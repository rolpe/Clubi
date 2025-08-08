//
//  ReviewSessionView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/6/25.
//

import SwiftUI
import SwiftData

struct ReviewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCourses: [Course]
    
    let course: Course
    let answers: [ReviewAnswer]
    let onCompletion: () -> Void
    
    @StateObject private var reviewSession: ReviewSession
    @State private var showingDetailedReview = false
    @State private var tiedCourse: Course?
    @State private var showingCancelAlert = false
    @State private var showingPlayoff = false
    
    init(course: Course, answers: [ReviewAnswer], onCompletion: @escaping () -> Void) {
        self.course = course
        self.answers = answers
        self.onCompletion = onCompletion
        self._reviewSession = StateObject(wrappedValue: ReviewSession(course: course, answers: answers))
    }
    
    private var calculatedScore: Double {
        reviewSession.getFinalScore()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Course Info
                VStack(spacing: 4) {
                    Text(course.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text(course.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Score Display
                VStack(spacing: 16) {
                    Text("Your Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("\(calculatedScore, specifier: "%.1f")")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        Text("out of 10")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Score interpretation
                    Text(scoreInterpretation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button("Save Review") {
                        saveReview()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                    
                    Button("Review Answers") {
                        showingDetailedReview = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                }
            }
            .sheet(isPresented: $showingDetailedReview) {
                DetailedReviewView(course: course, answers: answers, calculatedScore: calculatedScore, onReviewAgain: nil)
            }
            .fullScreenCover(item: $tiedCourse) { tied in
                TransactionalPlayoffView(
                    reviewSession: reviewSession,
                    tiedCourse: tied,
                    playoffCount: 1,
                    onCompletion: {
                        // Check for more ties after playoff
                        if let nextTie = findTiedCourse() {
                            tiedCourse = nextTie
                        } else {
                            // No more ties, commit the review
                            commitReview()
                        }
                    },
                    onCancel: {
                        onCompletion() // Go back to main course list
                    }
                )
            }
            .alert("Cancel Review?", isPresented: $showingCancelAlert) {
                Button("Keep Reviewing", role: .cancel) {}
                Button("Discard Review", role: .destructive) {
                    onCompletion() // Go back to main course list
                }
            } message: {
                Text("This will discard your review and all playoff results. This cannot be undone.")
            }
        }
    }
    
    private var scoreInterpretation: String {
        switch calculatedScore {
        case 9.0...10.0:
            return "Outstanding course! This is a must-play."
        case 8.0..<9.0:
            return "Excellent course. Highly recommended."
        case 7.0..<8.0:
            return "Very good course. Worth playing again."
        case 6.0..<7.0:
            return "Good course with some nice features."
        case 5.0..<6.0:
            return "Average course. It's okay."
        case 4.0..<5.0:
            return "Below average. Some issues noted."
        case 3.0..<4.0:
            return "Poor course with significant problems."
        default:
            return "Not recommended."
        }
    }
    
    private func saveReview() {
        // Check for ties first
        if let tied = findTiedCourse() {
            // Trigger playoff!
            tiedCourse = tied
            return
        }
        
        // No tie - commit normally
        commitReview()
    }
    
    private func commitReview() {
        do {
            try reviewSession.commitToDatabase(modelContext: modelContext)
            onCompletion()
        } catch {
            print("Failed to save review: \(error)")
        }
    }
    
    private func findTiedCourse() -> Course? {
        let currentScore = calculatedScore
        
        // Look for courses with the same score (within 0.05 tolerance)
        for otherCourse in allCourses {
            // Skip the current course
            if otherCourse.id == course.id { continue }
            
            // Skip courses already involved in playoffs
            let alreadyInPlayoffs = reviewSession.playoffResults.contains { result in
                result.opponent.id == otherCourse.id
            }
            if alreadyInPlayoffs { continue }
            
            // Check if this course has any reviews
            guard let otherScore = otherCourse.latestScore else { continue }
            
            // Check for tie (exact match or very close)
            if abs(otherScore - currentScore) < 0.05 {
                return otherCourse
            }
        }
        
        return nil
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Course.self, configurations: config)
    
    let course = Course(name: "Pebble Beach", location: "Pebble Beach, CA")
    let answers = [ReviewAnswer(questionId: 0, selectedAnswerIndex: 0)]
    
    return ReviewSessionView(course: course, answers: answers) {
        // Preview completion handler
    }
        .modelContainer(container)
}