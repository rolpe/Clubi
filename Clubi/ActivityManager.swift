//
//  ActivityManager.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import Foundation
import FirebaseFirestore

class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Activity Generation
    
    /// Creates a course review activity when a user reviews a course
    func createCourseReviewActivity(
        userId: String,
        userDisplayName: String,
        userUsername: String,
        courseId: String,
        courseName: String,
        courseLocation: String,
        score: Double
    ) async throws {
        // Check if user's reviews are public
        guard try await isUserReviewsPublic(userId: userId) else {
            print("🔒 Skipping activity creation - user reviews are private")
            return
        }
        
        let activity = FeedActivity(
            userId: userId,
            userDisplayName: userDisplayName,
            userUsername: userUsername,
            activityType: .courseReviewed,
            courseId: courseId,
            courseName: courseName,
            courseLocation: courseLocation,
            score: score
        )
        
        try await saveActivity(activity)
        print("📝 Created review activity: \(userDisplayName) reviewed \(courseName)")
    }
    
    
    // MARK: - Privacy Checks
    
    private func isUserReviewsPublic(userId: String) async throws -> Bool {
        let memberDoc = try await db.collection("members").document(userId).getDocument()
        
        if let data = memberDoc.data(),
           let areReviewsPublic = data["areReviewsPublic"] as? Bool {
            return areReviewsPublic
        }
        
        return true // Default to public if setting not found
    }
    
    
    // MARK: - Activity Storage
    
    private func saveActivity(_ activity: FeedActivity) async throws {
        let activityData = activity.toDictionary()
        try await db.collection("feed_activities").document(activity.id).setData(activityData)
    }
    
    // MARK: - Convenience Methods
    
    /// Creates review activity from ReviewSession data
    func createActivityFromReviewSession(
        _ reviewSession: ReviewSession,
        memberProfile: MemberProfile
    ) async throws {
        try await createCourseReviewActivity(
            userId: memberProfile.id,
            userDisplayName: memberProfile.displayName,
            userUsername: memberProfile.username,
            courseId: reviewSession.course.id.uuidString,
            courseName: reviewSession.course.name,
            courseLocation: reviewSession.course.location,
            score: reviewSession.getFinalScore()
        )
    }
    
}