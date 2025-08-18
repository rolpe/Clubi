//
//  FeedActivityRow.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import SwiftUI

struct FeedActivityRow: View {
    let activity: FeedActivity
    let onProfileDismissed: (() -> Void)?
    @State private var showingProfile = false
    @State private var memberProfile: MemberProfile?
    @State private var isLoadingProfile = false
    @State private var profileLoadError: String?
    @State private var showingErrorAlert = false
    @StateObject private var profileManager = MemberProfileManager()
    
    init(activity: FeedActivity, onProfileDismissed: (() -> Void)? = nil) {
        self.activity = activity
        self.onProfileDismissed = onProfileDismissed
    }
    
    var body: some View {
        HStack(spacing: ClubiSpacing.md) {
            // Activity icon
            Circle()
                .fill(activityColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: activity.activityType.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(activityColor)
                )
            
            // Activity content
            VStack(alignment: .leading, spacing: ClubiSpacing.xs) {
                // Member and action
                HStack(spacing: 4) {
                    Text(activity.userDisplayName)
                        .font(ClubiTypography.body(weight: .semibold))
                        .foregroundColor(.augustaPine)
                        .onTapGesture {
                            guard !isLoadingProfile else { return }
                            Task {
                                await loadMemberProfile()
                            }
                        }
                    
                    Text(activity.activityType.displayText)
                        .font(ClubiTypography.body())
                        .foregroundColor(.grayFairway)
                }
                
                // Course info
                HStack(spacing: ClubiSpacing.xs) {
                    Text(activity.courseName)
                        .font(ClubiTypography.body(weight: .medium))
                        .foregroundColor(.augustaPine)
                        .lineLimit(1)
                    
                    if let score = activity.score {
                        Text("•")
                            .font(ClubiTypography.caption())
                            .foregroundColor(.lightGray)
                        
                        Text(String(format: "%.1f", score))
                            .font(ClubiTypography.body(weight: .semibold))
                            .foregroundColor(scoreColor(for: score))
                    }
                }
                
                // Location and timestamp
                HStack(spacing: ClubiSpacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.lightGray)
                    
                    Text(activity.courseLocation)
                        .font(ClubiTypography.caption())
                        .foregroundColor(.grayFairway)
                        .lineLimit(1)
                    
                    Text("•")
                        .font(ClubiTypography.caption())
                        .foregroundColor(.lightGray)
                    
                    Text(timeAgoString(from: activity.timestamp))
                        .font(ClubiTypography.caption())
                        .foregroundColor(.lightGray)
                }
            }
            
            Spacer()
        }
        .padding(ClubiSpacing.lg)
        .background(Color.pristineWhite)
        .cornerRadius(ClubiRadius.md)
        .cardShadow()
        .sheet(item: $memberProfile, onDismiss: {
            // Call the callback when sheet is dismissed
            onProfileDismissed?()
        }) { profile in
            MemberDetailView(member: profile)
        }
        .alert("Unable to Load Profile", isPresented: $showingErrorAlert) {
            Button("OK") {
                profileLoadError = nil
            }
        } message: {
            Text(profileLoadError ?? "Something went wrong. Please try again.")
        }
    }
    
    // MARK: - Helper Properties
    
    private var activityColor: Color {
        switch activity.activityType {
        case .courseReviewed:
            return .goldenTournament
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 9.0 {
            return .goldenTournament
        } else if score >= 8.0 {
            return .freshGrass
        } else if score >= 7.0 {
            return .augustaPine
        } else if score >= 6.0 {
            return .fairwayGreen
        } else if score >= 4.0 {
            return .grayFairway
        } else {
            return .errorRed
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            if days == 1 {
                return "1 day ago"
            } else if days < 7 {
                return "\(days) days ago"
            } else {
                return date.formatted(.dateTime.month(.abbreviated).day())
            }
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadMemberProfile() async {
        guard !isLoadingProfile else { return }
        
        isLoadingProfile = true
        profileLoadError = nil
        
        do {
            let profile = try await profileManager.getMemberProfile(userId: activity.userId)
            await MainActor.run {
                memberProfile = profile
                isLoadingProfile = false
            }
        } catch {
            let errorMessage = "Failed to load profile for \(activity.userDisplayName)"
            print("\(errorMessage): \(error)")
            await MainActor.run {
                profileLoadError = errorMessage
                showingErrorAlert = true
                isLoadingProfile = false
            }
        }
    }
}

#Preview {
    VStack(spacing: ClubiSpacing.md) {
        // Course reviewed activity - high score
        FeedActivityRow(
            activity: FeedActivity(
                userId: "user1",
                userDisplayName: "Sarah Miller",
                userUsername: "sarahgolf",
                activityType: .courseReviewed,
                courseId: "course1",
                courseName: "Pebble Beach Golf Links",
                courseLocation: "Pebble Beach, CA",
                score: 8.7
            )
        )
        
        // Course reviewed activity - low score
        FeedActivityRow(
            activity: FeedActivity(
                userId: "user2",
                userDisplayName: "Mike Johnson",
                userUsername: "mikej",
                activityType: .courseReviewed,
                courseId: "course2",
                courseName: "Augusta National Golf Club",
                courseLocation: "Augusta, GA",
                score: 6.2
            )
        )
    }
    .padding()
    .background(Color.morningMist)
}