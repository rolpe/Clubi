//
//  ContentView.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case highestToLowest = "Highest to Lowest Score"
    case lowestToHighest = "Lowest to Highest Score"
    case dateReviewed = "Recently Reviewed"
    case alphabetical = "Alphabetical"
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var showingAddCourse = false
    @State private var selectedCourse: Course?
    @State private var selectedCourseForDetail: Course?
    @State private var courseToDelete: Course?
    @State private var showingDeleteAlert = false
    @State private var sortOption: SortOption = .highestToLowest
    @State private var showingClearAllAlert = false
    
    // Google Places integration
    @State private var googleResults: [CourseSearchResult] = []
    @State private var isSearchingGoogle = false
    @State private var searchTimer: Timer?
    @FocusState private var isSearchFieldFocused: Bool
    @State private var isSearchFieldDisabled = false

    private let googlePlacesService = GooglePlacesService(apiKey: ConfigManager.shared.googlePlacesAPIKey)
    
    // Filtered and sorted courses based on search text and sort option
    var filteredCourses: [Course] {
        let filtered: [Course]
        if searchText.isEmpty {
            filtered = courses
        } else {
            filtered = courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                course.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return sortCourses(filtered)
    }
    
    private func sortCourses(_ courses: [Course]) -> [Course] {
        switch sortOption {
        case .highestToLowest:
            return courses.sorted { course1, course2 in
                let score1 = course1.latestScore ?? -1
                let score2 = course2.latestScore ?? -1
                return score1 > score2
            }
        case .lowestToHighest:
            return courses.sorted { course1, course2 in
                let score1 = course1.latestScore ?? 11 // Put unreviewed courses at the end
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
                // Header Section
                VStack(spacing: 16) {
                    // App Title and Sort Menu
                    HStack {
                        Image(systemName: "flag.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Clubi")
                            .font(.title)
                            .fontWeight(.bold)
                            .onLongPressGesture {
                                addTestData()
                            }
                            .onTapGesture(count: 2) {
                                // Double-tap to clear all data (with confirmation)
                                if !courses.isEmpty {
                                    showingClearAllAlert = true
                                }
                            }
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Account Menu
                            Menu {
                                if let userEmail = authManager.user?.email {
                                    Text(userEmail)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    signOut()
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Sign Out")
                                    }
                                }
                            } label: {
                                VStack(alignment: .center, spacing: 2) {
                                    Image(systemName: "person.circle")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                    Text("Account")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Sort Menu
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
                                VStack(alignment: .center, spacing: 2) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                    Text("Sort")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search golf courses...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFieldFocused)
                            .disabled(isSearchFieldDisabled)
                            .onChange(of: searchText) { oldValue, newValue in
                                // Cancel previous timer
                                searchTimer?.invalidate()
                                
                                // Start new timer for debounced search
                                searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    searchGooglePlaces()
                                }
                            }
                        
                        // Clear button
                        if !searchText.isEmpty {
                            Button(action: {
                                clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content Section
                if courses.isEmpty && searchText.isEmpty {
                    // Empty state - no courses yet AND no search
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No courses yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Search for golf courses above to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                    
                } else {
                    // Course Results with Local and Google sections
                    VStack(spacing: 0) {
            List {
                            // Your Courses Section  
                            if !filteredCourses.isEmpty {
                                Section("Your Courses") {
                                    ForEach(filteredCourses, id: \.id) { course in
                                        CourseRowView(course: course)
                                            .id(course.id)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                if course.reviews.isEmpty {
                                                    // No review yet, go to review flow
                                                    selectedCourse = course
                                                } else {
                                                    // Has review, show detailed review
                                                    selectedCourseForDetail = course
                                                }
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button("Delete") {
                                                    courseToDelete = course
                                                    showingDeleteAlert = true
                                                }
                                                .tint(.red)
                                            }
                                    }
                                }
                                .id("your-courses-section")
                            }
                            
                            // Find Courses Section (Google Places)
                            if !searchText.isEmpty {
                                Section("Find Courses") {
                                    if isSearchingGoogle {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Searching...")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 8)
                                    } else if googleResults.isEmpty && searchText.count >= 2 {
                                        VStack(spacing: 12) {
                                            Text("No matches found")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            if filteredCourses.isEmpty {
                                                Button("Add \"\(searchText)\" manually") {
                                                    showingAddCourse = true
                                                }
                                                .font(.subheadline)
                                                .buttonStyle(.borderedProminent)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    } else {
                                        ForEach(googleResults, id: \.placeId) { result in
                                            GoogleCourseRowView(result: result) {
                                                addGoogleCourseToLocal(result)
                                            }
                                        }
                                        
                                        // Course not listed option
                                        if !googleResults.isEmpty {
                                            VStack(spacing: 8) {
                                                Divider()
                                                    .padding(.vertical, 8)
                                                
                                                Button(action: {
                                                    showingAddCourse = true
                                                }) {
                                                    HStack {
                                                        Image(systemName: "plus.circle")
                                                            .font(.subheadline)
                                                        Text("Course not listed? Add manually")
                                                            .font(.subheadline)
                                                        Spacer()
                                                    }
                                                    .foregroundColor(.secondary)
                                                    .padding(.vertical, 8)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        
                        // Sort indicator (only show if we have local courses)
                        if !filteredCourses.isEmpty {
                            HStack {
                                Text("Sorted by: \(sortOption.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView(searchText: searchText) { newCourse in
                    // When course is added, dismiss the sheet and start review
                    showingAddCourse = false
                    selectedCourse = newCourse
                    // Clear search since we'll show the review flow
                    searchTimer?.invalidate()
                    searchText = ""
                    googleResults = []
                }
            }
            .fullScreenCover(item: $selectedCourse) { course in
                ReviewFlowView(course: course) {
                    // Completion handler to dismiss the entire review flow
                    selectedCourse = nil
                    // Clear search to show updated course list
                    searchTimer?.invalidate()
                    searchText = ""
                    googleResults = []
                    
                    // Force unfocus by temporarily disabling the TextField
                    isSearchFieldDisabled = true
                    isSearchFieldFocused = false
                    
                    // Re-enable after a brief moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFieldDisabled = false
                    }
                }
            }
            .sheet(item: $selectedCourseForDetail) { course in
                if let latestReview = course.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first {
                    DetailedReviewView(
                        course: course,
                        answers: latestReview.answers,
                        calculatedScore: latestReview.calculatedScore
                    ) {
                        // On "Review Again" tapped
                        selectedCourseForDetail = nil
                        selectedCourse = course
                    }
                }
            }
            .alert("Delete Course", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    courseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
            } message: {
                if let course = courseToDelete {
                                         Text("Are you sure you want to delete \"\(course.name)\"? This will also delete all reviews for this course.")
                 }
             }
                         .alert("Clear All Data", isPresented: $showingClearAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all courses and reviews. This action cannot be undone.")
            }

        }
    }
    
    // MARK: - Google Places Search
    private func searchGooglePlaces() {
        // Don't search if query is too short or empty
        guard searchText.count >= 2 else {
            googleResults = []
            return
        }
        
        print("🔍 Starting Google Places search for: '\(searchText)'")
        isSearchingGoogle = true
        
        Task {
            do {
                let results = try await googlePlacesService.searchGolfCourses(query: searchText)
                
                await MainActor.run {
                    print("✅ Google Places returned \(results.count) results")
                    for (index, result) in results.prefix(3).enumerated() {
                        print("  \(index + 1). \(result.name) - \(result.address)")
                    }
                    
                    // Mark results as "local" if they already exist in our database
                    self.googleResults = results.map { result in
                        var updatedResult = result
                        updatedResult.isLocal = courses.contains { course in
                            course.name.localizedCaseInsensitiveContains(result.name) ||
                            result.name.localizedCaseInsensitiveContains(course.name)
                        }
                        return updatedResult
                    }
                    self.isSearchingGoogle = false
                }
            } catch {
                await MainActor.run {
                    print("Google Places search error: \(error)")
                    self.googleResults = []
                    self.isSearchingGoogle = false
                }
            }
        }
    }
    
    // MARK: - Actions
    private func signOut() {
        do {
            try authManager.signOut()
            // Clear any local state when signing out
            clearSearch()
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
    
    private func confirmDelete() {
        guard let course = courseToDelete else { return }
        
        // Delete the course directly - SwiftUI will handle animations
        modelContext.delete(course)
        try? modelContext.save()
        
        // Clear the reference
        courseToDelete = nil
    }
    
    private func addGoogleCourseToLocal(_ googleResult: CourseSearchResult) {
        // Create a new course from the Google result with cleaned address
        let cleanedLocation = cleanGoogleAddress(googleResult.address)
        let newCourse = Course(name: googleResult.name, location: cleanedLocation)
        modelContext.insert(newCourse)
        
        // Save and immediately start review
        try? modelContext.save()
        selectedCourse = newCourse
    }
    
    // MARK: - Test Data
    private func addTestData() {
        // Don't add test data if we already have courses
        guard courses.isEmpty else { return }
        
        let testCourses = [
            ("Augusta National Golf Club", "Augusta, GA", [0, 0, 0, 0]), // 40/40 = 10.0
            ("Pebble Beach Golf Links", "Pebble Beach, CA", [0, 0, 1, 0]), // 35/40 = 8.75
            ("St Andrews Old Course", "St Andrews, Scotland", [0, 1, 2, 0]), // 32/40 = 8.0
            // TRIPLE PLAYOFF TARGET: Strategic score ladder for chain playoffs
            ("Oakmont Country Club", "Oakmont, PA", [0, 2, 2, 1]), // Will be set to 6.0 - ties with new course
            ("Winged Foot Golf Club", "Mamaroneck, NY", [0, 2, 2, 1]), // Will be set to 6.1 - ties after first playoff  
            ("Merion Golf Club", "Ardmore, PA", [0, 2, 2, 1]), // Will be set to 6.2 - ties after second playoff
            ("Whistling Straits", "Kohler, WI", [0, 2, 3, 1]), // 10+4+2.5+5 = 21.5/40 = 5.4
            ("Bethpage Black", "Farmingdale, NY", [0, 2, 4, 1]), // 10+4+0+5 = 19/40 = 4.75
            ("Municipal Golf Course", "Anytown, USA", [1, 3, 4, 2]) // 0+0+0+0 = 0/40 = 0.0
        ]
        
        for (name, location, answerIndices) in testCourses {
            // Create the course
            let course = Course(name: name, location: location)
            modelContext.insert(course)
            
            // Create review answers
            let reviewAnswers = answerIndices.enumerated().map { index, answerIndex in
                ReviewAnswer(questionId: index, selectedAnswerIndex: answerIndex)
            }
            
            // Create and insert the review
            let review = Review(courseId: course.id, answers: reviewAnswers)
            review.course = course
            
            // Manually set strategic scores for playoff courses
            if name == "Oakmont Country Club" {
                review.calculatedScore = 6.0  // Will tie with new course (6.0)
            } else if name == "Winged Foot Golf Club" {
                review.calculatedScore = 6.1  // Will tie after first playoff winner (6.1)
            } else if name == "Merion Golf Club" {
                review.calculatedScore = 6.2  // Will tie after second playoff winner (6.2)
            }
            // All other courses keep their naturally calculated scores
            
            modelContext.insert(review)
        }
        
        // Save all changes
        try? modelContext.save()
        
        print("🏌️ Added test courses with TRIPLE PLAYOFF setup!")
        print("📋 TO TRIGGER TRIPLE PLAYOFF:")
        print("   1. Long-press 'Clubi' title to add test data")
        print("      • Oakmont Country Club: 6.0")  
        print("      • Winged Foot Golf Club: 6.1")
        print("      • Merion Golf Club: 6.2")
        print("   2. Add/review a new course with answers: [Yes, OK, Well Maintained, Maybe] = 6.0 score")
        print("   3. PLAYOFF 1: New course (6.0) ties with Oakmont Country Club (6.0)")
        print("      → Winner becomes 6.1, loser becomes 5.9")  
        print("   4. PLAYOFF 2: Winner (6.1) ties with Winged Foot Golf Club (6.1)")
        print("      → Winner becomes 6.2, loser becomes 6.0")
        print("   5. TRIPLE PLAYOFF! 💥: Winner (6.2) ties with Merion Golf Club (6.2)")
        print("      → You'll see the red 'TRIPLE PLAYOFF!' screen with rigid haptics!")
        print("🎯 Answer pattern: Q1=Yes, Q2=OK, Q3=Well Maintained, Q4=Maybe")
        print("💡 The system will automatically chain all three playoffs together!")
    }
    
    private func clearSearch() {
        searchTimer?.invalidate()
        searchText = ""
        googleResults = []
        // Force unfocus by temporarily disabling
        isSearchFieldDisabled = true
        isSearchFieldFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isSearchFieldDisabled = false
        }
    }
    
    private func clearAllData() {
        // Delete all courses (reviews will be deleted automatically due to cascade delete)
        for course in courses {
            modelContext.delete(course)
        }
        
        // Save changes
        try? modelContext.save()
        
        // Clear any UI state
        clearSearch()
        
        print("🗑️ Cleared all courses and reviews")
    }
    
    private func cleanGoogleAddress(_ fullAddress: String) -> String {
        // Google addresses are typically: "Street Address, City, State Zip, Country"
        // We want: "City, State, Country"
        
        let components = fullAddress.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count >= 2 else {
            return fullAddress // Return original if we can't parse it
        }
        
        if components.count >= 4 {
            // Format: "Street, City, State Zip, Country" -> "City, State, Country"
            let city = components[components.count - 3]
            let stateZip = components[components.count - 2]
            let country = components[components.count - 1]
            
            // Remove ZIP code from state (e.g., "CA 93953" -> "CA")
            let state = String(stateZip.split(separator: " ").first ?? Substring(stateZip))
            
            return "\(city), \(state), \(country)"
        } else if components.count == 3 {
            // Format: "City, State, Country" (already clean)
            return fullAddress
        } else {
            // Format: "City, Country" or other format
            let city = components[components.count - 2]
            let country = components[components.count - 1]
            return "\(city), \(country)"
        }
    }
}

// MARK: - Google Course Row View
struct GoogleCourseRowView: View {
    let result: CourseSearchResult
    let onAddCourse: () -> Void
    
    private var cleanedAddress: String {
        cleanGoogleAddressStatic(result.address)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(cleanedAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let rating = result.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(rating, specifier: "%.1f") on Google")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Add button or "Added" indicator
                if result.isLocal {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        Text("Added")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                } else {
                    Button("Add") {
                        onAddCourse()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Course Row View
struct CourseRowView: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(course.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Show score if course has been reviewed
                if let score = course.latestScore {
                    VStack(spacing: 2) {
                        Text("\(score, specifier: "%.1f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("/ 10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Not Reviewed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
            
            // Show review date if available
            if let latestReview = course.reviews.sorted(by: { $0.dateReviewed > $1.dateReviewed }).first {
                Text("Reviewed \(latestReview.dateReviewed, format: .dateTime.month().day().year())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Course View
struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let searchText: String
    let onCourseAdded: (Course) -> Void
    @State private var courseName: String = ""
    @State private var courseLocation: String = ""
    
    private var canAddCourse: Bool {
        !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !courseLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Course Details")) {
                    TextField("Course Name", text: $courseName)
                    
                    TextField("City, State/Country", text: $courseLocation)
                        .textContentType(.addressCity)
                }
                
                // Show a live preview of how the location will be formatted
                if !courseLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Will be saved as: \(smartFormatLocation(courseLocation))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCourse()
                    }
                    .disabled(!canAddCourse)
                }
            }
            .onAppear {
                // Pre-fill with search text if available
                if !searchText.isEmpty {
                    courseName = searchText
                }
            }

        }
    }
    
    private func addCourse() {
        let cleanedLocation = smartFormatLocation(courseLocation)
        let newCourse = Course(name: courseName.trimmingCharacters(in: .whitespacesAndNewlines), 
                              location: cleanedLocation)
        modelContext.insert(newCourse)
        
        try? modelContext.save()
        onCourseAdded(newCourse)
    }
    
    private func smartFormatLocation(_ input: String) -> String {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If already well-formatted with commas, just clean up spacing
        if cleaned.contains(",") {
            let components = cleaned.split(separator: ",").map { 
                $0.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
            }
            return components.joined(separator: ", ")
        }
        
        // Smart parsing for common patterns
        let words = cleaned.split(separator: " ").map { String($0).capitalized }
        
        // Handle common US state abbreviations and full names
        let stateMap: [String: String] = [
            "Ca": "CA", "California": "CA",
            "Tx": "TX", "Texas": "TX", 
            "Fl": "FL", "Florida": "FL",
            "Ny": "NY", "New York": "NY",
            "Ga": "GA", "Georgia": "GA",
            "Nc": "NC", "North Carolina": "NC",
            "Sc": "SC", "South Carolina": "SC",
            "Az": "AZ", "Arizona": "AZ",
            "Nv": "NV", "Nevada": "NV",
            "Co": "CO", "Colorado": "CO",
            "Or": "OR", "Oregon": "OR",
            "Wa": "WA", "Washington": "WA",
            "Mi": "MI", "Michigan": "MI",
            "Oh": "OH", "Ohio": "OH",
            "Pa": "PA", "Pennsylvania": "PA",
            "Va": "VA", "Virginia": "VA",
            "Md": "MD", "Maryland": "MD",
            "Ma": "MA", "Massachusetts": "MA",
            "Ct": "CT", "Connecticut": "CT",
            "Nj": "NJ", "New Jersey": "NJ"
        ]
        
        // Handle common countries
        let countryMap: [String: String] = [
            "Scotland": "Scotland",
            "England": "England", 
            "Ireland": "Ireland",
            "Wales": "Wales",
            "Canada": "Canada",
            "Australia": "Australia",
            "France": "France",
            "Spain": "Spain",
            "Italy": "Italy",
            "Germany": "Germany",
            "Japan": "Japan",
            "Uk": "UK", "United Kingdom": "UK"
        ]
        
        if words.count >= 2 {
            let potentialState = words.last!
            let potentialCountry = words.last!
            
            // Check if last word is a US state
            if let stateAbbrev = stateMap[potentialState] {
                let city = words.dropLast().joined(separator: " ")
                return "\(city), \(stateAbbrev)"
            }
            
            // Check if last word is a country
            if let country = countryMap[potentialCountry] {
                let city = words.dropLast().joined(separator: " ")
                return "\(city), \(country)"
            }
            
            // Default: assume last word is state/country, rest is city
            let city = words.dropLast().joined(separator: " ")
            let region = words.last!
            return "\(city), \(region)"
        }
        
        // Single word - just return capitalized
        return words.joined(separator: " ")
    }
}

// MARK: - Static Address Cleaning Function
private func cleanGoogleAddressStatic(_ fullAddress: String) -> String {
    // Google addresses are typically: "Street Address, City, State Zip, Country"
    // We want: "City, State, Country"
    
    let components = fullAddress.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    
    guard components.count >= 2 else {
        return fullAddress // Return original if we can't parse it
    }
    
    if components.count >= 4 {
        // Format: "Street, City, State Zip, Country" -> "City, State, Country"
        let city = components[components.count - 3]
        let stateZip = components[components.count - 2]
        let country = components[components.count - 1]
        
        // Remove ZIP code from state (e.g., "CA 93953" -> "CA")
        let state = String(stateZip.split(separator: " ").first ?? Substring(stateZip))
        
        return "\(city), \(state), \(country)"
    } else if components.count == 3 {
        // Format: "City, State, Country" (already clean)
        return fullAddress
    } else {
        // Format: "City, Country" or other format
        let city = components[components.count - 2]
        let country = components[components.count - 1]
        return "\(city), \(country)"
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .modelContainer(for: Course.self, inMemory: true)
}

