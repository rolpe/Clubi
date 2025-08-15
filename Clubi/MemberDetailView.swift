//
//  MemberDetailView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/10/25.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct MemberDetailView: View {
    let member: MemberProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var profileManager = MemberProfileManager()
    @State private var isFollowing = false
    @State private var isActionInProgress = false
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var errorMessage = ""
    @State private var showingFollowersList = false
    @State private var showingFollowingList = false
    @State private var followers: [MemberProfile] = []
    @State private var following: [MemberProfile] = []
    @State private var isLoadingLists = false
    @State private var memberCourses: [Course] = []
    @State private var isLoadingCourses = false
    @State private var showingAllCourses = false
    
    // Check if this is the current user's own profile
    private var isOwnProfile: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return member.id == currentUserId
    }
    
    // Sorted courses by highest score first
    private var sortedMemberCourses: [Course] {
        return memberCourses.sorted { course1, course2 in
            let score1 = course1.latestScore ?? -1
            let score2 = course2.latestScore ?? -1
            return score1 > score2
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ClubiSpacing.xl) {
                    profileHeader
                    profileInfo
                    coursesPreview
                    
                    Spacer(minLength: ClubiSpacing.xl)
                    
                    // Show follow button only if not viewing own profile
                    if !isOwnProfile {
                        followButton
                    } else {
                        ownProfileButton
                    }
                }
                .padding(ClubiSpacing.xl)
            }
            .background(Color.morningMist)
            .navigationBarTitleDisplayMode(.inline)
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
                loadFollowingData()
                loadMemberCourses()
            }
        }
        .sheet(isPresented: $showingFollowersList) {
            MemberListView(title: "Followers", members: followers)
        }
        .sheet(isPresented: $showingFollowingList) {
            MemberListView(title: "Following", members: following)
        }
        .sheet(isPresented: $showingAllCourses) {
            UserCourseListView(userId: member.id, displayName: member.displayName)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: ClubiSpacing.lg) {
            // Large Profile Avatar
            Circle()
                .fill(Color.augustaPine.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.augustaPine)
                )
            
            // Name and Username
            VStack(spacing: ClubiSpacing.xs) {
                Text(member.displayName)
                    .font(ClubiTypography.display(26, weight: .bold))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text("@\(member.username)")
                    .font(ClubiTypography.headline(18))
                    .foregroundColor(.grayFairway)
            }
        }
    }
    
    // MARK: - Profile Info
    
    private var profileInfo: some View {
        VStack(spacing: ClubiSpacing.lg) {
            // Bio Section
            if !member.bio.isEmpty {
                profileInfoCard(
                    title: "About",
                    content: member.bio,
                    icon: "quote.bubble.fill"
                )
            }
            
            // Member Since
            profileInfoCard(
                title: "Member Since",
                content: formatJoinDate(member.dateJoined),
                icon: "calendar.badge.plus"
            )
            
            // Additional profile stats can be added here in future steps
        }
    }
    
    // MARK: - Courses Preview
    
    private var coursesPreview: some View {
        VStack(alignment: .leading, spacing: ClubiSpacing.md) {
            HStack(spacing: ClubiSpacing.sm) {
                Image(systemName: "flag.2.crossed")
                    .font(.system(size: 16))
                    .foregroundColor(.augustaPine)
                
                Text(isOwnProfile ? "My Courses" : "\(member.displayName)'s Courses")
                    .font(ClubiTypography.headline(16, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                if sortedMemberCourses.count > 3 {
                    Button("View All (\(sortedMemberCourses.count))") {
                        showingAllCourses = true
                    }
                    .font(ClubiTypography.caption(weight: .medium))
                    .foregroundColor(.augustaPine)
                }
            }
            
            if isLoadingCourses {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                        .scaleEffect(0.8)
                    
                    Text("Loading courses...")
                        .font(ClubiTypography.body())
                        .foregroundColor(.grayFairway)
                }
                .frame(height: 60)
            } else if sortedMemberCourses.isEmpty {
                VStack(spacing: ClubiSpacing.sm) {
                    Image(systemName: "flag.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.lightGray)
                    
                    Text(isOwnProfile ? "No courses added yet" : "No courses found")
                        .font(ClubiTypography.body())
                        .foregroundColor(.grayFairway)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
            } else {
                LazyVStack(spacing: ClubiSpacing.sm) {
                    ForEach(Array(sortedMemberCourses.prefix(3)), id: \.id) { course in
                        CoursePreviewRow(course: course)
                    }
                }
            }
        }
        .padding(ClubiSpacing.lg)
        .background(Color.pristineWhite)
        .cornerRadius(ClubiRadius.md)
        .cardShadow()
    }
    
    // MARK: - Profile Info Card
    
    private func profileInfoCard(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: ClubiSpacing.md) {
            HStack(spacing: ClubiSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.augustaPine)
                
                Text(title)
                    .font(ClubiTypography.headline(16, weight: .semibold))
                    .foregroundColor(.charcoal)
            }
            
            Text(content)
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ClubiSpacing.lg)
        .background(Color.pristineWhite)
        .cornerRadius(ClubiRadius.md)
        .cardShadow()
    }
    
    // MARK: - Follow Button
    
    private var followButton: some View {
        VStack(spacing: ClubiSpacing.md) {
            // Follower/Following stats
            HStack(spacing: ClubiSpacing.xl) {
                Button(action: {
                    loadFollowersList()
                }) {
                    VStack(spacing: ClubiSpacing.xs) {
                        if isLoadingLists {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                                .scaleEffect(0.8)
                                .frame(height: 24)
                        } else {
                            Text("\(followerCount)")
                                .font(ClubiTypography.headline(20, weight: .bold))
                                .foregroundColor(.charcoal)
                        }
                        Text("Followers")
                            .font(ClubiTypography.caption())
                            .foregroundColor(.grayFairway)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoadingLists)
                
                Button(action: {
                    loadFollowingList()
                }) {
                    VStack(spacing: ClubiSpacing.xs) {
                        if isLoadingLists {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                                .scaleEffect(0.8)
                                .frame(height: 24)
                        } else {
                            Text("\(followingCount)")
                                .font(ClubiTypography.headline(20, weight: .bold))
                                .foregroundColor(.charcoal)
                        }
                        Text("Following")
                            .font(ClubiTypography.caption())
                            .foregroundColor(.grayFairway)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoadingLists)
            }
            .padding(.bottom, ClubiSpacing.md)
            
            // Follow/Unfollow Button
            Button(action: {
                handleFollowToggle()
            }) {
                HStack {
                    if isActionInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pristineWhite))
                            .scaleEffect(0.8)
                    }
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(ClubiTypography.body(weight: .semibold))
                }
            }
            .disabled(isActionInProgress)
            .clubiPrimaryButton(isDisabled: isActionInProgress)
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(ClubiTypography.caption())
                    .foregroundColor(.errorRed)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Own Profile Button
    
    private var ownProfileButton: some View {
        VStack(spacing: ClubiSpacing.md) {
            // Follower/Following stats (same as follow button)
            HStack(spacing: ClubiSpacing.xl) {
                Button(action: {
                    loadFollowersList()
                }) {
                    VStack(spacing: ClubiSpacing.xs) {
                        if isLoadingLists {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                                .scaleEffect(0.8)
                                .frame(height: 24)
                        } else {
                            Text("\(followerCount)")
                                .font(ClubiTypography.headline(20, weight: .bold))
                                .foregroundColor(.charcoal)
                        }
                        Text("Followers")
                            .font(ClubiTypography.caption())
                            .foregroundColor(.grayFairway)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoadingLists)
                
                Button(action: {
                    loadFollowingList()
                }) {
                    VStack(spacing: ClubiSpacing.xs) {
                        if isLoadingLists {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                                .scaleEffect(0.8)
                                .frame(height: 24)
                        } else {
                            Text("\(followingCount)")
                                .font(ClubiTypography.headline(20, weight: .bold))
                                .foregroundColor(.charcoal)
                        }
                        Text("Following")
                            .font(ClubiTypography.caption())
                            .foregroundColor(.grayFairway)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoadingLists)
            }
            .padding(.bottom, ClubiSpacing.md)
            
            // Edit Profile Button (instead of Follow button)
            Button(action: {
                dismiss()
                // Note: This will close the profile view, user can then access Edit Profile from menu
            }) {
                Text("Edit Profile")
                    .font(ClubiTypography.body(weight: .semibold))
            }
            .clubiPrimaryButton(isDisabled: false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadFollowingData() {
        Task {
            do {
                if isOwnProfile {
                    // For own profile, just load counts
                    async let followerCountResult = profileManager.getFollowerCount(userId: member.id)
                    async let followingCountResult = profileManager.getFollowingCount(userId: member.id)
                    
                    let results = try await (followerCountResult, followingCountResult)
                    
                    await MainActor.run {
                        isFollowing = false // Not applicable for own profile
                        followerCount = results.0
                        followingCount = results.1
                        errorMessage = ""
                    }
                } else {
                    // For other profiles, load following status and counts
                    async let followingStatus = profileManager.checkIfFollowing(userId: member.id)
                    async let followerCountResult = profileManager.getFollowerCount(userId: member.id)
                    async let followingCountResult = profileManager.getFollowingCount(userId: member.id)
                    
                    let results = try await (followingStatus, followerCountResult, followingCountResult)
                    
                    await MainActor.run {
                        isFollowing = results.0
                        followerCount = results.1
                        followingCount = results.2
                        errorMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load member data"
                }
            }
        }
    }
    
    private func handleFollowToggle() {
        guard !isActionInProgress else { return }
        
        isActionInProgress = true
        errorMessage = ""
        
        Task {
            do {
                if isFollowing {
                    try await profileManager.unfollowMember(userId: member.id)
                    await MainActor.run {
                        isFollowing = false
                        followerCount = max(0, followerCount - 1)
                    }
                } else {
                    try await profileManager.followMember(userId: member.id)
                    await MainActor.run {
                        isFollowing = true
                        followerCount += 1
                    }
                }
            } catch {
                await MainActor.run {
                    if let profileError = error as? ProfileError {
                        switch profileError {
                        case .notAuthenticated:
                            errorMessage = "Please log in to follow members"
                        case .invalidInput:
                            errorMessage = "Cannot follow yourself"
                        default:
                            errorMessage = "Failed to update following status"
                        }
                    } else {
                        errorMessage = "Failed to update following status: \(error.localizedDescription)"
                    }
                }
            }
            
            await MainActor.run {
                isActionInProgress = false
            }
        }
    }
    
    private func loadFollowersList() {
        guard !isLoadingLists else { return }
        
        isLoadingLists = true
        
        Task {
            do {
                let followersList = try await profileManager.getFollowers(userId: member.id)
                
                await MainActor.run {
                    followers = followersList
                    showingFollowersList = true
                    isLoadingLists = false
                }
            } catch {
                await MainActor.run {
                    isLoadingLists = false
                    // Could show error but for now just fail silently
                }
            }
        }
    }
    
    private func loadFollowingList() {
        guard !isLoadingLists else { return }
        
        isLoadingLists = true
        
        Task {
            do {
                let followingList = try await profileManager.getFollowing(userId: member.id)
                
                await MainActor.run {
                    following = followingList
                    showingFollowingList = true
                    isLoadingLists = false
                }
            } catch {
                await MainActor.run {
                    isLoadingLists = false
                    // Could show error but for now just fail silently
                }
            }
        }
    }
    
    private func formatJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func loadMemberCourses() {
        isLoadingCourses = true
        
        Task {
            await MainActor.run {
                do {
                    let descriptor = FetchDescriptor<Course>(
                        predicate: #Predicate<Course> { course in
                            course.userId == member.id
                        }
                    )
                    memberCourses = try modelContext.fetch(descriptor)
                    isLoadingCourses = false
                } catch {
                    memberCourses = []
                    isLoadingCourses = false
                }
            }
        }
    }
}

// MARK: - CoursePreviewRow Component

struct CoursePreviewRow: View {
    let course: Course
    
    var body: some View {
        HStack(spacing: ClubiSpacing.md) {
            // Course icon
            Circle()
                .fill(Color.augustaPine.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "flag.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.augustaPine)
                )
            
            // Course info
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(ClubiTypography.body(weight: .medium))
                    .foregroundColor(.charcoal)
                    .lineLimit(1)
                
                Text(course.location)
                    .font(ClubiTypography.caption())
                    .foregroundColor(.grayFairway)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Score or status
            if let score = course.latestScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", score))
                        .font(ClubiTypography.body(weight: .semibold))
                        .foregroundColor(scoreColor(for: score))
                    
                    Text("score")
                        .font(ClubiTypography.caption())
                        .foregroundColor(.grayFairway)
                }
            } else {
                Text("Not reviewed")
                    .font(ClubiTypography.caption())
                    .foregroundColor(.grayFairway)
            }
        }
        .padding(.horizontal, ClubiSpacing.md)
        .padding(.vertical, ClubiSpacing.sm)
        .background(Color.morningMist.opacity(0.3))
        .cornerRadius(ClubiRadius.sm)
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
}

#Preview {
    MemberDetailView(
        member: MemberProfile(
            id: "1",
            email: "john@example.com",
            username: "johndoe",
            displayName: "John Doe",
            bio: "Passionate golfer who loves exploring new courses and improving my game. I've been playing for over 10 years and enjoy both casual rounds and competitive play. Always looking to connect with fellow golf enthusiasts!"
        )
    )
}