//
//  FeedView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var feedManager = FeedManager.shared
    @State private var hasAppeared = false
    
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
                } else if feedManager.hasError {
                    errorView
                } else if feedManager.activities.isEmpty {
                    emptyStateView
                } else {
                    activitiesList
                }
            }
            .background(Color.morningMist)
            .navigationBarHidden(true)
            .onAppear {
                if !hasAppeared {
                    // First time appearing - load normally
                    Task {
                        await feedManager.loadFeedActivities()
                    }
                    hasAppeared = true
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
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.errorRed)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("Unable to Load Feed")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text(feedManager.errorMessage.isEmpty ? "Something went wrong. Please try again." : feedManager.errorMessage)
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button("Try Again") {
                Task {
                    await feedManager.retryLoading()
                }
            }
            .clubiPrimaryButton()
            
            Spacer()
        }
        .padding(.horizontal, ClubiSpacing.xl)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Spacer()
            
            Image(systemName: "heart.text.square")
                .font(.system(size: 50))
                .foregroundColor(.lightGray)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("Your Feed is Empty")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text("Start following other golfers to see their latest course reviews and discoveries in your feed. Connect with the community and never miss a great course recommendation!")
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
                    FeedActivityRow(activity: activity) {
                        // Refresh feed when profile sheet is dismissed
                        Task {
                            await feedManager.refreshFeed()
                        }
                    }
                    .onAppear {
                        // Load more when approaching end of list
                        if activity.id == feedManager.activities.last?.id {
                            Task {
                                await feedManager.loadMoreActivities()
                            }
                        }
                    }
                }
                
                // Loading more indicator
                if feedManager.isLoadingMore {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                            .scaleEffect(0.8)
                        Text("Loading more...")
                            .font(ClubiTypography.caption())
                            .foregroundColor(.grayFairway)
                    }
                    .padding(.vertical, ClubiSpacing.lg)
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