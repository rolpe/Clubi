//
//  MemberSearchView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/10/25.
//

import SwiftUI

struct MemberSearchView: View {
    @StateObject private var profileManager = MemberProfileManager()
    @State private var searchText = ""
    @State private var searchResults: [MemberProfile] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage = ""
    @State private var selectedMember: MemberProfile?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                ZStack {
                    if isSearching {
                        loadingView
                    } else if !hasSearched {
                        emptyStateView
                    } else if searchResults.isEmpty && hasSearched {
                        noResultsView
                    } else {
                        searchResultsList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.morningMist)
            .navigationTitle("Find Members")
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
        }
        .sheet(item: $selectedMember) { member in
            MemberDetailView(member: member)
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        VStack(spacing: ClubiSpacing.sm) {
            HStack(spacing: ClubiSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.grayFairway)
                
                TextField("Search by username or name", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                        searchResults = []
                        hasSearched = false
                        errorMessage = ""
                    }
                    .font(ClubiTypography.body(14))
                    .foregroundColor(.augustaPine)
                }
            }
            .padding(ClubiSpacing.md)
            .background(Color.pristineWhite)
            .cornerRadius(ClubiRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ClubiRadius.md)
                    .stroke(Color.subtleLines, lineWidth: 1)
            )
            .cardShadow()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(ClubiTypography.caption())
                    .foregroundColor(.errorRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, ClubiSpacing.lg)
        .padding(.vertical, ClubiSpacing.md)
        .background(Color.morningMist)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ClubiSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                .scaleEffect(1.2)
            
            Text("Searching members...")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.augustaPine.opacity(0.3))
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("Discover Members")
                    .font(ClubiTypography.display(24, weight: .bold))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text("Search for other Members by username or display name")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, ClubiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: ClubiSpacing.lg) {
            Image(systemName: "person.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.lightGray)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("No Members Found")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text("Try searching with different keywords")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, ClubiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: ClubiSpacing.md) {
                ForEach(searchResults, id: \.id) { member in
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
    
    private func performSearch(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear previous results and errors
        errorMessage = ""
        
        // Don't search if query is too short
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            hasSearched = false
            return
        }
        
        isSearching = true
        hasSearched = true
        
        Task {
            do {
                let results = try await profileManager.searchMembers(query: trimmedQuery)
                
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search members. Please try again."
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}

#Preview {
    MemberSearchView()
}
