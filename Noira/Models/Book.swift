//
//  Book.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import Foundation

struct Book: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let authors: [Author]
    let narrators: [String]
    let genres: [String]
    let description: String
    let duration: TimeInterval // in seconds
    let coverImageURL: String?
    let progress: Double // 0.0 to 1.0
    let lastPlayedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, authors, narrators, genres, description, duration, progress
        case coverImageURL = "coverPath"
        case lastPlayedDate = "lastPlayed"
    }
    
    // Computed property for formatted duration
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}

struct Author: Codable, Hashable {
    let id: String
    let name: String
}

struct Serie: Codable, Hashable {
    let id: String
    let name: String
    let sequence: String
}

struct Chapter: Codable, Identifiable, Hashable  {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    let title: String
}

struct Progress: Codable, Hashable {
    let id: String
    let duration: TimeInterval
    let progress: Double
    let currentTime: TimeInterval
}
