//
//  DetailedReviewView.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import SwiftUI
import SwiftData

struct DetailedReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let course: Course
    let answers: [ReviewAnswer]
    let calculatedScore: Double
    let onReviewAgain: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(course.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(course.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Final Score
                        HStack {
                            Text("Final Score:")
                                .font(.headline)
                            Text("\(calculatedScore, specifier: "%.1f") / 10")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 16)
                    
                    // Questions and Answers
                    VStack(spacing: 16) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                            QuestionAnswerView(
                                question: ReviewQuestions.allQuestions[answer.questionId],
                                selectedAnswerIndex: answer.selectedAnswerIndex,
                                questionNumber: answer.questionId + 1
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Review Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if onReviewAgain != nil {
                        Button("Review Again") {
                            onReviewAgain?()
                        }
                        .foregroundColor(.green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Question Answer View
struct QuestionAnswerView: View {
    let question: Question
    let selectedAnswerIndex: Int
    let questionNumber: Int
    
    private var selectedAnswer: AnswerOption {
        question.answerOptions[selectedAnswerIndex]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question
            VStack(alignment: .leading, spacing: 4) {
                Text("Question \(questionNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(question.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Selected Answer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Answer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(selectedAnswer.text)
                        .font(.body)
                }
                
                Spacer()
                
                // Points earned
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(selectedAnswer.scoreValue, specifier: "%.1f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(pointsColor)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var pointsColor: Color {
        let maxPoints = question.answerOptions.map(\.scoreValue).max() ?? 0
        let percentage = selectedAnswer.scoreValue / maxPoints
        
        if percentage >= 0.8 {
            return .green
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    let course = Course(name: "Pebble Beach", location: "Pebble Beach, CA", userId: "preview")
    let answers = [
        ReviewAnswer(questionId: 0, selectedAnswerIndex: 1),
        ReviewAnswer(questionId: 1, selectedAnswerIndex: 2),
        ReviewAnswer(questionId: 2, selectedAnswerIndex: 3)
    ]
    
    return DetailedReviewView(course: course, answers: answers, calculatedScore: 8.5, onReviewAgain: nil)
} 