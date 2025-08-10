//
//  PlayoffView.swift  
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import SwiftUI
import SwiftData

struct PlayoffView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCourses: [Course]
    
    let newCourse: Course
    let newAnswers: [ReviewAnswer]
    let tiedCourse: Course
    let playoffCount: Int
    let onCompletion: () -> Void
    
    @State private var selectedWinner: Course?
    @State private var showingResult = false
    @State private var showingNextPlayoff = false
    @State private var nextTiedCourse: Course?
    @State private var titleBounce = false
    @State private var leftCourseScale = 1.0
    @State private var rightCourseScale = 1.0
    
    private var newScore: Double {
        Review.calculateScore(from: newAnswers)
    }
    
    init(newCourse: Course, newAnswers: [ReviewAnswer], tiedCourse: Course, playoffCount: Int = 1, onCompletion: @escaping () -> Void) {
        self.newCourse = newCourse
        self.newAnswers = newAnswers
        self.tiedCourse = tiedCourse
        self.playoffCount = playoffCount
        self.onCompletion = onCompletion
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
                                
                                selectedWinner = newCourse
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
                                        Text(newCourse.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        Text(newCourse.location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                    }
                                    
                                    // Winner Indicator (always reserves space)
                                    Text(selectedWinner == newCourse ? "🏆 WINNER" : "")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .frame(height: 16) // Fixed height to prevent layout shift
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedWinner == newCourse ? Color.green.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedWinner == newCourse ? Color.green : Color.clear, lineWidth: 2)
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
                        dismiss()
                    }
                }
            }
            .fullScreenCover(item: $nextTiedCourse) { nextTied in
                PlayoffView(
                    newCourse: newCourse,
                    newAnswers: newAnswers,
                    tiedCourse: nextTied,
                    playoffCount: playoffCount + 1,
                    onCompletion: onCompletion
                )
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
        
        // For playoff chains, we need to either update existing review or track the current score
        // Check if newCourse already has a review (from previous playoff)
        let existingReview = newCourse.reviews.first
        let currentNewCourseScore: Double
        
        if let existing = existingReview {
            // Course already has a review (from previous playoff) - update it
            currentNewCourseScore = existing.calculatedScore
        } else {
            // First review for this course
            currentNewCourseScore = newScore
        }
        
        // Adjust scores based on playoff result
        let winnerScore: Double
        
        if winner == newCourse {
            // New course wins: +0.1, tied course gets -0.1
            winnerScore = currentNewCourseScore + 0.1
            
            if let existing = existingReview {
                // Update existing review
                existing.calculatedScore = winnerScore
            } else {
                // Create new review
                let newReview = Review(courseId: newCourse.id, answers: newAnswers)
                newReview.calculatedScore = winnerScore
                newReview.course = newCourse
                modelContext.insert(newReview)
            }
            
            adjustTiedCourseScore(by: -0.1)
        } else {
            // Tied course wins: new course gets -0.1, tied gets +0.1
            winnerScore = (tiedCourse.latestScore ?? 0.0) + 0.1
            
            if let existing = existingReview {
                // Update existing review
                existing.calculatedScore = currentNewCourseScore - 0.1
            } else {
                // Create new review
                let newReview = Review(courseId: newCourse.id, answers: newAnswers)
                newReview.calculatedScore = currentNewCourseScore - 0.1
                newReview.course = newCourse
                modelContext.insert(newReview)
            }
            
            adjustTiedCourseScore(by: +0.1)
        }
        
        // Save changes
        try? modelContext.save()
        
        // Check for chain playoff (limit to 3 total playoffs max)
        if playoffCount < 3 {
            if let nextTied = findTiedCourse(withScore: winnerScore, excluding: [newCourse.id, tiedCourse.id]) {
                // CHAIN PLAYOFF! 🔥
                nextTiedCourse = nextTied
                return
            }
        }
        
        // No more ties or hit limit - complete the flow
        onCompletion()
    }
    
    private func adjustTiedCourseScore(by adjustment: Double) {
        // Find the latest review for the tied course and adjust its score
        if let latestReview = tiedCourse.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first {
            latestReview.calculatedScore += adjustment
            // Ensure score stays within bounds
            latestReview.calculatedScore = max(0.0, min(10.0, latestReview.calculatedScore))
        }
    }
    
    private func findTiedCourse(withScore targetScore: Double, excluding excludedIds: [UUID]) -> Course? {
        // Look for courses with the target score (within 0.05 tolerance)
        for otherCourse in allCourses {
            // Skip excluded courses
            if excludedIds.contains(otherCourse.id) { continue }
            
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
    let course1 = Course(name: "Augusta National", location: "Augusta, GA", userId: "preview")
    let course2 = Course(name: "Pebble Beach", location: "Pebble Beach, CA", userId: "preview")
    let answers = [ReviewAnswer(questionId: 0, selectedAnswerIndex: 0)]
    
    PlayoffView(
        newCourse: course1,
        newAnswers: answers, 
        tiedCourse: course2,
        playoffCount: 1,
        onCompletion: {}
    )
}