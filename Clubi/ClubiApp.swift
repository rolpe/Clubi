//
//  ClubiApp.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct ClubiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Course.self,
            Review.self,
        ])
        // Use a versioned URL to force a clean database for the new schema
        let storeURL = URL.documentsDirectory.appending(path: "Clubi_v2.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    AuthenticationView()
                }
            }
            .environmentObject(authManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
