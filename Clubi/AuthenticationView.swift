//
//  AuthenticationView.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 24) {
                    Spacer()
                    
                    // App Logo & Title
                    VStack(spacing: 16) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Clubi")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Rate and discover golf courses")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                
                // Form Section
                VStack(spacing: 20) {
                    // Smooth segmented toggle between Sign In / Sign Up
                    ZStack {
                        // Background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 50)
                        
                        // Sliding indicator
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(!isSignUp ? Color.white : Color.clear)
                                .shadow(color: !isSignUp ? .black.opacity(0.15) : Color.clear, radius: 6, x: 0, y: 2)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSignUp)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSignUp ? Color.white : Color.clear)
                                .shadow(color: isSignUp ? .black.opacity(0.15) : Color.clear, radius: 6, x: 0, y: 2)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSignUp)
                        }
                        .padding(2)
                        
                        // Buttons
                        HStack(spacing: 2) {
                            Button("Sign In") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isSignUp = false
                                    clearForm()
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(!isSignUp ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                            .scaleEffect(!isSignUp ? 1.0 : 0.95)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSignUp)
                            
                            Button("Sign Up") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isSignUp = true
                                    clearForm()
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSignUp ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                            .scaleEffect(isSignUp ? 1.0 : 0.95)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSignUp)
                        }
                        .padding(2)
                    }
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                    
                    // Action Button
                    Button(action: {
                        handleAuthentication()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canSubmit ? Color.green : Color(.systemGray4))
                        )
                        .contentShape(Rectangle())
                    }
                    .disabled(!canSubmit || isLoading)
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    // MARK: - Actions
    
    private func handleAuthentication() {
        guard canSubmit else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
                
                await MainActor.run {
                    // Success - AuthenticationManager will handle state change
                    clearForm()
                }
            } catch {
                await MainActor.run {
                    // Handle specific Firebase errors with user-friendly messages
                    errorMessage = getErrorMessage(from: error)
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        errorMessage = ""
    }
    
    private func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case 17007: // Email already in use
            return "An account with this email already exists. Try signing in instead."
        case 17008: // Invalid email
            return "Please enter a valid email address."
        case 17026: // Weak password
            return "Password should be at least 6 characters long."
        case 17009: // Wrong password
            return "Incorrect password. Please try again."
        case 17011: // User not found
            return "No account found with this email. Try signing up instead."
        case 17020: // Network error
            return "Network error. Please check your connection and try again."
        case 17999: // Internal error
            return "Something went wrong. Please try again."
        default:
            return "Authentication failed. Please try again."
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}