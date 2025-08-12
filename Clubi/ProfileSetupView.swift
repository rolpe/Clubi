//
//  ProfileSetupView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/9/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @StateObject private var profileManager = MemberProfileManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var displayName = ""
    @State private var bio = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var usernameCheckMessage = ""
    @State private var isCheckingUsername = false
    
    let isEditing: Bool
    let onComplete: () -> Void
    
    init(isEditing: Bool = false, onComplete: @escaping () -> Void) {
        self.isEditing = isEditing
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ClubiSpacing.xl) {
                    headerSection
                    formSection
                    actionButtons
                }
                .padding(ClubiSpacing.xl)
            }
            .background(Color.morningMist)
            .navigationBarHidden(!isEditing)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .font(ClubiTypography.body(weight: .medium))
                        .foregroundColor(.augustaPine)
                    }
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: ClubiSpacing.lg) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.augustaPine)
            
            VStack(spacing: ClubiSpacing.sm) {
                Text(isEditing ? "Edit Profile" : "Complete Your Profile")
                    .font(ClubiTypography.display(26, weight: .bold))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text(isEditing ? "Update your public profile information" : "Set up your profile to connect with other members")
                    .font(ClubiTypography.body())
                    .foregroundColor(.grayFairway)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: ClubiSpacing.lg) {
            // Username Field
            VStack(alignment: .leading, spacing: ClubiSpacing.sm) {
                HStack {
                    Text("Username")
                        .font(ClubiTypography.headline(16, weight: .semibold))
                        .foregroundColor(.charcoal)
                    
                    Text("*")
                        .foregroundColor(.errorRed)
                }
                
                HStack {
                    TextField("Enter your username", text: $username)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _, newValue in
                            checkUsernameAvailability(newValue)
                        }
                    
                    if isCheckingUsername {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .augustaPine))
                            .scaleEffect(0.8)
                    }
                }
                .padding(ClubiSpacing.md)
                .background(Color.pristineWhite)
                .cornerRadius(ClubiRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ClubiRadius.md)
                        .stroke(usernameCheckMessage.contains("available") ? Color.fairwayGreen : 
                               usernameCheckMessage.contains("taken") ? Color.errorRed : Color.subtleLines, 
                               lineWidth: 1)
                )
                .cardShadow()
                
                if !usernameCheckMessage.isEmpty {
                    Text(usernameCheckMessage)
                        .font(ClubiTypography.caption())
                        .foregroundColor(usernameCheckMessage.contains("available") ? .fairwayGreen : .errorRed)
                }
                
                Text("3-20 characters, letters, numbers, and underscores only")
                    .font(ClubiTypography.caption())
                    .foregroundColor(.lightGray)
            }
            
            // Display Name Field
            VStack(alignment: .leading, spacing: ClubiSpacing.sm) {
                HStack {
                    Text("Display Name")
                        .font(ClubiTypography.headline(16, weight: .semibold))
                        .foregroundColor(.charcoal)
                    
                    Text("*")
                        .foregroundColor(.errorRed)
                }
                
                TextField("Your display name", text: $displayName)
                    .textFieldStyle(.plain)
                    .padding(ClubiSpacing.md)
                    .background(Color.pristineWhite)
                    .cornerRadius(ClubiRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ClubiRadius.md)
                            .stroke(Color.subtleLines, lineWidth: 1)
                    )
                    .cardShadow()
                
                Text("This is how other members will see your name")
                    .font(ClubiTypography.caption())
                    .foregroundColor(.lightGray)
            }
            
            // Bio Field
            VStack(alignment: .leading, spacing: ClubiSpacing.sm) {
                Text("Bio")
                    .font(ClubiTypography.headline(16, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                TextField("Tell other members about yourself (optional)", text: $bio, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .padding(ClubiSpacing.md)
                    .background(Color.pristineWhite)
                    .cornerRadius(ClubiRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ClubiRadius.md)
                            .stroke(Color.subtleLines, lineWidth: 1)
                    )
                    .cardShadow()
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: ClubiSpacing.lg) {
            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(ClubiTypography.body(14))
                    .foregroundColor(.errorRed)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, ClubiSpacing.md)
            }
            
            // Save Button
            Button(action: {
                Task {
                    await saveProfile()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pristineWhite))
                            .scaleEffect(0.8)
                    }
                    Text(isEditing ? "Save Changes" : "Complete Profile")
                        .font(ClubiTypography.body(weight: .semibold))
                }
            }
            .disabled(!canSaveProfile || isLoading)
            .clubiPrimaryButton(isDisabled: !canSaveProfile || isLoading)
            
            // Skip Button (only for new profiles)
            if !isEditing {
                Button("Skip for now") {
                    onComplete()
                }
                .clubiTertiaryButton()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSaveProfile: Bool {
        !username.isEmpty && 
        !displayName.isEmpty && 
        !isCheckingUsername &&
        (usernameCheckMessage.contains("available") || usernameCheckMessage.isEmpty) &&
        username.count >= 3
    }
    
    // MARK: - Actions
    
    private func loadCurrentProfile() {
        if isEditing {
            Task {
                guard let user = Auth.auth().currentUser else { return }
                
                do {
                    if let profile = try await profileManager.getMemberProfile(userId: user.uid) {
                        await MainActor.run {
                            username = profile.username
                            displayName = profile.displayName
                            bio = profile.bio
                        }
                    }
                } catch {
                    print("❌ Error loading profile for editing: \(error)")
                }
            }
        }
    }
    
    private func checkUsernameAvailability(_ newUsername: String) {
        let cleanUsername = newUsername.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't check if it's the current user's existing username
        if isEditing, let currentProfile = profileManager.currentMemberProfile, 
           currentProfile.username.lowercased() == cleanUsername {
            usernameCheckMessage = ""
            return
        }
        
        // Check length first
        if cleanUsername.count < 3 {
            usernameCheckMessage = "Username must be at least 3 characters"
            return
        }
        
        if cleanUsername.count > 20 {
            usernameCheckMessage = "Username must be 20 characters or less"
            return
        }
        
        // Check character validity
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        guard predicate.evaluate(with: cleanUsername) else {
            usernameCheckMessage = "Username can only contain letters, numbers, and underscores"
            return
        }
        
        isCheckingUsername = true
        usernameCheckMessage = ""
        
        Task {
            do {
                let isAvailable = try await profileManager.checkUsernameAvailability(username: cleanUsername)
                await MainActor.run {
                    usernameCheckMessage = isAvailable ? "✓ Username available" : "✗ Username already taken"
                    isCheckingUsername = false
                }
            } catch {
                await MainActor.run {
                    usernameCheckMessage = "Error checking username"
                    isCheckingUsername = false
                }
            }
        }
    }
    
    private func saveProfile() async {
        guard let user = authManager.user else {
            errorMessage = "You must be logged in"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            if isEditing, var existingProfile = profileManager.currentMemberProfile {
                // Update existing profile
                existingProfile.username = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                existingProfile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                existingProfile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
                existingProfile.isProfileComplete = true
                
                try await profileManager.updateMemberProfile(existingProfile)
            } else {
                // Create new profile
                _ = try await profileManager.createMemberProfile(
                    email: user.email ?? "",
                    username: username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            
            onComplete()
            
            // Dismiss if editing mode
            if isEditing {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    ProfileSetupView(isEditing: false) {}
        .environmentObject(AuthenticationManager())
}