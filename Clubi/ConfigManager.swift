//
//  ConfigManager.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/6/25.
//

import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    
    private var config: [String: Any]?
    
    private init() {
        loadConfig()
    }
    
    private func loadConfig() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found or invalid format")
        }
        
        self.config = configData
    }
    
    var googlePlacesAPIKey: String {
        guard let apiKey = config?["GooglePlacesAPIKey"] as? String else {
            fatalError("GooglePlacesAPIKey not found in Config.plist")
        }
        return apiKey
    }
}