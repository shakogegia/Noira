//
//  UserDefaultsService.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import Foundation

class UserDefaultsService {
    private let serverURLKey = "abs_server_url"
    private let usernameKey = "abs_username"
    private let tokenKey = "abs_auth_token"
    private let selectedLibraryKey = "selected_library_id"
    
    static let shared = UserDefaultsService()
    
    private init() {}
    
    var serverURL: String? {
        get { UserDefaults.standard.string(forKey: serverURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: serverURLKey) }
    }
    
    var username: String? {
        get { UserDefaults.standard.string(forKey: usernameKey) }
        set { UserDefaults.standard.set(newValue, forKey: usernameKey) }
    }
    
    var authToken: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }
    
    var selectedLibraryId: String? {
        get { UserDefaults.standard.string(forKey: selectedLibraryKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedLibraryKey) }
    }
    
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: serverURLKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: selectedLibraryKey)
    }
}
