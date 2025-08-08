//
//  DataModels.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import Foundation
import SwiftData

// MARK: - Course Model
@Model
final class Course: Identifiable {
    var id: UUID
    var name: String
    var location: String
    var dateAdded: Date
    
    // Relationship to reviews
    @Relationship(deleteRule: .cascade) var reviews: [Review] = []
    
    init(name: String, location: String) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.dateAdded = Date()
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
