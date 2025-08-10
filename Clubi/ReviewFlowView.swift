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
                progressHeader
                questionContent
                navigationButtons
            }
            .background(Color.morningMist)
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
    
    private var progressHeader: some View {
        VStack(spacing: ClubiSpacing.lg) {
            // Course Info
            VStack(spacing: ClubiSpacing.xs) {
                Text(course.name)
                    .font(ClubiTypography.headline())
                    .foregroundColor(Color.charcoal)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: ClubiSpacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(Color.grayFairway)
                    
                    Text(course.location)
                        .font(ClubiTypography.body(14))
                        .foregroundColor(Color.grayFairway)
                }
            }
            
            // Progress Section
            VStack(spacing: ClubiSpacing.sm) {
                HStack {
                    Text("Question \(currentQuestionIndex + 1) of \(ReviewQuestions.allQuestions.count)")
                        .font(ClubiTypography.caption())
                        .foregroundColor(Color.lightGray)
                    Spacer()
                }
                
                ClubiProgressBar(
                    progress: Double(currentQuestionIndex + 1),
                    total: Double(ReviewQuestions.allQuestions.count),
                    color: Color.fairwayGreen
                )
                .frame(height: 8)
            }
        }
        .padding(ClubiSpacing.xl)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.morningMist, Color.pristineWhite]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cardShadow()
    }
    
    private var questionContent: some View {
        VStack(spacing: ClubiSpacing.lg) {
            // Question Text
            Text(currentQuestion.text)
                .font(ClubiTypography.display(20, weight: .semibold))
                .foregroundColor(Color.charcoal)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, ClubiSpacing.xl)
                .padding(.top, ClubiSpacing.lg)
            
            // Answer Options
            VStack(spacing: ClubiSpacing.sm) {
                ForEach(Array(currentQuestion.answerOptions.enumerated()), id: \.offset) { index, option in
                    PremiumAnswerOptionView(
                        text: option.text,
                        isSelected: selectedAnswerIndex == index,
                        index: index,
                        action: {
                            selectAnswer(index)
                        }
                    )
                }
            }
            .padding(.horizontal, ClubiSpacing.xl)
            
            Spacer()
        }
    }
    
    private var navigationButtons: some View {
        VStack(spacing: ClubiSpacing.lg) {
            if currentQuestionIndex > 0 {
                Button("← Previous Question") {
                    previousQuestion()
                }
                .clubiTertiaryButton()
                .padding(.horizontal, ClubiSpacing.xl)
            }
        }
        .padding(.bottom, ClubiSpacing.xl)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if isLastQuestion {
                showResults()
            } else {
                nextQuestion()
            }
        }
    }
    
    private func nextQuestion() {
        withAnimation(ClubiAnimation.smooth) {
            currentQuestionIndex += 1
        }
    }
    
    private func previousQuestion() {
        withAnimation(ClubiAnimation.smooth) {
            currentQuestionIndex -= 1
        }
    }
    
    private func showResults() {
        showingResults = true
    }
}

// MARK: - Premium Answer Option View
struct PremiumAnswerOptionView: View {
    let text: String
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    
    var body: some View {
        Button(action: handleTap) {
            optionContent
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(ClubiAnimation.quick) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(ClubiAnimation.quick) {
                    isPressed = false
                }
            }
        }
    }
    
    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        action()
    }
    
    private var optionContent: some View {
        HStack(spacing: ClubiSpacing.lg) {
            optionText
            Spacer()
            selectionIndicator
        }
        .padding(ClubiSpacing.lg)
        .background(optionBackground)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .cardShadow()
    }
    
    
    private var optionText: some View {
        VStack(alignment: .leading, spacing: ClubiSpacing.xs) {
            Text(text)
                .font(ClubiTypography.body(16, weight: .medium))
                .foregroundColor(isSelected ? Color.augustaPine : Color.charcoal)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(Color.fairwayGreen)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(ClubiAnimation.bouncy, value: isPressed)
        }
    }
    
    private var optionBackground: some View {
        RoundedRectangle(cornerRadius: ClubiRadius.lg)
            .fill(isSelected ? Color.sunsetOrange.opacity(0.1) : Color.pristineWhite)
            .overlay(
                RoundedRectangle(cornerRadius: ClubiRadius.lg)
                    .stroke(
                        isSelected ? Color.fairwayGreen : Color.subtleLines,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Course.self, configurations: config)
    
    let course = Course(name: "Pebble Beach", location: "Pebble Beach, CA", userId: "preview")
    
    return ReviewFlowView(course: course) {
        // Preview completion handler
    }
        .modelContainer(container)
} 