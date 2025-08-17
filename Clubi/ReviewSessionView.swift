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
    @StateObject private var profileManager = MemberProfileManager()
    @State private var showingDetailedReview = false
    @State private var tiedCourse: Course?
    @State private var showingCancelAlert = false
    @State private var showingPlayoff = false
    @State private var scoreAnimationProgress: Double = 0.0
    @State private var showConfetti = false
    @State private var titleBounce = false
    
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
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.morningMist, Color.pristineWhite]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: ClubiSpacing.xl) {
                        Spacer().frame(height: ClubiSpacing.sm)
                        
                        // Course Info Card
                        VStack(spacing: ClubiSpacing.lg) {
                            // Completion Badge
                            HStack {
                                Spacer()
                                ClubiTag(
                                    "✓ Review Complete",
                                    color: .pristineWhite,
                                    backgroundColor: .fairwayGreen
                                )
                                Spacer()
                            }
                            
                            VStack(spacing: ClubiSpacing.sm) {
                                Text(course.name)
                                    .font(ClubiTypography.display(24, weight: .bold))
                                    .foregroundColor(.charcoal)
                                    .multilineTextAlignment(.center)
                                    .scaleEffect(titleBounce ? 1.05 : 1.0)
                                    .animation(ClubiAnimation.bouncy, value: titleBounce)
                                
                                HStack(spacing: ClubiSpacing.xs) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.grayFairway)
                                    
                                    Text(course.location)
                                        .font(ClubiTypography.body(weight: .medium))
                                        .foregroundColor(.grayFairway)
                                }
                            }
                        }
                        .padding(ClubiSpacing.xl)
                        .background(Color.pristineWhite)
                        .cornerRadius(ClubiRadius.lg)
                        .cardShadow()
                        
                        // Premium Score Display
                        VStack(spacing: ClubiSpacing.lg) {
                            VStack(spacing: ClubiSpacing.md) {
                                Text("Your Score")
                                    .font(ClubiTypography.headline(18, weight: .semibold))
                                    .foregroundColor(.grayFairway)
                                
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(Color.subtleLines, lineWidth: 8)
                                        .frame(width: 160, height: 160)
                                    
                                    // Progress circle
                                    Circle()
                                        .trim(from: 0, to: scoreAnimationProgress / 10.0)
                                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                        .frame(width: 160, height: 160)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeOut(duration: 1.5), value: scoreAnimationProgress)
                                    
                                    // Score text
                                    VStack(spacing: ClubiSpacing.xs) {
                                        Text(scoreEmoji)
                                            .font(.system(size: 32))
                                            .scaleEffect(showConfetti ? 1.2 : 1.0)
                                            .animation(ClubiAnimation.bouncy, value: showConfetti)
                                        
                                        Text(String(format: "%.1f", scoreAnimationProgress))
                                            .font(ClubiTypography.scoreDisplay(48))
                                            .foregroundColor(scoreColor)
                                            .contentTransition(.numericText())
                                        
                                        Text("out of 10")
                                            .font(ClubiTypography.body(weight: .medium))
                                            .foregroundColor(.grayFairway)
                                    }
                                }
                            }
                            
                            // Score interpretation with premium styling
                            VStack(spacing: ClubiSpacing.md) {
                                Text(scoreInterpretation)
                                    .font(ClubiTypography.body(16, weight: .medium))
                                    .foregroundColor(.charcoal)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, ClubiSpacing.lg)
                                    .padding(.vertical, ClubiSpacing.lg)
                                    .background(
                                        RoundedRectangle(cornerRadius: ClubiRadius.md)
                                            .fill(scoreColor.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ClubiRadius.md)
                                                    .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        Spacer().frame(height: ClubiSpacing.md)
                        
                        // Premium Action Buttons
                        VStack(spacing: ClubiSpacing.lg) {
                            Button("Save Review") {
                                saveReview()
                            }
                            .clubiPrimaryButton()
                            
                            Button("Review Answers") {
                                showingDetailedReview = true
                            }
                            .clubiTertiaryButton()
                        }
                        .padding(.horizontal, ClubiSpacing.xl)
                        
                        Spacer().frame(height: ClubiSpacing.lg)
                    }
                }
            }
            .background(Color.morningMist)
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
        .onAppear {
            startScoreAnimation()
        }
    }
    
    // MARK: - Computed Properties
    
    private var scoreColor: Color {
        switch calculatedScore {
        case 9.0...10.0:
            return .freshGrass       // Bright green for 9.0-10.0
        case 8.0..<9.0:
            return .fairwayGreen     // Medium-bright green for 8.0-8.9
        case 7.0..<8.0:
            return .mediumGreen      // Medium green for 7.0-7.9
        case 5.0..<7.0:
            return .darkGreen        // Dark green for 5.0-6.9
        default:
            return .goldenTournament // Brown for below 5.0
        }
    }
    
    private var scoreEmoji: String {
        switch calculatedScore {
        case 9.0...10.0:
            return "🏆"
        case 8.0..<9.0:
            return "⭐"
        case 7.0..<8.0:
            return "👏"
        case 6.0..<7.0:
            return "👍"
        case 5.0..<6.0:
            return "👌"
        default:
            return "🤔"
        }
    }
    
    private var scoreInterpretation: String {
        switch calculatedScore {
        case 9.0...10.0:
            return "Outstanding course! This is a must-play destination that exceeds all expectations."
        case 8.0..<9.0:
            return "Excellent course. Highly recommended for golfers seeking a premium experience."
        case 7.0..<8.0:
            return "Very good course. Definitely worth playing again with memorable holes."
        case 6.0..<7.0:
            return "Good course with some nice features. A solid choice for your next round."
        case 5.0..<6.0:
            return "Average course. It's okay but nothing particularly special stands out."
        case 4.0..<5.0:
            return "Below average. Some issues noted that detract from the experience."
        case 3.0..<4.0:
            return "Poor course with significant problems. Not recommended."
        default:
            return "Not recommended. Consider other options for a better golf experience."
        }
    }
    
    // MARK: - Animation Methods
    
    private func startScoreAnimation() {
        // Animate title bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(ClubiAnimation.bouncy) {
                titleBounce = true
            }
        }
        
        // Animate score counting
        withAnimation(.easeOut(duration: 1.5)) {
            scoreAnimationProgress = calculatedScore
        }
        
        // Show confetti for high scores
        if calculatedScore >= 8.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(ClubiAnimation.bouncy) {
                    showConfetti = true
                }
                
                // Haptic celebration
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
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
        // First commit to local database synchronously
        do {
            try reviewSession.commitToDatabase(modelContext: modelContext)
            
            // Then generate activity asynchronously if profile available
            if let memberProfile = profileManager.currentMemberProfile {
                Task {
                    do {
                        try await ActivityManager.shared.createActivityFromReviewSession(
                            reviewSession,
                            memberProfile: memberProfile
                        )
                    } catch {
                        print("⚠️ Failed to create feed activity: \(error)")
                        // Activity creation failure doesn't affect the review
                    }
                }
            }
            
            onCompletion()
        } catch {
            print("Failed to save review: \(error)")
        }
    }
    
    private func findTiedCourse() -> Course? {
        let currentScore = calculatedScore
        
        // Get current user's ID to filter courses
        let currentUserId = course.userId
        
        // Look for courses with the same score (within 0.05 tolerance)
        // Only check courses belonging to the current user
        for otherCourse in allCourses {
            // Skip courses not belonging to current user
            if otherCourse.userId != currentUserId { continue }
            
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
    
    let course = Course(name: "Pebble Beach", location: "Pebble Beach, CA", userId: "preview")
    let answers = [ReviewAnswer(questionId: 0, selectedAnswerIndex: 0)]
    
    return ReviewSessionView(course: course, answers: answers) {
        // Preview completion handler
    }
        .modelContainer(container)
}