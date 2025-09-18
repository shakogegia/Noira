//
//  ABSLibrary.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import Foundation

// MARK: - API Response Models
struct ABSLibraryItemsResponse: Codable {
    let results: [ABSLibraryItem]
    let total: Int
    let limit: Int
    let page: Int
    let mediaType: String
}

struct ABSLibraryItem: Codable {
    let id: String
    let libraryId: String
    let mediaType: String
    let media: Media
    let addedAt: Int64
    let updatedAt: Int64
    
    struct Media: Codable {
        let id: String
        let metadata: Metadata
        let coverPath: String?
        let duration: Double?
        
        struct Metadata: Codable {
            let title: String
            let titleIgnorePrefix: String?
            let subtitle: String?
            let authorName: String?
            let narratorName: String?
            let seriesName: String?
            let genres: [String]?
            let publishedYear: String?
            let publishedDate: String?
            let publisher: String?
            let description: String?
            let language: String?
        }
    }
}

enum ABSLibraryError: LocalizedError {
    case noLibraryId
    case noServerURL
    case noAuthToken
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noLibraryId:
            return "No library ID found. Please check your settings."
        case .noServerURL:
            return "No server URL found. Please login again."
        case .noAuthToken:
            return "No authentication token found. Please login again."
        case .invalidURL:
            return "Invalid server URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error parsing server response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
