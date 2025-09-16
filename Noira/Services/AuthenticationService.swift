//
//  AuthenticationService.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import Foundation
import SwiftUI

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: String?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaultsService.shared
    
    func checkAuthentication() {
        // Check if we have stored credentials
        if let token = userDefaults.authToken,
           let serverURL = userDefaults.serverURL,
           let username = userDefaults.username,
           !token.isEmpty && !serverURL.isEmpty {
            isAuthenticated = true
            currentUser = username
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func login(serverURL: String, username: String, password: String) async -> Bool {
        isLoading = true
        
        // TODO: Replace with actual ABS API call
        // For now, simulate login with delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Simulate success if fields are not empty
        let success = !serverURL.isEmpty && !username.isEmpty && !password.isEmpty
        
        if success {
            // Store credentials (in real app, store token from API response)
            userDefaults.serverURL = serverURL
            userDefaults.username = username
            userDefaults.authToken = "fake_token_\(Date().timeIntervalSince1970)"
            
            isAuthenticated = true
            currentUser = username
        }
        
        isLoading = false
        return success
    }
    
    func logout() {
        userDefaults.clearAll()
        isAuthenticated = false
        currentUser = nil
    }
}
