//
//  DataModels.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import Foundation
import SwiftData
import Firebase

// MARK: - Course Model
@Model
final class Course: Identifiable {
    var id: UUID
    var name: String
    var location: String
    var dateAdded: Date
    var userId: String // Firebase Auth UID of the user who saved this course
    
    // Relationship to reviews
    @Relationship(deleteRule: .cascade) var reviews: [Review] = []
    
    init(name: String, location: String, userId: String) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.dateAdded = Date()
        self.userId = userId
    }
    
    // Computed property to get the latest review score
    var latestScore: Double? {
        return reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first?.calculatedScore
    }
}

// MARK: - Review Model
@Model
final class Review {
    var id: UUID
    var courseId: UUID
    var answers: [ReviewAnswer]
    var calculatedScore: Double
    var dateReviewed: Date
    
    // Relationship to course
    var course: Course?
    
    init(courseId: UUID, answers: [ReviewAnswer]) {
        self.id = UUID()
        self.courseId = courseId
        self.answers = answers
        self.dateReviewed = Date()
        
        // Calculate score based on answers
        self.calculatedScore = Self.calculateScore(from: answers)
    }
    
    // Static method to calculate score from answers
    static func calculateScore(from answers: [ReviewAnswer]) -> Double {
        let totalScore = answers.reduce(0.0) { sum, answer in
            let question = ReviewQuestions.allQuestions[answer.questionId]
            let selectedOption = question.answerOptions[answer.selectedAnswerIndex]
            return sum + selectedOption.scoreValue
        }
        
        // Max possible score is 40 (4 questions × 10 points each)
        let maxScore = 40.0
        let normalizedScore = (totalScore / maxScore) * 10.0
        
        // Round to 1 decimal place
        return round(normalizedScore * 10) / 10
    }
}

// MARK: - Question Model
struct Question {
    let id: Int
    let text: String
    let answerOptions: [AnswerOption]
}

// MARK: - Answer Option Model  
struct AnswerOption {
    let text: String
    let scoreValue: Double
}

// MARK: - Review Answer Model
struct ReviewAnswer: Codable {
    let questionId: Int
    let selectedAnswerIndex: Int
}

// MARK: - Static Questions Data
struct ReviewQuestions {
    static let allQuestions: [Question] = [
        Question(
            id: 0,
            text: "Did you like this course overall?",
            answerOptions: [
                AnswerOption(text: "Yes", scoreValue: 10),
                AnswerOption(text: "No", scoreValue: 0)
            ]
        ),
        Question(
            id: 1,
            text: "How was the course layout and design?",
            answerOptions: [
                AnswerOption(text: "Excellent", scoreValue: 10),
                AnswerOption(text: "Thoughtful / Fun", scoreValue: 7),
                AnswerOption(text: "OK", scoreValue: 4),
                AnswerOption(text: "Confusing / Bland", scoreValue: 0)
            ]
        ),
        Question(
            id: 2,
            text: "How well maintained was the course?",
            answerOptions: [
                AnswerOption(text: "Professional Tour Quality", scoreValue: 10),
                AnswerOption(text: "Very Well Maintained", scoreValue: 7.5),
                AnswerOption(text: "Well Maintained", scoreValue: 5),
                AnswerOption(text: "OK", scoreValue: 2.5),
                AnswerOption(text: "Poor", scoreValue: 0)
            ]
        ),
        Question(
            id: 3,
            text: "Would you play it again?",
            answerOptions: [
                AnswerOption(text: "Definitely", scoreValue: 10),
                AnswerOption(text: "Maybe", scoreValue: 5),
                AnswerOption(text: "No", scoreValue: 0)
            ]
        )
    ]
}

// MARK: - Member Profile Model
struct MemberProfile: Codable, Identifiable {
    let id: String // Firebase Auth UID
    var username: String
    var displayName: String
    var bio: String
    var email: String
    var dateJoined: Date
    var isProfileComplete: Bool
    
    // Privacy settings
    var isProfilePublic: Bool
    var areReviewsPublic: Bool
    
    init(id: String, email: String, username: String = "", displayName: String = "", bio: String = "") {
        self.id = id
        self.email = email
        self.username = username.isEmpty ? String(email.prefix(while: { $0 != "@" })) : username
        self.displayName = displayName.isEmpty ? self.username : displayName
        self.bio = bio
        self.dateJoined = Date()
        self.isProfileComplete = !username.isEmpty && !displayName.isEmpty
        self.isProfilePublic = true
        self.areReviewsPublic = true
    }
    
    // Firestore conversion helpers
    func toDictionary() -> [String: Any] {
        return [
            "username": username,
            "displayName": displayName,
            "bio": bio,
            "email": email,
            "dateJoined": Timestamp(date: dateJoined),
            "isProfileComplete": isProfileComplete,
            "isProfilePublic": isProfilePublic,
            "areReviewsPublic": areReviewsPublic
        ]
    }
    
    static func fromDictionary(id: String, data: [String: Any]) -> MemberProfile? {
        guard let username = data["username"] as? String,
              let displayName = data["displayName"] as? String,
              let email = data["email"] as? String,
              let dateJoined = (data["dateJoined"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        var profile = MemberProfile(id: id, email: email, username: username, displayName: displayName)
        profile.bio = data["bio"] as? String ?? ""
        profile.dateJoined = dateJoined
        profile.isProfileComplete = data["isProfileComplete"] as? Bool ?? false
        profile.isProfilePublic = data["isProfilePublic"] as? Bool ?? true
        profile.areReviewsPublic = data["areReviewsPublic"] as? Bool ?? true
        
        return profile
    }
}

// MARK: - MemberProfile Extensions
extension MemberProfile: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MemberProfile, rhs: MemberProfile) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Following Relationship Model
struct FollowingRelationship {
    let id: String // Firestore document ID
    let followerId: String // User who is following
    let followingId: String // User being followed
    let dateFollowed: Date
    
    init(followerId: String, followingId: String) {
        self.id = "\(followerId)_\(followingId)"
        self.followerId = followerId
        self.followingId = followingId
        self.dateFollowed = Date()
    }
    
    // Firestore conversion helpers
    func toDictionary() -> [String: Any] {
        return [
            "followerId": followerId,
            "followingId": followingId,
            "dateFollowed": Timestamp(date: dateFollowed)
        ]
    }
    
    static func fromDictionary(id: String, data: [String: Any]) -> FollowingRelationship? {
        guard let followerId = data["followerId"] as? String,
              let followingId = data["followingId"] as? String,
              let dateFollowed = (data["dateFollowed"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        var relationship = FollowingRelationship(followerId: followerId, followingId: followingId)
        relationship = FollowingRelationship(
            id: id,
            followerId: followerId, 
            followingId: followingId,
            dateFollowed: dateFollowed
        )
        return relationship
    }
    
    private init(id: String, followerId: String, followingId: String, dateFollowed: Date) {
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.dateFollowed = dateFollowed
    }
}

// MARK: - Feed Activity Models

enum FeedActivityType: String, Codable, CaseIterable {
    case courseReviewed = "course_reviewed"
    
    var displayText: String {
        switch self {
        case .courseReviewed:
            return "reviewed"
        }
    }
    
    var iconName: String {
        switch self {
        case .courseReviewed:
            return "star.fill"
        }
    }
}

struct FeedActivity: Codable, Identifiable {
    let id: String
    let userId: String
    let userDisplayName: String
    let userUsername: String
    let activityType: FeedActivityType
    let courseId: String
    let courseName: String
    let courseLocation: String
    let score: Double? // Only present for courseReviewed activities
    let timestamp: Date
    
    init(userId: String, userDisplayName: String, userUsername: String, activityType: FeedActivityType, courseId: String, courseName: String, courseLocation: String, score: Double? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.userUsername = userUsername
        self.activityType = activityType
        self.courseId = courseId
        self.courseName = courseName
        self.courseLocation = courseLocation
        self.score = score
        self.timestamp = Date()
    }
    
    // Firestore conversion helpers
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "userDisplayName": userDisplayName,
            "userUsername": userUsername,
            "activityType": activityType.rawValue,
            "courseId": courseId,
            "courseName": courseName,
            "courseLocation": courseLocation,
            "timestamp": Timestamp(date: timestamp)
        ]
        
        if let score = score {
            dict["score"] = score
        }
        
        return dict
    }
    
    static func fromDictionary(id: String, data: [String: Any]) -> FeedActivity? {
        guard let userId = data["userId"] as? String,
              let userDisplayName = data["userDisplayName"] as? String,
              let userUsername = data["userUsername"] as? String,
              let activityTypeRaw = data["activityType"] as? String,
              let activityType = FeedActivityType(rawValue: activityTypeRaw),
              let courseId = data["courseId"] as? String,
              let courseName = data["courseName"] as? String,
              let courseLocation = data["courseLocation"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        let score = data["score"] as? Double
        
        var activity = FeedActivity(
            userId: userId,
            userDisplayName: userDisplayName,
            userUsername: userUsername,
            activityType: activityType,
            courseId: courseId,
            courseName: courseName,
            courseLocation: courseLocation,
            score: score
        )
        
        // Override the generated values with the stored ones
        activity = FeedActivity(
            id: id,
            userId: userId,
            userDisplayName: userDisplayName,
            userUsername: userUsername,
            activityType: activityType,
            courseId: courseId,
            courseName: courseName,
            courseLocation: courseLocation,
            score: score,
            timestamp: timestamp
        )
        
        return activity
    }
    
    private init(id: String, userId: String, userDisplayName: String, userUsername: String, activityType: FeedActivityType, courseId: String, courseName: String, courseLocation: String, score: Double?, timestamp: Date) {
        self.id = id
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.userUsername = userUsername
        self.activityType = activityType
        self.courseId = courseId
        self.courseName = courseName
        self.courseLocation = courseLocation
        self.score = score
        self.timestamp = timestamp
    }
}

// MARK: - FeedActivity Extensions
extension FeedActivity: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FeedActivity, rhs: FeedActivity) -> Bool {
        return lhs.id == rhs.id
    }
}
