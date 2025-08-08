//
//  GooglePlacesService.swift
//  Clubi
//
//  Created by Ron Lipkin on 7/27/25.
//

import Foundation

// MARK: - Google Places API Models
struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
}

struct GooglePlace: Codable {
    let placeId: String
    let name: String
    let formattedAddress: String?
    let geometry: PlaceGeometry
    let rating: Double?
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case rating
        case types
    }
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double
    let lng: Double
}

// MARK: - Our App's Search Result Model
struct CourseSearchResult {
    let placeId: String
    let name: String
    let address: String
    let rating: Double?
    var isLocal: Bool // true if already in user's database
    
    init(from googlePlace: GooglePlace, isLocal: Bool = false) {
        self.placeId = googlePlace.placeId
        self.name = googlePlace.name
        self.address = googlePlace.formattedAddress ?? "Address not available"
        self.rating = googlePlace.rating
        self.isLocal = isLocal
    }
}

// MARK: - Google Places Service
class GooglePlacesService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    /// Search for golf courses using text query
    func searchGolfCourses(query: String) async throws -> [CourseSearchResult] {
        let results = try await performTextSearch(query: "\(query) golf course")
        
        // Filter to only include results that are likely golf courses
        let golfCourses = results.filter { place in
            place.types.contains("establishment") && 
            (place.name.localizedCaseInsensitiveContains("golf") ||
             place.name.localizedCaseInsensitiveContains("country club") ||
             place.types.contains("golf_course"))
        }
        
        return golfCourses.map { CourseSearchResult(from: $0) }
    }
    
    /// Search for golf courses near a location
    func searchGolfCoursesNearby(latitude: Double, longitude: Double, radius: Int = 50000) async throws -> [CourseSearchResult] {
        let results = try await performNearbySearch(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: "golf_course"
        )
        
        return results.map { CourseSearchResult(from: $0) }
    }
    
    // MARK: - Private API Methods
    
    private func performTextSearch(query: String) async throws -> [GooglePlace] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/textsearch/json?query=\(encodedQuery)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        // Create URL request with bundle identifier headers for API restrictions
        var request = URLRequest(url: url)
        request.setValue("Ron.Clubi", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.setValue("Ron.Clubi", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            
            guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                throw GooglePlacesError.apiError(response.status)
            }
            
            return response.results
        } catch {
            throw GooglePlacesError.decodingError(error)
        }
    }
    
    private func performNearbySearch(latitude: Double, longitude: Double, radius: Int, type: String) async throws -> [GooglePlace] {
        let urlString = "\(baseURL)/nearbysearch/json?location=\(latitude),\(longitude)&radius=\(radius)&type=\(type)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        // Create URL request with bundle identifier headers for API restrictions
        var request = URLRequest(url: url)
        request.setValue("Ron.Clubi", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.setValue("Ron.Clubi", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            
            guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                throw GooglePlacesError.apiError(response.status)
            }
            
            return response.results
        } catch {
            throw GooglePlacesError.decodingError(error)
        }
    }
}

// MARK: - Error Handling
enum GooglePlacesError: LocalizedError {
    case invalidURL
    case apiError(String)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Google Places API"
        case .apiError(let status):
            return "Google Places API error: \(status)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
} 