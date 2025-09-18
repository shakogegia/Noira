//
//  ABSLibraryService.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import Foundation


@MainActor
class ABSLibraryService: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: ABSLibraryError?
    
    private let userDefaults = UserDefaultsService.shared
    private let urlSession = URLSession.shared
    
    func fetchLibraryItems() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Get required data from UserDefaults
        guard let libraryId = userDefaults.libraryId, !libraryId.isEmpty else {
            error = .noLibraryId
            return
        }
        
        guard let serverURL = userDefaults.serverURL, !serverURL.isEmpty else {
            error = .noServerURL
            return
        }
        
        guard let authToken = userDefaults.authToken, !authToken.isEmpty else {
            error = .noAuthToken
            return
        }
        
        // Construct the API URL
        guard let url = URL(string: "\(serverURL)/api/libraries/\(libraryId)/items") else {
            error = .invalidURL
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Make the API call
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                error = .networkError(NSError(domain: "LibraryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            // Check for HTTP errors
            switch httpResponse.statusCode {
            case 200...299:
                // Success - parse the response
                do {
                    let libraryResponse = try JSONDecoder().decode(ABSLibraryItemsResponse.self, from: data)
                    books = convertToBooks(from: libraryResponse.results, serverURL: serverURL)
                } catch {
                    self.error = .decodingError(error)
                }
                
            default:
                error = .serverError(httpResponse.statusCode)
            }
            
        } catch {
            self.error = .networkError(error)
        }
    }
    
    private func convertToBooks(from items: [ABSLibraryItem], serverURL: String) -> [Book] {
        return items.compactMap { item in
            // Only process book media types
            guard item.mediaType == "book" else { return nil }
            
            let metadata = item.media.metadata
            
            // Create authors array
            let authors: [Author]
            if let authorName = metadata.authorName, !authorName.isEmpty {
                // Split multiple authors by comma if needed
                let authorNames = authorName.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                authors = authorNames.enumerated().map { index, name in
                    Author(id: "\(item.id)_author_\(index)", name: name)
                }
            } else {
                authors = []
            }
            
            // Create narrators array
            let narrators: [String]
            if let narratorName = metadata.narratorName, !narratorName.isEmpty {
                narrators = narratorName.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            } else {
                narrators = []
            }
            
            // Build cover image URL
            let coverImageURL: String?
            if let coverPath = item.media.coverPath, !coverPath.isEmpty {
                coverImageURL = "\(serverURL)/audiobookshelf/api/items/\(item.id)/cover"
            } else {
                coverImageURL = nil
            }
            
            return Book(
                id: item.id,
                title: metadata.title,
                authors: authors,
                narrators: narrators,
                genres: metadata.genres ?? [],
                description: metadata.description ?? "",
                duration: item.media.duration ?? 0,
                coverImageURL: coverImageURL,
                progress: 0.0, // We'll need to fetch progress separately if needed
                lastPlayedDate: nil // We'll need to fetch this separately if needed
            )
        }
    }
}
