//
//  MemberProfileManager.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/9/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@MainActor
class MemberProfileManager: ObservableObject {
    @Published var currentMemberProfile: MemberProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var followingStatus: [String: Bool] = [:] // userId -> isFollowing
    
    private let db = Firestore.firestore()
    private let membersCollection = "members"
    private let followingCollection = "following"
    private var profileListener: ListenerRegistration?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for authentication state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadCurrentMemberProfile(userId: user.uid)
                } else {
                    self?.currentMemberProfile = nil
                    self?.cleanupListener()
                }
            }
        }
    }
    
    deinit {
        // Clean up Firebase listeners
        profileListener?.remove()
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Profile Management
    
    func createMemberProfile(email: String, username: String, displayName: String, bio: String) async throws -> MemberProfile {
        guard let user = Auth.auth().currentUser else {
            throw ProfileError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if username is already taken
            let isAvailable = try await checkUsernameAvailability(username: username)
            guard isAvailable else {
                throw ProfileError.usernameAlreadyTaken
            }
            
            // Create profile
            let profile = MemberProfile(
                id: user.uid,
                email: email,
                username: username.lowercased(),
                displayName: displayName,
                bio: bio
            )
            
            // Save to Firestore
            try await db.collection(membersCollection).document(user.uid).setData(profile.toDictionary())
            
            // Update local state
            currentMemberProfile = profile
            
            isLoading = false
            return profile
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateMemberProfile(_ profile: MemberProfile) async throws {
        guard let user = Auth.auth().currentUser else {
            throw ProfileError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // If username changed, check availability
            if let currentProfile = currentMemberProfile,
               currentProfile.username != profile.username {
                let isAvailable = try await checkUsernameAvailability(username: profile.username)
                guard isAvailable else {
                    throw ProfileError.usernameAlreadyTaken
                }
            }
            
            // Update in Firestore
            try await db.collection(membersCollection).document(user.uid).updateData(profile.toDictionary())
            
            // Update local state
            currentMemberProfile = profile
            
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func checkUsernameAvailability(username: String) async throws -> Bool {
        let cleanUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let querySnapshot = try await db.collection(membersCollection)
            .whereField("username", isEqualTo: cleanUsername)
            .getDocuments()
        
        return querySnapshot.documents.isEmpty
    }
    
    // MARK: - Member Discovery
    
    func searchMembers(query: String, limit: Int = 20) async throws -> [MemberProfile] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let currentUserId = Auth.auth().currentUser?.uid
        
        // Get all public profiles and filter client-side to avoid complex indexes
        let querySnapshot = try await db.collection(membersCollection)
            .whereField("isProfilePublic", isEqualTo: true)
            .limit(to: 100) // Get more to filter client-side
            .getDocuments()
        
        var memberProfiles: [MemberProfile] = []
        
        for document in querySnapshot.documents {
            if let profile = MemberProfile.fromDictionary(id: document.documentID, data: document.data()) {
                // Exclude current user from search results
                guard profile.id != currentUserId else { continue }
                
                // Client-side filtering
                let usernameMatch = profile.username.lowercased().contains(cleanQuery)
                let displayNameMatch = profile.displayName.lowercased().contains(cleanQuery)
                
                if usernameMatch || displayNameMatch {
                    memberProfiles.append(profile)
                }
            }
        }
        
        // Sort by relevance (exact username matches first, then starts with, then contains)
        let sortedProfiles = memberProfiles.sorted { profile1, profile2 in
            let username1 = profile1.username.lowercased()
            let username2 = profile2.username.lowercased()
            let displayName1 = profile1.displayName.lowercased()
            let displayName2 = profile2.displayName.lowercased()
            
            // Exact username match gets highest priority
            if username1 == cleanQuery && username2 != cleanQuery {
                return true
            } else if username1 != cleanQuery && username2 == cleanQuery {
                return false
            }
            
            // Username starts with query gets next priority
            let username1StartsWithQuery = username1.hasPrefix(cleanQuery)
            let username2StartsWithQuery = username2.hasPrefix(cleanQuery)
            
            if username1StartsWithQuery && !username2StartsWithQuery {
                return true
            } else if !username1StartsWithQuery && username2StartsWithQuery {
                return false
            }
            
            // Display name starts with query gets next priority
            let displayName1StartsWithQuery = displayName1.hasPrefix(cleanQuery)
            let displayName2StartsWithQuery = displayName2.hasPrefix(cleanQuery)
            
            if displayName1StartsWithQuery && !displayName2StartsWithQuery {
                return true
            } else if !displayName1StartsWithQuery && displayName2StartsWithQuery {
                return false
            }
            
            // Finally, sort alphabetically by username
            return username1 < username2
        }
        
        // Return limited results
        return Array(sortedProfiles.prefix(limit))
    }
    
    func getMemberProfile(userId: String) async throws -> MemberProfile? {
        let document = try await db.collection(membersCollection).document(userId).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        return MemberProfile.fromDictionary(id: userId, data: data)
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentMemberProfile(userId: String) async {
        cleanupListener()
        
        // Set up real-time listener for current member profile
        profileListener = db.collection(membersCollection).document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ Error listening to member profile: \(error)")
                        return
                    }
                    
                    guard let document = documentSnapshot,
                          document.exists,
                          let data = document.data() else {
                        self?.currentMemberProfile = nil
                        return
                    }
                    
                    self?.currentMemberProfile = MemberProfile.fromDictionary(id: userId, data: data)
                }
            }
    }
    
    private func cleanupListener() {
        profileListener?.remove()
        profileListener = nil
    }
    
    // MARK: - Following Functionality
    
    func followMember(userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Follow failed: User not authenticated")
            throw ProfileError.notAuthenticated
        }
        
        guard currentUser.uid != userId else {
            print("❌ Follow failed: Cannot follow yourself. Current user: \(currentUser.uid), Target user: \(userId)")
            throw ProfileError.invalidInput // Can't follow yourself
        }
        
        print("✅ Attempting to follow user: \(userId) from: \(currentUser.uid)")
        
        let relationship = FollowingRelationship(followerId: currentUser.uid, followingId: userId)
        
        do {
            try await db.collection(followingCollection).document(relationship.id)
                .setData(relationship.toDictionary())
            
            print("✅ Successfully followed user: \(userId)")
            
            // Update local state
            followingStatus[userId] = true
        } catch {
            print("❌ Firebase error following user \(userId): \(error)")
            throw error
        }
    }
    
    func unfollowMember(userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw ProfileError.notAuthenticated
        }
        
        let relationshipId = "\(currentUser.uid)_\(userId)"
        
        try await db.collection(followingCollection).document(relationshipId).delete()
        
        // Update local state
        followingStatus[userId] = false
    }
    
    func checkIfFollowing(userId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            return false
        }
        
        guard currentUser.uid != userId else {
            return false // Can't follow yourself
        }
        
        // Check cache first
        if let cached = followingStatus[userId] {
            return cached
        }
        
        let relationshipId = "\(currentUser.uid)_\(userId)"
        let document = try await db.collection(followingCollection).document(relationshipId).getDocument()
        
        let isFollowing = document.exists
        followingStatus[userId] = isFollowing
        return isFollowing
    }
    
    func getFollowerCount(userId: String) async throws -> Int {
        let querySnapshot = try await db.collection(followingCollection)
            .whereField("followingId", isEqualTo: userId)
            .getDocuments()
        
        return querySnapshot.documents.count
    }
    
    func getFollowingCount(userId: String) async throws -> Int {
        let querySnapshot = try await db.collection(followingCollection)
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()
        
        return querySnapshot.documents.count
    }
    
    func getFollowers(userId: String) async throws -> [MemberProfile] {
        let querySnapshot = try await db.collection(followingCollection)
            .whereField("followingId", isEqualTo: userId)
            .getDocuments()
        
        var followers: [MemberProfile] = []
        
        for document in querySnapshot.documents {
            if let relationship = FollowingRelationship.fromDictionary(id: document.documentID, data: document.data()),
               let follower = try await getMemberProfile(userId: relationship.followerId) {
                followers.append(follower)
            }
        }
        
        return followers.sorted { $0.username.lowercased() < $1.username.lowercased() }
    }
    
    func getFollowing(userId: String) async throws -> [MemberProfile] {
        let querySnapshot = try await db.collection(followingCollection)
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()
        
        var following: [MemberProfile] = []
        
        for document in querySnapshot.documents {
            if let relationship = FollowingRelationship.fromDictionary(id: document.documentID, data: document.data()),
               let followedMember = try await getMemberProfile(userId: relationship.followingId) {
                following.append(followedMember)
            }
        }
        
        return following.sorted { $0.username.lowercased() < $1.username.lowercased() }
    }
}

// MARK: - Profile Errors

enum ProfileError: LocalizedError {
    case notAuthenticated
    case usernameAlreadyTaken
    case profileNotFound
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to manage your profile"
        case .usernameAlreadyTaken:
            return "This username is already taken"
        case .profileNotFound:
            return "Member profile not found"
        case .invalidInput:
            return "Please check your input and try again"
        }
    }
}
