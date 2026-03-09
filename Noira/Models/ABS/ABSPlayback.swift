//
//  ABSPlayback.swift
//  Noira
//
//  Created by Shalva Gegia on 09/03/2026.
//

import Foundation

// MARK: - Play Request

struct ABSPlayRequest: Codable {
    let deviceInfo: ABSDeviceInfo
    let supportedMimeTypes: [String]
}

struct ABSDeviceInfo: Codable {
    let clientName: String
    let clientVersion: String
    let deviceId: String
}

// MARK: - Play Response (Playback Session)

struct ABSPlaybackSession: Codable {
    let id: String
    let libraryItemId: String
    let currentTime: Double
    let duration: Double
    let chapters: [ABSSessionChapter]
    let audioTracks: [ABSAudioTrack]
}

struct ABSAudioTrack: Codable {
    let index: Int
    let contentUrl: String
    let duration: Double
    let mimeType: String
    let startOffset: Double
}

struct ABSSessionChapter: Codable {
    let id: Int
    let start: Double
    let end: Double
    let title: String
}

// MARK: - Sync Request

struct ABSSyncRequest: Codable {
    let currentTime: Double
    let timeListened: Double
    let duration: Double
}
