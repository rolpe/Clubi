//
//  FeedView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import SwiftUI

struct FeedView: View {
    @State private var activities: [FeedActivity] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundColor(.augustaPine)
                    Text("Feed")
                        .font(ClubiTypography.display(24, weight: .bold))
                        .foregroundColor(.charcoal)
                    Spacer()
                }
                .padding(.horizontal, ClubiSpacing.lg)
                .padding(.top, ClubiSpacing.lg)
                .padding(.bottom, ClubiSpacing.md)
                
                // Content
                if activities.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    activitiesList
                }
            }
            .background(Color.morningMist)
            .navigationBarHidden(true)
            .onAppear {
                loadMockActivities()
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Spacer()
            
            Image(systemName: "heart.text.square")
                .font(.system(size: 50))
                .foregroundColor(.lightGray)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("No Activity Yet")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text("Follow other golf enthusiasts to see their course reviews and activity in your feed")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button("Find Members") {
                // Will connect to member search later
            }
            .clubiPrimaryButton()
            
            Spacer()
        }
        .padding(.horizontal, ClubiSpacing.xl)
    }
    
    // MARK: - Activities List
    
    private var activitiesList: some View {
        ScrollView {
            LazyVStack(spacing: ClubiSpacing.md) {
                ForEach(activities, id: \.id) { activity in
                    FeedActivityRow(activity: activity)
                }
            }
            .padding(.horizontal, ClubiSpacing.lg)
            .padding(.top, ClubiSpacing.sm)
        }
    }
    
    // MARK: - Mock Data
    
    private func loadMockActivities() {
        // Create some mock activities to show the UI
        activities = [
            FeedActivity(
                userId: "user1",
                userDisplayName: "Sarah Miller",
                userUsername: "sarahgolf",
                activityType: .courseReviewed,
                courseId: "course1",
                courseName: "Pebble Beach Golf Links",
                courseLocation: "Pebble Beach, CA",
                score: 8.7
            ),
            FeedActivity(
                userId: "user2",
                userDisplayName: "Mike Johnson",
                userUsername: "mikej",
                activityType: .courseReviewed,
                courseId: "course2",
                courseName: "Augusta National Golf Club",
                courseLocation: "Augusta, GA",
                score: 9.4
            ),
            FeedActivity(
                userId: "user3",
                userDisplayName: "Emma Davis",
                userUsername: "emmagolf",
                activityType: .courseReviewed,
                courseId: "course3",
                courseName: "Torrey Pines Golf Course",
                courseLocation: "La Jolla, CA",
                score: 9.2
            ),
            FeedActivity(
                userId: "user4",
                userDisplayName: "Alex Chen",
                userUsername: "alexc",
                activityType: .courseReviewed,
                courseId: "course4",
                courseName: "Whistling Straits",
                courseLocation: "Kohler, WI",
                score: 7.3
            ),
            FeedActivity(
                userId: "user1",
                userDisplayName: "Sarah Miller",
                userUsername: "sarahgolf",
                activityType: .courseReviewed,
                courseId: "course5",
                courseName: "Bethpage Black",
                courseLocation: "Farmingdale, NY",
                score: 6.8
            )
        ]
    }
}

#Preview {
    FeedView()
}