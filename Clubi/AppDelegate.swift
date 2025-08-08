//
//  AppDelegate.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        return true
    }
}