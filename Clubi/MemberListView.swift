//
//  MemberListView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/10/25.
//

import SwiftUI

struct MemberListView: View {
    let title: String
    let members: [MemberProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMember: MemberProfile?
    
    var body: some View {
        NavigationView {
            VStack {
                if members.isEmpty {
                    emptyStateView
                } else {
                    membersList
                }
            }
            .background(Color.morningMist)
            .navigationTitle(title)
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
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: ClubiSpacing.xl) {
            Image(systemName: "person.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.lightGray)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text("No \(title)")
                    .font(ClubiTypography.headline(20, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text("When this member has \(title.lowercased()), they'll appear here")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, ClubiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Members List
    
    private var membersList: some View {
        ScrollView {
            LazyVStack(spacing: ClubiSpacing.md) {
                ForEach(members, id: \.id) { member in
                    MemberRowView(member: member) {
                        selectedMember = member
                    }
                }
            }
            .padding(.horizontal, ClubiSpacing.lg)
            .padding(.top, ClubiSpacing.sm)
        }
    }
}

#Preview {
    MemberListView(
        title: "Followers",
        members: [
            MemberProfile(
                id: "1",
                email: "john@example.com",
                username: "johndoe",
                displayName: "John Doe",
                bio: "Golf enthusiast"
            ),
            MemberProfile(
                id: "2",
                email: "jane@example.com",
                username: "janegolfer",
                displayName: "Jane Smith",
                bio: "Weekend golfer"
            )
        ]
    )
}