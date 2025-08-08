//
//  ReviewSession.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/6/25.
//

import Foundation
import SwiftData

class ReviewSession: ObservableObject {
    let course: Course
    let answers: [ReviewAnswer]
    let calculatedScore: Double
    
    @Published var playoffResults: [PlayoffResult] = []
    @Published var isCompleted = false
    
    init(course: Course, answers: [ReviewAnswer]) {
        self.course = course
        self.answers = answers
        self.calculatedScore = Review.calculateScore(from: answers)
    }
    
    func getFinalScore() -> Double {
        var finalScore = calculatedScore
        
        for result in playoffResults {
            if result.winner == course.id {
                finalScore += result.scoreAdjustment
            }
        }
        
        return max(0.0, min(10.0, finalScore))
    }
    
    func addPlayoffResult(_ result: PlayoffResult) {
        playoffResults.append(result)
    }
    
    func commitToDatabase(modelContext: ModelContext) throws {
        let review = Review(courseId: course.id, answers: answers)
        review.calculatedScore = getFinalScore()
        review.course = course
        
        modelContext.insert(review)
        
        for result in playoffResults {
            if let opponentCourse = result.getOpponentCourse(from: modelContext) {
                adjustOpponentScore(opponentCourse, by: result.getOpponentAdjustment())
            }
        }
        
        try modelContext.save()
        isCompleted = true
    }
    
    private func adjustOpponentScore(_ course: Course, by adjustment: Double) {
        if let latestReview = course.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first {
            latestReview.calculatedScore += adjustment
            latestReview.calculatedScore = max(0.0, min(10.0, latestReview.calculatedScore))
        }
    }
}

struct PlayoffResult {
    let opponent: Course
    let winner: UUID
    let scoreAdjustment: Double = 0.1
    
    func getOpponentAdjustment() -> Double {
        return winner == opponent.id ? scoreAdjustment : -scoreAdjustment
    }
    
    func getOpponentCourse(from modelContext: ModelContext) -> Course? {
        return opponent
    }
}