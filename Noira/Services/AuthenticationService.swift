//
//  AuthenticationService.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import Foundation
import SwiftUI

enum AuthenticationError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidCredentials
    case invalidResponse
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL. Please check your server address."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidCredentials:
            return "Invalid username or password."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Error parsing server response."
        }
    }
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: String?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaultsService.shared
    private let urlSession = URLSession.shared
    
    func checkAuthentication() {
        print("check")
        print(userDefaults.authToken, userDefaults.serverURL, userDefaults.username)
        print("check end")
        // Check if we have stored credentials
        if let token = userDefaults.authToken,
           let serverURL = userDefaults.serverURL,
           let username = userDefaults.username,
           !token.isEmpty && !serverURL.isEmpty {
            isAuthenticated = true
            currentUser = username
            
            // Validate token in background
            Task {
                let isValid = await validateToken()
                await MainActor.run {
                    if !isValid {
                        logout()
                    }
                }
            }
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func login(serverURL: String, username: String, password: String) async -> Result<Void, AuthenticationError> {
        isLoading = true
        defer { isLoading = false }
        
        // Normalize server URL - remove trailing slash if present
        let normalizedServerURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // Construct login URL
        guard let loginURL = URL(string: "\(normalizedServerURL)/login") else {
            return .failure(.invalidURL)
        }
        
        // Create login request
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let loginRequest = ABSLoginRequest(username: username, password: password)
        
        do {
            let requestData = try JSONEncoder().encode(loginRequest)
            request.httpBody = requestData
            
            // Make the API call
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            // Check for HTTP errors
            switch httpResponse.statusCode {
            case 200...299:
                // Success - parse response
                do {
                    let loginResponse = try JSONDecoder().decode(ABSLoginResponse.self, from: data)
                    
                    // Store all the credentials
                    userDefaults.serverURL = normalizedServerURL
                    userDefaults.username = loginResponse.user.username
                    userDefaults.authToken = loginResponse.user.token
                    userDefaults.libraryId = loginResponse.userDefaultLibraryId
                    
                    isAuthenticated = true
                    currentUser = loginResponse.user.username
                    
                    return .success(())
                } catch {
                    return .failure(.decodingError(error))
                }
                
            case 401:
                return .failure(.invalidCredentials)
                
            default:
                // Try to parse error message from response
                if let errorResponse = try? JSONDecoder().decode(ABSErrorResponse.self, from: data),
                   let errorMessage = errorResponse.error ?? errorResponse.message {
                    return .failure(.networkError(NSError(domain: "AudioBookshelf", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                } else {
                    return .failure(.networkError(NSError(domain: "AudioBookshelf", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])))
                }
            }
            
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func logout() {
        userDefaults.clearAll()
        isAuthenticated = false
        currentUser = nil
    }
    
    /// Validates the current authentication token by making a test API call
    func validateToken() async -> Bool {
        guard let serverURL = userDefaults.serverURL,
              let token = userDefaults.authToken,
              !serverURL.isEmpty && !token.isEmpty else {
            return false
        }
        
        // Test the token by making a request to a simple endpoint
        guard let url = URL(string: "\(serverURL)/api/me") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // If we get 200-299, token is valid
            // If we get 401, token is invalid
            // For other errors, we'll assume token might still be valid
            switch httpResponse.statusCode {
            case 200...299:
                return true
            case 401:
                return false
            default:
                // For other errors (server down, etc.), assume token is still valid
                return true
            }
        } catch {
            // Network error - assume token is still valid
            return true
        }
    }
}
