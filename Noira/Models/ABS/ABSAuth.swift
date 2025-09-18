//
//  ABSAuth.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import Foundation

// MARK: - Authentication Models
struct ABSLoginResponse: Codable {
    let user: ABSUser
    let userDefaultLibraryId: String
}

// MARK: - Login Request

struct ABSLoginRequest: Codable {
    let username: String
    let password: String
}

// MARK: - Error Response

struct ABSErrorResponse: Codable {
    let error: String?
    let message: String?
}
