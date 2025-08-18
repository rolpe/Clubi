//
//  FeedManager.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FeedManager: ObservableObject {
    @Published var activities: [FeedActivity] = []
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    // Caching
    private var cachedFollowing: [String] = []
    private var followingCacheExpiry: Date = Date()
    private let followingCacheTimeout: TimeInterval = 300 // 5 minutes
    
    // Listener management
    private var isListenerActive = false
    private var listenerRetryCount = 0
    private let maxRetryAttempts = 3
    
    // Feed refresh tracking
    @Published var needsRefresh = false
    
    static let shared = FeedManager()
    
    private init() {}
    
    deinit {
        stopListening()
    }
    
    // MARK: - Public Methods
    
    /// Loads feed activities for the current user
    func loadFeedActivities() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                activities = []
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            hasError = false
        }
        
        do {
            // Get list of users that current user follows
            let followingUsers = try await getFollowingUserIds(userId: currentUserId)
            
            // If not following anyone, show empty feed
            guard !followingUsers.isEmpty else {
                await MainActor.run {
                    activities = []
                    isLoading = false
                }
                return
            }
            
            // Load activities from followed users
            let feedActivities = try await loadActivitiesFromUsers(followingUsers)
            
            await MainActor.run {
                activities = feedActivities
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to load feed: \(error.localizedDescription)"
                isLoading = false
                activities = []
            }
        }
    }
    
    /// Refreshes the feed (pull-to-refresh)
    func refreshFeed() async {
        // Clear all cached data and state
        lastDocument = nil
        await MainActor.run {
            hasMoreData = true
            needsRefresh = false
            // Clear the cache to force fresh data
            cachedFollowing = []
            followingCacheExpiry = Date()
            // Clear existing activities to force fresh load
            activities = []
        }
        // Load fresh activities
        await loadFeedActivities()
    }
    
    /// Filter existing activities and refresh if needed
    private func filterAndRefreshFeed() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                activities = []
                needsRefresh = false
            }
            return
        }
        
        do {
            // Get fresh following list (bypassing cache)
            await MainActor.run {
                cachedFollowing = []
                followingCacheExpiry = Date()
            }
            
            let followingUsers = try await getFollowingUserIds(userId: currentUserId)
            
            await MainActor.run {
                // Filter existing activities to only show those from users we still follow
                activities = activities.filter { activity in
                    followingUsers.contains(activity.userId)
                }
                
                lastDocument = nil
                hasMoreData = true
                needsRefresh = false
            }
            
            // Load fresh activities to fill any gaps
            await loadFeedActivities()
            
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
                needsRefresh = false
            }
        }
    }
    
    /// Load more activities (pagination)
    func loadMoreActivities() async {
        guard !isLoadingMore && hasMoreData && !activities.isEmpty else { return }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        do {
            // Get list of users that current user follows
            let followingUsers = try await getFollowingUserIds(userId: currentUserId)
            
            guard !followingUsers.isEmpty else {
                await MainActor.run {
                    isLoadingMore = false
                    hasMoreData = false
                }
                return
            }
            
            // Load next batch of activities
            let newActivities = try await loadMoreActivitiesFromUsers(followingUsers)
            
            if !newActivities.isEmpty {
                await MainActor.run {
                    // Merge with existing activities and remove duplicates
                    var allActivities = activities
                    for activity in newActivities {
                        if !allActivities.contains(where: { $0.id == activity.id }) {
                            allActivities.append(activity)
                        }
                    }
                    
                    activities = allActivities.sorted { $0.timestamp > $1.timestamp }
                    hasMoreData = newActivities.count >= 20 // If we got less than page size, we're at the end
                    isLoadingMore = false
                }
            } else {
                await MainActor.run {
                    hasMoreData = false
                    isLoadingMore = false
                }
            }
            
        } catch {
            await MainActor.run {
                isLoadingMore = false
            }
            print("Failed to load more activities: \(error)")
        }
    }
    
    /// Sets up real-time listener for feed updates
    func startListeningForFeedUpdates() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let followingUsers = try await getFollowingUserIds(userId: currentUserId)
                guard !followingUsers.isEmpty else {
                    await MainActor.run {
                        activities = []
                    }
                    return
                }
                
                await setupRealtimeListener(for: followingUsers)
            } catch {
                print("Failed to setup feed listener: \(error)")
            }
        }
    }
    
    /// Stops the real-time listener
    func stopListening() {
        listener?.remove()
        listener = nil
        isListenerActive = false
        listenerRetryCount = 0
    }
    
    /// Retry loading after an error
    func retryLoading() async {
        await MainActor.run {
            hasError = false
            errorMessage = ""
        }
        await loadFeedActivities()
    }
    
    /// Invalidate following cache when user's following list changes
    func invalidateFollowingCache() {
        Task { @MainActor in
            cachedFollowing = []
            followingCacheExpiry = Date()
            needsRefresh = true
        }
    }
    
    /// Clear all cached data
    func clearCache() {
        Task { @MainActor in
            cachedFollowing = []
            followingCacheExpiry = Date()
            lastDocument = nil
            hasMoreData = true
        }
    }
    
    // MARK: - Private Methods
    
    private func getFollowingUserIds(userId: String) async throws -> [String] {
        // Check cache first
        let now = Date()
        if !cachedFollowing.isEmpty && now < followingCacheExpiry {
            return cachedFollowing
        }
        
        // Fetch from Firebase if cache is expired or empty
        let profileManager = await MemberProfileManager()
        let followingList = try await profileManager.getFollowing(userId: userId)
        let followingIds = followingList.map { $0.id }
        
        // Update cache
        await MainActor.run {
            cachedFollowing = followingIds
            followingCacheExpiry = now.addingTimeInterval(followingCacheTimeout)
        }
        
        return followingIds
    }
    
    private func loadActivitiesFromUsers(_ userIds: [String]) async throws -> [FeedActivity] {
        // Firebase 'in' queries are limited to 10 items, so we need to batch if following more users
        let batchSize = 10
        var allActivities: [FeedActivity] = []
        
        for batchStart in stride(from: 0, to: userIds.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, userIds.count)
            let batch = Array(userIds[batchStart..<batchEnd])
            
            let batchActivities = try await loadActivitiesBatch(userIds: batch)
            allActivities.append(contentsOf: batchActivities)
        }
        
        // Sort by timestamp (newest first) and limit for initial load
        return allActivities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20) // Initial load: 20 activities
            .map { $0 }
    }
    
    private func loadActivitiesBatch(userIds: [String]) async throws -> [FeedActivity] {
        let query = db.collection("feed_activities")
            .whereField("userId", in: userIds)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
        
        let snapshot = try await query.getDocuments()
        
        var activities: [FeedActivity] = []
        for document in snapshot.documents {
            if let activity = FeedActivity.fromDictionary(id: document.documentID, data: document.data()) {
                activities.append(activity)
            }
        }
        
        return activities
    }
    
    private func loadMoreActivitiesFromUsers(_ userIds: [String]) async throws -> [FeedActivity] {
        // Firebase 'in' queries are limited to 10 items, so we need to batch if following more users
        let batchSize = 10
        var allActivities: [FeedActivity] = []
        
        for batchStart in stride(from: 0, to: userIds.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, userIds.count)
            let batch = Array(userIds[batchStart..<batchEnd])
            
            let batchActivities = try await loadMoreActivitiesBatch(userIds: batch)
            allActivities.append(contentsOf: batchActivities)
        }
        
        // Sort by timestamp (newest first) and limit for pagination
        return allActivities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20) // Page size: 20 activities
            .map { $0 }
    }
    
    private func loadMoreActivitiesBatch(userIds: [String]) async throws -> [FeedActivity] {
        var query = db.collection("feed_activities")
            .whereField("userId", in: userIds)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
        
        // Add pagination - start after the last document
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        // Update lastDocument for next pagination
        if let lastDoc = snapshot.documents.last {
            lastDocument = lastDoc
        }
        
        var activities: [FeedActivity] = []
        for document in snapshot.documents {
            if let activity = FeedActivity.fromDictionary(id: document.documentID, data: document.data()) {
                activities.append(activity)
            }
        }
        
        return activities
    }
    
    private func setupRealtimeListener(for userIds: [String]) async {
        // For real-time updates, we'll listen to the first batch of users
        // (In a production app, you might want more sophisticated real-time handling)
        let listenUserIds = Array(userIds.prefix(10))
        
        guard !listenUserIds.isEmpty else { return }
        
        await MainActor.run {
            // Stop existing listener if any
            listener?.remove()
            isListenerActive = true
            
            listener = db.collection("feed_activities")
                .whereField("userId", in: listenUserIds)
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Feed listener error: \(error)")
                        
                        // Attempt to reconnect if we haven't exceeded retry limit
                        if self.listenerRetryCount < self.maxRetryAttempts {
                            self.listenerRetryCount += 1
                            print("Attempting to reconnect listener (attempt \(self.listenerRetryCount))")
                            
                            // Retry after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                Task {
                                    await self.setupRealtimeListener(for: userIds)
                                }
                            }
                        } else {
                            print("Max retry attempts reached for feed listener")
                            self.isListenerActive = false
                        }
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    // Reset retry count on successful connection
                    self.listenerRetryCount = 0
                    
                    var newActivities: [FeedActivity] = []
                    for document in snapshot.documents {
                        if let activity = FeedActivity.fromDictionary(id: document.documentID, data: document.data()) {
                            newActivities.append(activity)
                        }
                    }
                    
                    // Update activities with new data
                    Task {
                        await self.updateActivitiesWithRealtimeData(newActivities)
                    }
                }
        }
    }
    
    private func updateActivitiesWithRealtimeData(_ newActivities: [FeedActivity]) async {
        await MainActor.run {
            // Merge new activities with existing ones, removing duplicates
            var allActivities = activities
            
            for newActivity in newActivities {
                if !allActivities.contains(where: { $0.id == newActivity.id }) {
                    allActivities.append(newActivity)
                }
            }
            
            // Sort by timestamp and limit
            activities = allActivities
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(50)
                .map { $0 }
        }
    }
}