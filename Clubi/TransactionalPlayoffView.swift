//
//  TransactionalPlayoffView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/6/25.
//

import SwiftUI
import SwiftData

struct TransactionalPlayoffView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allCourses: [Course]
    
    @ObservedObject var reviewSession: ReviewSession
    let tiedCourse: Course
    let playoffCount: Int
    let onCompletion: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedWinner: Course?
    @State private var showingResult = false
    @State private var showingNextPlayoff = false
    @State private var nextTiedCourse: Course?
    @State private var titleBounce = false
    @State private var leftCourseScale = 1.0
    @State private var rightCourseScale = 1.0
    @State private var showingCancelAlert = false
    
    init(reviewSession: ReviewSession, tiedCourse: Course, playoffCount: Int = 1, onCompletion: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.reviewSession = reviewSession
        self.tiedCourse = tiedCourse
        self.playoffCount = playoffCount
        self.onCompletion = onCompletion
        self.onCancel = onCancel
    }
    
    private var playoffTitle: String {
        switch playoffCount {
        case 1:
            return "⛳ PLAYOFF! ⛳"
        case 2:
            return "🔥 DOUBLE PLAYOFF! 🔥"
        case 3:
            return "💥 TRIPLE PLAYOFF! 💥"
        default:
            return "🚨 MEGA PLAYOFF! 🚨"
        }
    }
    
    private var playoffTitleColor: Color {
        switch playoffCount {
        case 1:
            return Color.fairwayGreen
        case 2:
            return Color.sunsetOrange
        case 3:
            return Color.errorRed
        default:
            return Color.augustaPine
        }
    }
    
    private var playoffGradient: LinearGradient {
        switch playoffCount {
        case 1:
            return LinearGradient(
                gradient: Gradient(colors: [Color.fairwayGreen.opacity(0.8), Color.freshGrass.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                gradient: Gradient(colors: [Color.sunsetOrange.opacity(0.8), Color.goldenTournament.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                gradient: Gradient(colors: [Color.errorRed.opacity(0.8), Color.sunsetOrange.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color.augustaPine.opacity(0.8), Color.fairwayGreen.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                playoffGradient
                    .ignoresSafeArea()
                
                // Animated background elements
                ZStack {
                    Circle()
                        .fill(Color.pristineWhite.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .offset(x: -100, y: -200)
                        .scaleEffect(titleBounce ? 1.2 : 1.0)
                        .animation(ClubiAnimation.smooth, value: titleBounce)
                    
                    Circle()
                        .fill(Color.pristineWhite.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .offset(x: 120, y: 150)
                        .scaleEffect(titleBounce ? 0.8 : 1.0)
                        .animation(ClubiAnimation.smooth.delay(0.2), value: titleBounce)
                }
                
                ScrollView {
                    VStack(spacing: ClubiSpacing.xxl) {
                        Spacer().frame(height: ClubiSpacing.lg)
                        
                        // Playoff Header
                        VStack(spacing: ClubiSpacing.lg) {
                            VStack(spacing: ClubiSpacing.md) {
                                Text(playoffTitle)
                                    .font(ClubiTypography.display(28, weight: .black))
                                    .foregroundColor(Color.pristineWhite)
                                    .shadow(color: Color.charcoal.opacity(0.3), radius: 4, x: 0, y: 2)
                                    .scaleEffect(titleBounce ? 1.15 : 1.0)
                                    .animation(ClubiAnimation.bouncy, value: titleBounce)
                                
                                Rectangle()
                                    .fill(Color.pristineWhite.opacity(0.8))
                                    .frame(width: 60, height: 2)
                                    .scaleEffect(x: titleBounce ? 1.5 : 1.0)
                                    .animation(ClubiAnimation.smooth, value: titleBounce)
                                
                                Text("Which course do you prefer?")
                                    .font(ClubiTypography.headline(18, weight: .semibold))
                                    .foregroundColor(Color.pristineWhite)
                                    .shadow(color: Color.charcoal.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(ClubiSpacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: ClubiRadius.lg)
                                .fill(Color.charcoal.opacity(0.3))
                                .background(
                                    RoundedRectangle(cornerRadius: ClubiRadius.lg)
                                        .fill(.ultraThinMaterial)
                                )
                        )
                        .cardShadow()
                        
                        // Battle Section
                        VStack(spacing: ClubiSpacing.lg) {
                            // Your Review Course Card
                            courseCardButton(
                                course: reviewSession.course,
                                label: "YOUR REVIEW",
                                labelColor: Color.goldenTournament,
                                isSelected: selectedWinner == reviewSession.course,
                                action: {
                                    selectWinner(reviewSession.course, scale: $leftCourseScale)
                                }
                            )
                            .scaleEffect(leftCourseScale)
                            
                            // VS Divider
                            Text("VS")
                                .font(ClubiTypography.display(28, weight: .black))
                                .foregroundColor(Color.pristineWhite)
                                .shadow(color: Color.charcoal.opacity(0.5), radius: 3, x: 0, y: 2)
                                .scaleEffect(titleBounce ? 1.1 : 1.0)
                                .animation(ClubiAnimation.bouncy, value: titleBounce)
                            
                            // Challenger Course Card
                            courseCardButton(
                                course: tiedCourse,
                                label: "CHALLENGER",
                                labelColor: Color.augustaPine,
                                isSelected: selectedWinner == tiedCourse,
                                action: {
                                    selectWinner(tiedCourse, scale: $rightCourseScale)
                                }
                            )
                            .scaleEffect(rightCourseScale)
                        }
                        
                        // Confirm Button
                        if selectedWinner != nil {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                completePlayoff()
                            }) {
                                Text("Confirm")
                                    .font(ClubiTypography.headline(weight: .bold))
                                .foregroundColor(Color.pristineWhite)
                            }
                            .clubiPrimaryButton()
                            .scaleEffect(showingResult ? 1.05 : 1.0)
                            .animation(ClubiAnimation.bouncy, value: showingResult)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.horizontal, ClubiSpacing.xl)
                        }
                        
                        Spacer().frame(height: ClubiSpacing.xxl)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                }
            }
            .fullScreenCover(item: $nextTiedCourse) { nextTied in
                TransactionalPlayoffView(
                    reviewSession: reviewSession,
                    tiedCourse: nextTied,
                    playoffCount: playoffCount + 1,
                    onCompletion: onCompletion,
                    onCancel: onCancel
                )
            }
            .alert("Cancel Review?", isPresented: $showingCancelAlert) {
                Button("Keep Reviewing", role: .cancel) {}
                Button("Discard Review", role: .destructive) {
                    onCancel()
                }
            } message: {
                Text("This will discard your entire review including all playoff results. This cannot be undone.")
            }
            .onAppear {
                startDramaticEntrance()
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func courseCardButton(
        course: Course,
        label: String,
        labelColor: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: ClubiSpacing.md) {
                // Header Badge
                HStack {
                    Text(label)
                        .font(ClubiTypography.caption(weight: .bold))
                        .foregroundColor(isSelected ? Color.pristineWhite : labelColor)
                        .padding(.horizontal, ClubiSpacing.sm)
                        .padding(.vertical, ClubiSpacing.xs)
                        .background(
                            Capsule()
                                .fill(isSelected ? labelColor.opacity(0.3) : labelColor.opacity(0.1))
                        )
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.pristineWhite)
                            .scaleEffect(showingResult ? 1.2 : 1.0)
                            .animation(ClubiAnimation.bouncy, value: showingResult)
                    }
                }
                
                // Course Info
                VStack(spacing: ClubiSpacing.sm) {
                    Text(course.name)
                        .font(ClubiTypography.display(20, weight: .bold))
                        .foregroundColor(isSelected ? Color.pristineWhite : Color.charcoal)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: ClubiSpacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? Color.pristineWhite.opacity(0.8) : Color.grayFairway)
                        
                        Text(course.location)
                            .font(ClubiTypography.body(16, weight: .medium))
                            .foregroundColor(isSelected ? Color.pristineWhite.opacity(0.8) : Color.grayFairway)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
            }
            .padding(ClubiSpacing.xl)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ClubiRadius.lg)
                    .fill(isSelected ? playoffTitleColor : Color.pristineWhite)
                    .shadow(color: Color.charcoal.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: ClubiRadius.lg)
                            .stroke(
                                isSelected ? Color.pristineWhite.opacity(0.6) : Color.augustaPine.opacity(0.3),
                                lineWidth: isSelected ? 3 : 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func selectWinner(_ winner: Course, scale: Binding<Double>) {
        let impactFeedback = UIImpactFeedbackGenerator(style: getHapticStyle())
        impactFeedback.impactOccurred()
        
        selectedWinner = winner
        withAnimation(ClubiAnimation.bouncy) {
            showingResult = true
            scale.wrappedValue = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(ClubiAnimation.smooth) {
                scale.wrappedValue = 1.0
            }
        }
    }
    
    private func startDramaticEntrance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(ClubiAnimation.bouncy) {
                titleBounce = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(ClubiAnimation.bouncy) {
                titleBounce = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(ClubiAnimation.quick) {
                titleBounce = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(ClubiAnimation.smooth) {
                titleBounce = false
            }
        }
    }
    
    private func getHapticStyle() -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch playoffCount {
        case 1:
            return .medium
        case 2:
            return .heavy
        default:
            return .rigid
        }
    }
    
    private func completePlayoff() {
        guard let winner = selectedWinner else { return }
        
        let playoffResult = PlayoffResult(
            opponent: tiedCourse,
            winner: winner.id
        )
        
        reviewSession.addPlayoffResult(playoffResult)
        
        if playoffCount < 3 {
            if let nextTied = findTiedCourse(withScore: reviewSession.getFinalScore(), excluding: [reviewSession.course.id, tiedCourse.id]) {
                nextTiedCourse = nextTied
                return
            }
        }
        
        onCompletion()
    }
    
    private func findTiedCourse(withScore targetScore: Double, excluding excludedIds: [UUID]) -> Course? {
        for otherCourse in allCourses {
            if excludedIds.contains(otherCourse.id) { continue }
            
            let alreadyInPlayoffs = reviewSession.playoffResults.contains { result in
                result.opponent.id == otherCourse.id
            }
            if alreadyInPlayoffs { continue }
            
            guard let otherScore = otherCourse.latestScore else { continue }
            
            if abs(otherScore - targetScore) < 0.05 {
                return otherCourse
            }
        }
        
        return nil
    }
}

#Preview {
    let course1 = Course(name: "Augusta National", location: "Augusta, GA")
    let course2 = Course(name: "Pebble Beach", location: "Pebble Beach, CA")
    let answers = [ReviewAnswer(questionId: 0, selectedAnswerIndex: 0)]
    let session = ReviewSession(course: course1, answers: answers)
    
    TransactionalPlayoffView(
        reviewSession: session,
        tiedCourse: course2,
        playoffCount: 1,
        onCompletion: {},
        onCancel: {}
    )
}
