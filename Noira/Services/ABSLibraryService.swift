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

        // Normalize server URL
        let normalizedServerURL = serverURL.normalizedServerURL()

        // Construct the API URL
        guard let url = URL(string: "\(normalizedServerURL)/api/libraries/\(libraryId)/items") else {
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
                    books = ABSLibraryItemMapper.mapToBooks(from: libraryResponse.results, serverURL: normalizedServerURL)
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
}
