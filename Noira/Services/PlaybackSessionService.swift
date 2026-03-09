//
//  PlaybackSessionService.swift
//  Noira
//
//  Created by Shalva Gegia on 09/03/2026.
//

import Foundation

enum PlaybackSessionError: LocalizedError {
    case noServerURL
    case noAuthToken
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .noServerURL:
            return "No server URL found. Please login again."
        case .noAuthToken:
            return "No authentication token found. Please login again."
        case .invalidURL:
            return "Invalid server URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error starting playback: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

@MainActor
class PlaybackSessionService: ObservableObject {
    private let userDefaults = UserDefaultsService.shared
    private let urlSession = URLSession.shared

    func startSession(itemId: String) async throws -> ABSPlaybackSession {
        let (serverURL, authToken) = try getCredentials()

        guard let url = URL(string: "\(serverURL)/api/items/\(itemId)/play") else {
            throw PlaybackSessionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let playRequest = ABSPlayRequest(
            deviceInfo: ABSDeviceInfo(
                clientName: "Noira",
                clientVersion: "1.0",
                deviceId: userDefaults.deviceId
            ),
            supportedMimeTypes: ["audio/mp4", "audio/mpeg", "audio/aac", "audio/x-m4a", "audio/x-m4b"]
        )

        request.httpBody = try JSONEncoder().encode(playRequest)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlaybackSessionError.networkError(
                NSError(domain: "PlaybackSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw PlaybackSessionError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(ABSPlaybackSession.self, from: data)
        } catch {
            throw PlaybackSessionError.decodingError(error)
        }
    }

    func syncProgress(sessionId: String, currentTime: Double, timeListened: Double, duration: Double) async {
        guard let (serverURL, authToken) = try? getCredentials() else { return }
        guard let url = URL(string: "\(serverURL)/api/session/\(sessionId)/sync") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let syncRequest = ABSSyncRequest(
            currentTime: currentTime,
            timeListened: timeListened,
            duration: duration
        )

        request.httpBody = try? JSONEncoder().encode(syncRequest)

        _ = try? await urlSession.data(for: request)
    }

    func closeSession(sessionId: String) async {
        guard let (serverURL, authToken) = try? getCredentials() else { return }
        guard let url = URL(string: "\(serverURL)/api/session/\(sessionId)/close") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        _ = try? await urlSession.data(for: request)
    }

    // MARK: - Private

    private func getCredentials() throws -> (serverURL: String, authToken: String) {
        guard let serverURL = userDefaults.serverURL, !serverURL.isEmpty else {
            throw PlaybackSessionError.noServerURL
        }
        guard let authToken = userDefaults.authToken, !authToken.isEmpty else {
            throw PlaybackSessionError.noAuthToken
        }
        return (serverURL.normalizedServerURL(), authToken)
    }
}
