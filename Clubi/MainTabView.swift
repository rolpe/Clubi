//
//  MainTabView.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/15/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // My Courses Tab
            ContentView()
                .tabItem {
                    Image(systemName: "flag.fill")
                    Text("My Courses")
                }
            
            // Feed Tab
            FeedView()
                .tabItem {
                    Image(systemName: "heart.text.square.fill")
                    Text("Feed")
                }
        }
        .accentColor(.augustaPine)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .modelContainer(for: Course.self, inMemory: true)
}