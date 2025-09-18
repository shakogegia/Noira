//
//  UserDefaultsService.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import Combine
import Foundation

class UserDefaultsService: ObservableObject {
    private let serverURLKey = "abs_server_url"
    private let usernameKey = "abs_username"
    private let tokenKey = "abs_auth_token"
    private let libraryIdKey = "library_id"

    static let shared = UserDefaultsService()

    private init() {
        // Initialize published properties from UserDefaults
        self.serverURL = UserDefaults.standard.string(forKey: serverURLKey)
        self.username = UserDefaults.standard.string(forKey: usernameKey)
        self.authToken = UserDefaults.standard.string(forKey: tokenKey)
        self.libraryId = UserDefaults.standard.string(forKey: libraryIdKey)
    }

    @Published var serverURL: String? {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: serverURLKey)
        }
    }

    @Published var username: String? {
        didSet {
            UserDefaults.standard.set(username, forKey: usernameKey)
        }
    }

    @Published var authToken: String? {
        didSet {
            UserDefaults.standard.set(authToken, forKey: tokenKey)
        }
    }

    @Published var libraryId: String? {
        didSet {
            UserDefaults.standard.set(libraryId, forKey: libraryIdKey) // Fixed: was using serverURLKey
        }
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: serverURLKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: libraryIdKey)
    }
}
