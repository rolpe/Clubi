//
//  AuthenticationManager.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import Foundation
import FirebaseAuth
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for authentication state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    deinit {
        // Clean up the listener when the manager is deallocated
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        print("✅ User created successfully: \(result.user.email ?? "Unknown")")
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        print("✅ User signed in successfully: \(result.user.email ?? "Unknown")")
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        print("✅ User signed out successfully")
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
        print("✅ Password reset email sent to: \(email)")
    }
}