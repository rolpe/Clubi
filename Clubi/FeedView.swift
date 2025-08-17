//
//  FeedView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var feedManager = FeedManager.shared
    
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
                if feedManager.isLoading {
                    loadingView
                } else if feedManager.activities.isEmpty {
                    emptyStateView
                } else {
                    activitiesList
                }
            }
            .background(Color.morningMist)
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await feedManager.loadFeedActivities()
                }
                feedManager.startListeningForFeedUpdates()
            }
            .onDisappear {
                feedManager.stopListening()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ClubiSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                .scaleEffect(1.2)
            
            Text("Loading your feed...")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                ForEach(feedManager.activities, id: \.id) { activity in
                    FeedActivityRow(activity: activity)
                }
            }
            .padding(.horizontal, ClubiSpacing.lg)
            .padding(.top, ClubiSpacing.sm)
        }
        .refreshable {
            Task {
                await feedManager.refreshFeed()
            }
        }
    }
}

#Preview {
    FeedView()
}