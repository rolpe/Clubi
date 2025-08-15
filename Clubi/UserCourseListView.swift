//
//  UserCourseListView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/12/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct UserCourseListView: View {
    let userId: String
    let displayName: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var courses: [Course] = []
    @State private var isLoading = true
    @State private var sortOption: SortOption = .highestToLowest
    
    // Check if this is the current user's own courses
    private var isOwnCourses: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return userId == currentUserId
    }
    
    // Sorted courses based on sort option
    private var sortedCourses: [Course] {
        switch sortOption {
        case .highestToLowest:
            return courses.sorted { course1, course2 in
                let score1 = course1.latestScore ?? -1
                let score2 = course2.latestScore ?? -1
                return score1 > score2
            }
        case .lowestToHighest:
            return courses.sorted { course1, course2 in
                let score1 = course1.latestScore ?? 11
                let score2 = course2.latestScore ?? 11
                return score1 < score2
            }
        case .dateReviewed:
            return courses.sorted { course1, course2 in
                let date1 = course1.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first?.dateReviewed ?? Date.distantPast
                let date2 = course2.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first?.dateReviewed ?? Date.distantPast
                return date1 > date2
            }
        case .alphabetical:
            return courses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if courses.isEmpty {
                    emptyStateView
                } else {
                    coursesList
                }
            }
            .background(Color.morningMist)
            .navigationTitle(isOwnCourses ? "My Courses" : "\(displayName)'s Courses")
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
                loadCourses()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ClubiSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                .scaleEffect(1.2)
            
            Text("Loading courses...")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Image(systemName: "flag.slash")
                .font(.system(size: 50))
                .foregroundColor(.lightGray)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text(isOwnCourses ? "No Courses Yet" : "No Courses Found")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text(isOwnCourses ? 
                     "Add and review golf courses to build your personal course collection" :
                     "\(displayName) hasn't added any courses yet")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, ClubiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Courses List
    
    private var coursesList: some View {
        List {
            // Sort Controls Section
            Section {
                HStack {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortOption = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    Spacer()
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: ClubiSpacing.sm) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14))
                                .foregroundColor(.augustaPine)
                            Text("Sort: \(sortOption.rawValue)")
                                .font(ClubiTypography.body(14, weight: .medium))
                                .foregroundColor(.charcoal)
                        }
                        .padding(.horizontal, ClubiSpacing.md)
                        .padding(.vertical, ClubiSpacing.sm)
                        .background(Color.pristineWhite)
                        .cornerRadius(ClubiRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: ClubiRadius.sm)
                                .stroke(Color.subtleLines, lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: ClubiSpacing.sm,
                leading: ClubiSpacing.lg,
                bottom: ClubiSpacing.sm,
                trailing: ClubiSpacing.lg
            ))
            
            // Courses Section
            Section {
                ForEach(sortedCourses, id: \.id) { course in
                    UserCourseRowView(course: course)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(
                            top: ClubiSpacing.sm,
                            leading: ClubiSpacing.lg,
                            bottom: ClubiSpacing.sm,
                            trailing: ClubiSpacing.lg
                        ))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    
    private func loadCourses() {
        isLoading = true
        
        Task {
            await MainActor.run {
                do {
                    let descriptor = FetchDescriptor<Course>(
                        predicate: #Predicate<Course> { course in
                            course.userId == userId
                        }
                    )
                    courses = try modelContext.fetch(descriptor)
                    isLoading = false
                } catch {
                    courses = []
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - UserCourseRowView Component

struct UserCourseRowView: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClubiSpacing.md) {
            // Main course info row
            HStack(alignment: .center, spacing: ClubiSpacing.md) {
                VStack(alignment: .leading, spacing: ClubiSpacing.xs) {
                    Text(course.name)
                        .font(ClubiTypography.headline(18))
                        .foregroundColor(.charcoal)
                        .lineLimit(2)
                    
                    HStack(spacing: ClubiSpacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.grayFairway)
                        
                        Text(course.location)
                            .font(ClubiTypography.body(14))
                            .foregroundColor(.grayFairway)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Score display or status
                if let score = course.latestScore {
                    ClubiScoreDisplay(score: score, size: .medium)
                } else {
                    ClubiTag("Not Reviewed", color: .lightGray, backgroundColor: Color.morningMist)
                }
            }
            
            // Progress bar for reviewed courses
            if let score = course.latestScore {
                ClubiProgressBar(progress: score, total: 10.0)
                    .frame(height: 4)
            }
            
            // Bottom row with tags and date
            HStack {
                // Tags based on score or status
                if let score = course.latestScore {
                    HStack(spacing: ClubiSpacing.xs) {
                        if score >= 9.0 {
                            ClubiTag("Exceptional", color: .goldenTournament)
                        } else if score >= 8.0 {
                            ClubiTag("Excellent", color: .freshGrass)
                        } else if score >= 7.0 {
                            ClubiTag("Very Good", color: .augustaPine)
                        } else if score >= 6.0 {
                            ClubiTag("Good", color: .fairwayGreen)
                        } else if score >= 4.0 {
                            ClubiTag("OK", color: .grayFairway)
                        } else {
                            ClubiTag("Poor", color: .errorRed)
                        }
                    }
                }
                
                Spacer()
                
                // Review date
                if let latestReview = course.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first {
                    Text(formatReviewDate(latestReview.dateReviewed))
                        .font(ClubiTypography.caption())
                        .foregroundColor(.lightGray)
                }
            }
        }
        .padding(ClubiSpacing.lg)
        .background(Color.pristineWhite)
        .cornerRadius(ClubiRadius.lg)
        .cardShadow()
    }
    
    private func formatReviewDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, equalTo: calendar.date(byAdding: .day, value: -1, to: now) ?? now, toGranularity: .day) {
            return "Yesterday"
        } else {
            let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if daysAgo < 7 {
                return "\(daysAgo) days ago"
            } else {
                return date.formatted(.dateTime.month(.abbreviated).day())
            }
        }
    }
}

#Preview {
    UserCourseListView(userId: "preview-user-id", displayName: "John Doe")
        .modelContainer(for: Course.self, inMemory: true)
}