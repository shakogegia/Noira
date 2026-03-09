//
//  ABSMediaProgress.swift
//  Noira
//
//  Created by Shalva Gegia on 09/03/2026.
//

import Foundation

struct ABSMeResponse: Codable {
    let id: String
    let username: String
    let mediaProgress: [ABSMediaProgress]
}

struct ABSMediaProgress: Codable {
    let id: String
    let libraryItemId: String
    let duration: Double
    let progress: Double
    let currentTime: Double
    let isFinished: Bool
    let lastUpdate: Int64
    let startedAt: Int64
    let finishedAt: Int64?
}
