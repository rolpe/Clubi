//
//  MemberRowView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/10/25.
//

import SwiftUI

struct MemberRowView: View {
    let member: MemberProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ClubiSpacing.md) {
                // Profile Avatar
                Circle()
                    .fill(Color.augustaPine.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.augustaPine)
                    )
                
                // Member Info
                VStack(alignment: .leading, spacing: ClubiSpacing.xs) {
                    Text(member.displayName)
                        .font(ClubiTypography.headline(16, weight: .semibold))
                        .foregroundColor(.charcoal)
                        .lineLimit(1)
                    
                    Text("@\(member.username)")
                        .font(ClubiTypography.body(14))
                        .foregroundColor(.grayFairway)
                        .lineLimit(1)
                    
                    if !member.bio.isEmpty {
                        Text(member.bio)
                            .font(ClubiTypography.caption())
                            .foregroundColor(.lightGray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lightGray)
            }
            .padding(ClubiSpacing.md)
            .background(Color.pristineWhite)
            .cornerRadius(ClubiRadius.md)
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: ClubiSpacing.md) {
        MemberRowView(
            member: MemberProfile(
                id: "1",
                email: "john@example.com",
                username: "johndoe",
                displayName: "John Doe",
                bio: "Love playing golf on weekends and trying new courses!"
            ),
            onTap: {}
        )
        
        MemberRowView(
            member: MemberProfile(
                id: "2",
                email: "jane@example.com",
                username: "janegolfer",
                displayName: "Jane Smith",
                bio: ""
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Color.morningMist)
}