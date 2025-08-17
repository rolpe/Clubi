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
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    static let shared = FeedManager()
    
    private init() {}
    
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
        lastDocument = nil
        await loadFeedActivities()
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
    }
    
    // MARK: - Private Methods
    
    private func getFollowingUserIds(userId: String) async throws -> [String] {
        let profileManager = await MemberProfileManager()
        let followingList = try await profileManager.getFollowing(userId: userId)
        return followingList.map { $0.id }
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
        
        // Sort by timestamp (newest first) and limit to reasonable number
        return allActivities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(50) // Limit to 50 most recent activities
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
    
    private func setupRealtimeListener(for userIds: [String]) async {
        // For real-time updates, we'll listen to the first batch of users
        // (In a production app, you might want more sophisticated real-time handling)
        let listenUserIds = Array(userIds.prefix(10))
        
        guard !listenUserIds.isEmpty else { return }
        
        await MainActor.run {
            listener = db.collection("feed_activities")
                .whereField("userId", in: listenUserIds)
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Feed listener error: \(error)")
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
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