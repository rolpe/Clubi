//
//  ReviewFlowView.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import SwiftUI
import SwiftData

struct ReviewFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let course: Course
    let onCompletion: () -> Void
    @State private var currentQuestionIndex = 0
    @State private var answers: [ReviewAnswer] = []
    @State private var showingResults = false
    @State private var showingCancelAlert = false
    
    private var currentQuestion: Question {
        ReviewQuestions.allQuestions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == ReviewQuestions.allQuestions.count - 1
    }
    
    private var canProceed: Bool {
        answers.count > currentQuestionIndex
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                VStack(spacing: 16) {
                    // Course Info
                    VStack(spacing: 4) {
                        Text(course.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text(course.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Question \(currentQuestionIndex + 1) of \(ReviewQuestions.allQuestions.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        ProgressView(value: Double(currentQuestionIndex + 1), total: Double(ReviewQuestions.allQuestions.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Question Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Question Text
                        Text(currentQuestion.text)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Answer Options
                        VStack(spacing: 12) {
                            ForEach(Array(currentQuestion.answerOptions.enumerated()), id: \.offset) { index, option in
                                AnswerOptionView(
                                    text: option.text,
                                    isSelected: selectedAnswerIndex == index,
                                    action: {
                                        selectAnswer(index)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 32)
                }
                
                // Navigation Buttons
                VStack(spacing: 16) {
                    if currentQuestionIndex > 0 {
                        Button("Previous Question") {
                            previousQuestion()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                }
            }
            .alert("Cancel Review?", isPresented: $showingCancelAlert) {
                Button("Keep Reviewing", role: .cancel) {}
                Button("Discard Review", role: .destructive) {
                    onCompletion() // Go back to main course list
                }
            } message: {
                Text("This will discard your review. This cannot be undone.")
            }
            .fullScreenCover(isPresented: $showingResults) {
                ReviewSessionView(course: course, answers: answers, onCompletion: onCompletion)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var selectedAnswerIndex: Int? {
        if answers.count > currentQuestionIndex {
            return answers[currentQuestionIndex].selectedAnswerIndex
        }
        return nil
    }
    
    // MARK: - Actions
    private func selectAnswer(_ index: Int) {
        let answer = ReviewAnswer(questionId: currentQuestionIndex, selectedAnswerIndex: index)
        
        if answers.count > currentQuestionIndex {
            // Update existing answer
            answers[currentQuestionIndex] = answer
        } else {
            // Add new answer
            answers.append(answer)
        }
        
        // Auto-advance after a brief delay to show selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if isLastQuestion {
                showResults()
            } else {
                nextQuestion()
            }
        }
    }
    
    private func nextQuestion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuestionIndex += 1
        }
    }
    
    private func previousQuestion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuestionIndex -= 1
        }
    }
    
    private func showResults() {
        showingResults = true
    }
}

// MARK: - Answer Option View
struct AnswerOptionView: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Course.self, configurations: config)
    
    let course = Course(name: "Pebble Beach", location: "Pebble Beach, CA")
    
    return ReviewFlowView(course: course) {
        // Preview completion handler
    }
        .modelContainer(container)
} 