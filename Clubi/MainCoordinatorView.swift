//
//  MainCoordinatorView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/10/25.
//

import SwiftUI
import FirebaseAuth

struct MainCoordinatorView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var profileManager = MemberProfileManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if let profile = profileManager.currentMemberProfile, profile.isProfileComplete {
                    // User has complete profile - show main app
                    MainTabView()
                        .environmentObject(authManager)
                } else {
                    // User needs to complete profile setup
                    ProfileSetupView(isEditing: false) {
                        // Profile setup completed - this will trigger a profile reload
                        // The view will automatically update when currentMemberProfile changes
                    }
                    .environmentObject(authManager)
                }
            } else {
                // User not authenticated - show login
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // ProfileManager automatically listens for auth state changes
            // and loads the profile when user is authenticated
        }
    }
}

#Preview {
    MainCoordinatorView()
        .environmentObject(AuthenticationManager())
}