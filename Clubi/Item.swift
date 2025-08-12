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
