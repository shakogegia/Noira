//
//  AudioBookshelfModels.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import Foundation

// MARK: - Authentication Models

struct AudioBookshelfLoginResponse: Codable {
    let user: AudioBookshelfUser
    let userDefaultLibraryId: String
}

struct AudioBookshelfUser: Codable {
    let id: String
    let username: String
    let token: String
    let accessToken: String
}

// MARK: - Login Request

struct AudioBookshelfLoginRequest: Codable {
    let username: String
    let password: String
}

// MARK: - Error Response

struct AudioBookshelfErrorResponse: Codable {
    let error: String?
    let message: String?
}