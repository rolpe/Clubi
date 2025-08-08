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
            return .green
        case 2:
            return .orange
        case 3:
            return .red
        default:
            return .purple
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(maxHeight: 60)
                
                // Playoff Title
                VStack(spacing: 16) {
                    Text(playoffTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(playoffTitleColor)
                        .scaleEffect(titleBounce ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: titleBounce)
                    
                    Text("Which course do you prefer?")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                    .frame(maxHeight: 60)
                
                // VS Section
                VStack(spacing: 16) {
                    // Course Comparison
                    HStack(spacing: 0) {
                        // Left Course (New Course)
                        VStack(spacing: 12) {
                            Button(action: { 
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: getHapticStyle())
                                impactFeedback.impactOccurred()
                                
                                selectedWinner = reviewSession.course
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showingResult = true
                                    leftCourseScale = 1.1
                                }
                                
                                // Reset scale after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        leftCourseScale = 1.0
                                    }
                                }
                            }) {
                                VStack(spacing: 8) {
                                    // Course Info
                                    VStack(spacing: 4) {
                                        Text(reviewSession.course.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        Text(reviewSession.course.location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                    }
                                    
                                    // Winner Indicator (always reserves space)
                                    Text(selectedWinner == reviewSession.course ? "🏆 WINNER" : "")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .frame(height: 16) // Fixed height to prevent layout shift
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedWinner == reviewSession.course ? Color.green.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedWinner == reviewSession.course ? Color.green : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(leftCourseScale)
                        }
                        
                        // VS Divider
                        VStack {
                            Text("VS")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60)
                        
                        // Right Course (Tied Course)
                        VStack(spacing: 12) {
                            Button(action: { 
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: getHapticStyle())
                                impactFeedback.impactOccurred()
                                
                                selectedWinner = tiedCourse
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showingResult = true
                                    rightCourseScale = 1.1
                                }
                                
                                // Reset scale after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        rightCourseScale = 1.0
                                    }
                                }
                            }) {
                                VStack(spacing: 8) {
                                    // Course Info
                                    VStack(spacing: 4) {
                                        Text(tiedCourse.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        Text(tiedCourse.location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                    }
                                    
                                    // Winner Indicator (always reserves space)
                                    Text(selectedWinner == tiedCourse ? "🏆 WINNER" : "")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .frame(height: 16) // Fixed height to prevent layout shift
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedWinner == tiedCourse ? Color.green.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedWinner == tiedCourse ? Color.green : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(rightCourseScale)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Confirm Button
                    if selectedWinner != nil {
                        Button("Confirm Winner") {
                            completePlayoff()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                        .padding(.horizontal, 32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
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
                    onCancel() // This will trigger the cancellation chain back to course list
                }
            } message: {
                Text("This will discard your entire review including all playoff results. This cannot be undone.")
            }
        }
        .onAppear {
            // Bounce the title when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    titleBounce = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        titleBounce = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
    
    // MARK: - Actions
    
    private func completePlayoff() {
        guard let winner = selectedWinner else { return }
        
        // Create playoff result (no immediate persistence!)
        let playoffResult = PlayoffResult(
            opponent: tiedCourse,
            winner: winner.id
        )
        
        // Add to session (still in memory only)
        reviewSession.addPlayoffResult(playoffResult)
        
        // Check for chain playoff (limit to 3 total playoffs max)
        if playoffCount < 3 {
            if let nextTied = findTiedCourse(withScore: reviewSession.getFinalScore(), excluding: [reviewSession.course.id, tiedCourse.id]) {
                // CHAIN PLAYOFF! 🔥
                nextTiedCourse = nextTied
                return
            }
        }
        
        // No more ties or hit limit - complete the flow
        onCompletion()
    }
    
    private func findTiedCourse(withScore targetScore: Double, excluding excludedIds: [UUID]) -> Course? {
        // Look for courses with the target score (within 0.05 tolerance)
        for otherCourse in allCourses {
            // Skip excluded courses
            if excludedIds.contains(otherCourse.id) { continue }
            
            // Skip courses already involved in playoffs this session
            let alreadyInPlayoffs = reviewSession.playoffResults.contains { result in
                result.opponent.id == otherCourse.id
            }
            if alreadyInPlayoffs { continue }
            
            // Check if this course has any reviews
            guard let otherScore = otherCourse.latestScore else { continue }
            
            // Check for tie (exact match or very close)
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