//
//  FollowingListView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/10/25.
//

import SwiftUI

struct FollowingListView: View {
    let userId: String
    let onFindMembers: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = MemberProfileManager()
    @State private var following: [MemberProfile] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var selectedMember: MemberProfile?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    loadingView
                } else if following.isEmpty {
                    emptyStateView
                } else {
                    membersList
                }
            }
            .background(Color.morningMist)
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(ClubiTypography.body(weight: .medium))
                    .foregroundColor(.augustaPine)
                }
            }
            .onAppear {
                loadFollowing()
            }
        }
        .sheet(item: $selectedMember) { member in
            MemberDetailView(member: member)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ClubiSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                .scaleEffect(1.2)
            
            Text("Loading following...")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.lightGray)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("Not Following Anyone Yet")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text("Discover and follow other members to see their course reviews and activity")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button("Find Members") {
                dismiss()
                onFindMembers?()
            }
            .clubiPrimaryButton(isDisabled: false)
        }
        .padding(.horizontal, ClubiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Members List
    
    private var membersList: some View {
        ScrollView {
            LazyVStack(spacing: ClubiSpacing.md) {
                ForEach(following, id: \.id) { member in
                    MemberRowView(member: member) {
                        selectedMember = member
                    }
                }
            }
            .padding(.horizontal, ClubiSpacing.lg)
            .padding(.top, ClubiSpacing.sm)
        }
    }
    
    // MARK: - Actions
    
    private func loadFollowing() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let followingList = try await profileManager.getFollowing(userId: userId)
                
                await MainActor.run {
                    following = followingList
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load following list"
                    following = []
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    FollowingListView(userId: "preview-user-id", onFindMembers: nil)
}
