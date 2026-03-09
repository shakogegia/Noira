# Noira Audio Player & Bug Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete audiobook player for the Noira tvOS Audiobookshelf client, fix existing bugs, and clean up unused code.

**Architecture:** Custom AVPlayer wrapped in AudioPlayerService (shared @EnvironmentObject), with PlaybackSessionService handling ABS API session lifecycle (start/sync/close). NowPlayingView provides full playback UI designed for Siri Remote.

**Tech Stack:** Swift 5+, SwiftUI, AVFoundation (AVPlayer/AVURLAsset), tvOS, Audiobookshelf REST API

---

## Phase 1: Bug Fixes & Cleanup

### Task 1: Remove debug prints and fix SettingsView

**Files:**
- Modify: `Noira/Services/AuthenticationService.swift:45-47`
- Modify: `Noira/Views/Settings/SettingsView.swift:13,15,21-25,64-68`

**Step 1: Remove debug prints from AuthenticationService**

In `AuthenticationService.swift`, delete lines 45-47:
```swift
// DELETE these 3 lines:
print("check")
print(userDefaults.authToken, userDefaults.serverURL, userDefaults.username)
print("check end")
```

**Step 2: Fix SettingsView — remove @StateObject for singleton, remove broken theme picker**

In `SettingsView.swift`:

Replace the entire file content with:
```swift
//
//  SettingsView.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService

    private let userDefaults = UserDefaultsService.shared

    @State var showLogoutAlert: Bool = false

    var body: some View {
        Form {
            Section(header: Text("User")) {
                Button(action: {}) {
                    Text(userDefaults.username ?? "Username")
                }
                .disabled(true)

                Button(role: .destructive, action: {
                    showLogoutAlert = true
                }, label: {
                    Text("Sign out")
                })
            }
        }
        .padding(.leading, 400)
        .overlay(alignment: .leading) {
            HStack(spacing: 0) {
                BrandingView()
                    .frame(width: 350)

                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.gray)
                    .padding(.vertical, 40)
            }
        }
        .alert("Sign out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

#Preview {
    SettingsView()
}
```

Changes: removed `@StateObject` (use plain `let` for singleton), removed `Theme` enum and picker, removed `@State var theme`.

**Step 3: Delete unused files**

Delete:
- `Noira.xcodeproj/AudioBookshelfModels.swift` (duplicate unused models)
- `Noira/Views/Home/Components/StandardBookCard.swift` (unused component)
- `Noira/Views/Home/Components/` directory (if empty after deletion)
- `Noira/Views/Home/` directory (if empty after deletion)

**Step 4: Commit**
```bash
git add -u
git commit -m "fix: remove debug prints, fix SettingsView, delete unused files"
```

---

### Task 2: Add progress tracking from /api/me

**Files:**
- Create: `Noira/Models/ABS/ABSMediaProgress.swift`
- Modify: `Noira/Services/ABSLibraryService.swift`
- Modify: `Noira/Services/Mappers/ABSLibraryItemMapper.swift`

**Step 1: Create ABSMediaProgress model**

Create `Noira/Models/ABS/ABSMediaProgress.swift`:
```swift
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
```

**Step 2: Modify ABSLibraryService to fetch progress alongside library items**

In `ABSLibraryService.swift`, add a method to fetch user progress and pass it to the mapper.

Replace the entire file content with:
```swift
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
            // Fetch library items and user progress concurrently
            async let libraryData = urlSession.data(for: request)
            async let progressList = fetchUserProgress(serverURL: normalizedServerURL, authToken: authToken)

            let (data, response) = try await libraryData
            let mediaProgress = await progressList

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
                    books = ABSLibraryItemMapper.mapToBooks(
                        from: libraryResponse.results,
                        serverURL: normalizedServerURL,
                        mediaProgress: mediaProgress
                    )
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

    private func fetchUserProgress(serverURL: String, authToken: String) async -> [ABSMediaProgress] {
        guard let url = URL(string: "\(serverURL)/api/me") else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return []
            }
            let meResponse = try JSONDecoder().decode(ABSMeResponse.self, from: data)
            return meResponse.mediaProgress
        } catch {
            return []
        }
    }
}
```

**Step 3: Update ABSLibraryItemMapper to use progress data**

In `ABSLibraryItemMapper.swift`, update `mapToBooks` and `mapToBook` to accept and use `mediaProgress`:

Replace the entire file content with:
```swift
//
//  ABSLibraryItemMapper.swift
//  Noira
//
//  Created by Shalva Gegia on 23/12/2025.
//

import Foundation

struct ABSLibraryItemMapper {
    /// Maps API library items to app Book models
    static func mapToBooks(
        from items: [ABSLibraryItem],
        serverURL: String,
        mediaProgress: [ABSMediaProgress] = []
    ) -> [Book] {
        // Build a lookup dictionary for fast progress matching
        let progressByItemId = Dictionary(
            mediaProgress.map { ($0.libraryItemId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let books = items.compactMap { item -> Book? in
            mapToBook(from: item, serverURL: serverURL, progress: progressByItemId[item.id])
        }

        // Sort by addedAt descending (newest first)
        return books.sorted { ($0.addedAt ?? .distantPast) > ($1.addedAt ?? .distantPast) }
    }

    // MARK: - Private Mapping Methods

    private static func mapToBook(
        from item: ABSLibraryItem,
        serverURL: String,
        progress: ABSMediaProgress?
    ) -> Book? {
        // Only process book media types
        guard item.mediaType == "book" else { return nil }

        let metadata = item.media.metadata
        let authors = mapAuthors(from: metadata.authorName, itemId: item.id)
        let narrators = mapNarrators(from: metadata.narratorName)
        let coverURL = buildCoverURL(coverPath: item.media.coverPath, itemId: item.id, serverURL: serverURL)
        let series = mapSeries(from: metadata)
        let addedAt = mapDate(from: item.addedAt)

        let bookProgress = progress?.progress ?? 0.0
        let lastPlayed: Date? = progress.map { Date(timeIntervalSince1970: TimeInterval($0.lastUpdate) / 1000) }

        return Book(
            id: item.id,
            title: metadata.title,
            subtitle: metadata.subtitle,
            authors: authors,
            narrators: narrators,
            genres: metadata.genres ?? [],
            description: metadata.description ?? "",
            duration: item.media.duration ?? 0,
            coverImageURL: coverURL,
            progress: bookProgress,
            lastPlayedDate: lastPlayed,
            addedAt: addedAt,
            publisher: metadata.publisher,
            publishedYear: metadata.publishedYear,
            series: series
        )
    }

    private static func mapAuthors(from authorName: String?, itemId: String) -> [Author] {
        guard let authorName = authorName, !authorName.isEmpty else {
            return []
        }

        // Split multiple authors by comma
        let authorNames = authorName.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return authorNames.enumerated().map { index, name in
            Author(id: "\(itemId)_author_\(index)", name: name)
        }
    }

    private static func mapNarrators(from narratorName: String?) -> [String] {
        guard let narratorName = narratorName, !narratorName.isEmpty else {
            return []
        }

        return narratorName.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }

    private static func buildCoverURL(coverPath: String?, itemId: String, serverURL: String) -> String? {
        guard coverPath != nil, !coverPath!.isEmpty else { return nil }
        return "\(serverURL)/audiobookshelf/api/items/\(itemId)/cover"
    }

    private static func mapSeries(from metadata: ABSLibraryItem.Media.Metadata) -> Serie? {
        guard let seriesName = metadata.seriesName, !seriesName.isEmpty else {
            return nil
        }

        return Serie(
            id: seriesName.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: seriesName,
            sequence: ""
        )
    }

    private static func mapDate(from milliseconds: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
```

**Step 4: Commit**
```bash
git add Noira/Models/ABS/ABSMediaProgress.swift Noira/Services/ABSLibraryService.swift Noira/Services/Mappers/ABSLibraryItemMapper.swift
git commit -m "feat: fetch and display user progress from /api/me"
```

---

## Phase 2: Playback API Models & Services

### Task 3: Create ABS Playback API models

**Files:**
- Create: `Noira/Models/ABS/ABSPlayback.swift`

**Step 1: Create the playback API models**

Create `Noira/Models/ABS/ABSPlayback.swift`:
```swift
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
```

**Step 2: Add deviceId to UserDefaultsService**

In `Noira/Services/UserDefaultsService.swift`, add a `deviceId` property that persists a UUID:

Add after the `libraryIdKey` line (line 15):
```swift
private let deviceIdKey = "device_id"
```

Add after the `libraryId` @Published property block (after line 49):
```swift
var deviceId: String {
    if let existing = UserDefaults.standard.string(forKey: deviceIdKey) {
        return existing
    }
    let newId = UUID().uuidString
    UserDefaults.standard.set(newId, forKey: deviceIdKey)
    return newId
}
```

Add `UserDefaults.standard.removeObject(forKey: deviceIdKey)` is NOT needed in clearAll — deviceId should persist across logouts.

**Step 3: Commit**
```bash
git add Noira/Models/ABS/ABSPlayback.swift Noira/Services/UserDefaultsService.swift
git commit -m "feat: add playback API models and deviceId persistence"
```

---

### Task 4: Create PlaybackSessionService

**Files:**
- Create: `Noira/Services/PlaybackSessionService.swift`

**Step 1: Create the PlaybackSessionService**

Create `Noira/Services/PlaybackSessionService.swift`:
```swift
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
```

**Step 2: Commit**
```bash
git add Noira/Services/PlaybackSessionService.swift
git commit -m "feat: add PlaybackSessionService for ABS playback API"
```

---

## Phase 3: Audio Player Service

### Task 5: Create AudioPlayerService

**Files:**
- Create: `Noira/Services/AudioPlayerService.swift`

**Step 1: Create the AudioPlayerService**

Create `Noira/Services/AudioPlayerService.swift`:
```swift
//
//  AudioPlayerService.swift
//  Noira
//
//  Created by Shalva Gegia on 09/03/2026.
//

import AVFoundation
import Foundation
import Combine

@MainActor
class AudioPlayerService: ObservableObject {
    @Published var currentBook: Book?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var chapters: [Chapter] = []
    @Published var currentChapter: Chapter?
    @Published var isLoading = false
    @Published var error: String?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var sessionId: String?
    private var syncTimer: Timer?
    private var timeListened: Double = 0
    private var lastSyncTime: Date?

    private let sessionService = PlaybackSessionService()
    private let userDefaults = UserDefaultsService.shared

    static let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    func play(book: Book) async {
        // If same book is already loaded, just resume
        if currentBook?.id == book.id, player != nil {
            resume()
            return
        }

        // Stop current playback if any
        await stop()

        isLoading = true
        error = nil
        currentBook = book

        do {
            // Start ABS session
            let session = try await sessionService.startSession(itemId: book.id)
            sessionId = session.id

            // Map chapters
            chapters = session.chapters.map { ch in
                Chapter(id: ch.id, start: ch.start, end: ch.end, title: ch.title)
            }
            duration = session.duration

            // Get the first audio track
            guard let track = session.audioTracks.first else {
                error = "No audio tracks available"
                isLoading = false
                return
            }

            // Build streaming URL with auth header
            guard let serverURL = userDefaults.serverURL else {
                error = "No server URL configured"
                isLoading = false
                return
            }

            let normalizedURL = serverURL.normalizedServerURL()
            guard let streamURL = URL(string: "\(normalizedURL)\(track.contentUrl)") else {
                error = "Invalid streaming URL"
                isLoading = false
                return
            }

            guard let authToken = userDefaults.authToken else {
                error = "No auth token"
                isLoading = false
                return
            }

            // Create AVURLAsset with auth headers
            let headers = ["Authorization": "Bearer \(authToken)"]
            let asset = AVURLAsset(url: streamURL, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])

            let playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)

            // Seek to last position if resuming
            if session.currentTime > 0 {
                let targetTime = CMTime(seconds: session.currentTime, preferredTimescale: 600)
                await player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }

            // Set playback rate
            player?.rate = playbackRate

            // Start time observer
            setupTimeObserver()

            // Start sync timer
            startSyncTimer()

            isPlaying = true
            isLoading = false
            timeListened = 0
            lastSyncTime = Date()
            updateCurrentChapter()

        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateTimeListened()
    }

    func resume() {
        player?.rate = playbackRate
        isPlaying = true
        lastSyncTime = Date()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateCurrentChapter()
    }

    func skipForward(seconds: Double = 30) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(seconds: Double = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    func goToChapter(_ chapter: Chapter) {
        seek(to: chapter.start)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }

    func cyclePlaybackRate() {
        guard let currentIndex = Self.playbackRates.firstIndex(of: playbackRate) else {
            playbackRate = 1.0
            if isPlaying { player?.rate = 1.0 }
            return
        }
        let nextIndex = (currentIndex + 1) % Self.playbackRates.count
        setPlaybackRate(Self.playbackRates[nextIndex])
    }

    func stop() async {
        // Sync final progress
        if let sessionId = sessionId {
            updateTimeListened()
            await sessionService.syncProgress(
                sessionId: sessionId,
                currentTime: currentTime,
                timeListened: timeListened,
                duration: duration
            )
            await sessionService.closeSession(sessionId: sessionId)
        }

        // Cleanup
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        syncTimer?.invalidate()
        syncTimer = nil
        timeObserver = nil
        player?.pause()
        player = nil
        sessionId = nil
        isPlaying = false
        timeListened = 0
        lastSyncTime = nil
    }

    // MARK: - Private

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds
                self.updateCurrentChapter()
            }
        }
    }

    private func updateCurrentChapter() {
        currentChapter = chapters.first { chapter in
            currentTime >= chapter.start && currentTime < chapter.end
        }
    }

    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let sessionId = self.sessionId else { return }
                self.updateTimeListened()
                await self.sessionService.syncProgress(
                    sessionId: sessionId,
                    currentTime: self.currentTime,
                    timeListened: self.timeListened,
                    duration: self.duration
                )
                self.timeListened = 0
            }
        }
    }

    private func updateTimeListened() {
        guard let lastSync = lastSyncTime, isPlaying else { return }
        timeListened += Date().timeIntervalSince(lastSync)
        lastSyncTime = Date()
    }
}
```

**Step 2: Register AudioPlayerService in ContentView**

In `Noira/App/ContentView.swift`, add the AudioPlayerService as a shared @StateObject and inject it via .environmentObject:

Add after line 12 (`@StateObject private var absLibraryService`):
```swift
@StateObject private var audioPlayerService = AudioPlayerService()
```

Update the RootView injection (line 18-19) to add the new service:
```swift
RootView()
    .environmentObject(authService)
    .environmentObject(absLibraryService)
    .environmentObject(audioPlayerService)
```

**Step 3: Commit**
```bash
git add Noira/Services/AudioPlayerService.swift Noira/App/ContentView.swift
git commit -m "feat: add AudioPlayerService with AVPlayer wrapper and progress sync"
```

---

## Phase 4: Navigation & NowPlayingView

### Task 6: Update navigation for Now Playing

**Files:**
- Modify: `Noira/Navigation/Destination.swift`
- Modify: `Noira/Views/RootView.swift`

**Step 1: Add nowPlaying destination**

Replace `Noira/Navigation/Destination.swift` with:
```swift
//
//  Destination.swift
//  Noira
//
//  Created by Shalva Gegia on 16/09/2025.
//

import Foundation
import SwiftUI

enum Destination: Hashable {
    case search
    case settings
    case detail(Book)
    case nowPlaying(Book)
}
```

**Step 2: Update RootView to handle nowPlaying destination and use AudioPlayerService for the tab**

Replace `Noira/Views/RootView.swift` with:
```swift
//
//  RootView.swift
//  Noira
//
//  Created by Shalva Gegia on 16/09/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var audioPlayerService: AudioPlayerService

    var body: some View {
        TabView {
            // Library
            NavigationStack {
                LibraryView()
                    .navigationDestination(for: Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Text("Library")
            }

            // Now Playing
            NavigationStack {
                NowPlayingView()
            }
            .tabItem {
                Label("Now Playing", systemImage: "waveform")
            }

            // Settings
            SettingsView()
                .tabItem {
                    Text("Settings")
                }

            // Search
            NavigationStack {
                SearchView()
                    .navigationDestination(for: Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .detail(let book):
            BookDetailView(book: book)
        case .nowPlaying(let book):
            NowPlayingView(bookToPlay: book)
        case .search:
            SearchView()
        case .settings:
            SettingsView()
        }
    }

}
```

**Step 3: Commit**
```bash
git add Noira/Navigation/Destination.swift Noira/Views/RootView.swift
git commit -m "feat: add nowPlaying navigation destination"
```

---

### Task 7: Rewrite NowPlayingView

**Files:**
- Modify: `Noira/Views/NowPlaying/NowPlayingView.swift`

**Step 1: Complete rewrite of NowPlayingView**

Replace `Noira/Views/NowPlaying/NowPlayingView.swift` with:
```swift
//
//  NowPlayingView.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var audioPlayerService: AudioPlayerService

    var bookToPlay: Book?

    @State private var prominentColor: Color = Color.clear
    @State private var vibrantColor: Color = Color.clear
    @State private var secondaryColor: Color = Color.clear

    var body: some View {
        Group {
            if audioPlayerService.isLoading {
                ProgressView("Loading audiobook...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let book = audioPlayerService.currentBook {
                playerView(for: book)
            } else {
                emptyStateView
            }
        }
        .task {
            if let book = bookToPlay, audioPlayerService.currentBook?.id != book.id {
                await audioPlayerService.play(book: book)
            }
            if let coverURL = audioPlayerService.currentBook?.coverImageURL ?? bookToPlay?.coverImageURL {
                let colors = await ImageColorExtractor.extractColors(from: coverURL)
                prominentColor = colors.prominent ?? .clear
                vibrantColor = colors.vibrant ?? .clear
                secondaryColor = colors.secondary ?? .clear
            }
        }
    }

    // MARK: - Player View

    private func playerView(for book: Book) -> some View {
        HStack(alignment: .center, spacing: 80) {
            // Cover Art
            VStack {
                Spacer()
                SquareBookCover(
                    url: book.coverImageURL,
                    size: 400,
                    radius: 12
                )
                .shadow(radius: 12)
                Spacer()
            }

            // Controls & Info
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                // Title & Author
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Text("by \(book.authors.map(\.name).joined(separator: ", "))")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                // Current Chapter
                if let chapter = audioPlayerService.currentChapter {
                    Text(chapter.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progress Bar
                VStack(spacing: 8) {
                    ProgressView(value: audioPlayerService.currentTime, total: max(audioPlayerService.duration, 1))
                        .tint(.white)

                    HStack {
                        Text(formatTime(audioPlayerService.currentTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(audioPlayerService.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Playback Controls
                HStack(spacing: 40) {
                    Button(action: { audioPlayerService.skipBackward() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "gobackward.15")
                                .font(.title2)
                            Text("15s")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerService.togglePlayPause() }) {
                        Image(systemName: audioPlayerService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerService.skipForward() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "goforward.30")
                                .font(.title2)
                            Text("30s")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerService.cyclePlaybackRate() }) {
                        Text(formatRate(audioPlayerService.playbackRate))
                            .font(.callout)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }

                // Chapter List
                if !audioPlayerService.chapters.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chapters")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(audioPlayerService.chapters) { chapter in
                                    Button(action: { audioPlayerService.goToChapter(chapter) }) {
                                        Text(chapter.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                audioPlayerService.currentChapter?.id == chapter.id
                                                    ? Color.white.opacity(0.3)
                                                    : Color.white.opacity(0.1)
                                            )
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollClipDisabled()
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.all, 60)
        .dynamicGradientBackground(colors: [secondaryColor, prominentColor, vibrantColor])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Nothing Playing")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Select an audiobook from your library to start listening")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatRate(_ rate: Float) -> String {
        if rate == Float(Int(rate)) {
            return String(format: "%.0fx", rate)
        }
        return String(format: "%.1fx", rate)
                .replacingOccurrences(of: ".0x", with: "x")
    }
}

#Preview("Empty State") {
    NowPlayingView()
        .environmentObject(AudioPlayerService())
}
```

**Step 2: Commit**
```bash
git add Noira/Views/NowPlaying/NowPlayingView.swift
git commit -m "feat: complete NowPlayingView with player controls and chapter navigation"
```

---

### Task 8: Wire play button in BookDetailView

**Files:**
- Modify: `Noira/Views/Book/BookDetailView.swift`

**Step 1: Wire the play button to navigate to NowPlayingView**

In `BookDetailView.swift`, add `@EnvironmentObject` for AudioPlayerService, and update the play button action.

Replace the full file with:
```swift
//
//  BookDetailView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI
import AttributedText

struct BookDetailView: View {
    let book: Book
    @EnvironmentObject var audioPlayerService: AudioPlayerService
    @State private var prominentColor: Color = Color.clear
    @State private var vibrantColor: Color = Color.clear
    @State private var secondaryColor: Color = Color.clear

    var body: some View {
        HStack(alignment: .center, spacing: 100) {
                VStack(alignment: .trailing, spacing: 48) {
                    Spacer()
                        .frame(maxWidth: .infinity)
                    SquareBookCover(
                        url: book.coverImageURL,
                        size: 600,
                        radius: 12
                    )
                    .shadow(radius: 12)
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(
                            "by \(book.authors.map(\.name).joined(separator: ", "))"
                        )
                        .font(.title2)
                        .foregroundColor(.secondary)
                    }

                    NavigationLink(value: Destination.nowPlaying(book)) {
                        HStack(spacing: 12) {
                            Image(systemName: book.progress > 0 ? "play.fill" : "play.fill")
                            Text(book.progress > 0 ? "Continue" : "Play")
                        }
                    }

                    // Duration
                    if !book.narrators.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(book.formattedDuration)
                                .font(.caption)
                        }
                    }

                    // Progress
                    if book.progress > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(Int(book.progress * 100))%")
                                .font(.caption)
                        }
                    }

                    // Narrators
                    if !book.narrators.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Narrated by")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(book.narrators.joined(separator: ", "))
                                .font(.caption)
                        }
                    }

                    // Genres
                    if !book.genres.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Genres")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                ForEach(book.genres, id: \.self) {
                                    genre in
                                    Text(genre)
                                        .font(.caption)
                                }
                            }
                        }
                    }

                    // Description
                    if !book.description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            AttributedText(book.description)
                        }
                    }
                }
            }
            .padding(.all, 60)
        .dynamicGradientBackground(colors: [secondaryColor, prominentColor, vibrantColor])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: [.all])
        .task {
            let colors = await ImageColorExtractor.extractColors(from: book.coverImageURL)
            prominentColor = colors.prominent ?? .clear
            vibrantColor = colors.vibrant ?? .clear
            secondaryColor = colors.secondary ?? .clear
        }
    }
}

#Preview("Book 1") {
    NavigationStack {
        BookDetailView(book: Book.sampleBooks[0])
            .environmentObject(AudioPlayerService())
    }
}

#Preview("Book 2") {
    NavigationStack {
        BookDetailView(book: Book.sampleBooks[1])
            .environmentObject(AudioPlayerService())
    }
}
```

Changes: replaced empty `Button` with `NavigationLink(value: .nowPlaying(book))`, added progress display, shows "Continue" when progress > 0, added `@EnvironmentObject` for AudioPlayerService.

**Step 2: Commit**
```bash
git add Noira/Views/Book/BookDetailView.swift
git commit -m "feat: wire play button to NowPlayingView navigation"
```

---

## Phase 5: Final Integration & Verification

### Task 9: Build verification and final fixes

**Step 1: Build the project**

Run: `xcodebuild -project Noira.xcodeproj -scheme Noira -destination 'platform=tvOS Simulator,name=Apple TV' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 2: Fix any build errors**

If there are compile errors, fix them one at a time. Common issues to watch for:
- Missing `Identifiable` conformance
- Missing `@EnvironmentObject` in preview providers
- Import statements (AVFoundation in AudioPlayerService)
- File not added to Xcode project (since we use filesystem sync, new files in the Noira/ directory should be auto-detected)

**Step 3: Final commit**
```bash
git add -A
git commit -m "feat: complete audiobook player with ABS integration and bug fixes"
```

---

## Summary of All Changes

### New Files (5)
1. `Noira/Models/ABS/ABSMediaProgress.swift` — /api/me progress models
2. `Noira/Models/ABS/ABSPlayback.swift` — playback session API models
3. `Noira/Services/PlaybackSessionService.swift` — ABS session API (start/sync/close)
4. `Noira/Services/AudioPlayerService.swift` — AVPlayer wrapper + state management

### Modified Files (8)
1. `Noira/Services/AuthenticationService.swift` — removed debug prints
2. `Noira/Services/ABSLibraryService.swift` — added progress fetching from /api/me
3. `Noira/Services/Mappers/ABSLibraryItemMapper.swift` — maps progress data to Book
4. `Noira/Services/UserDefaultsService.swift` — added deviceId
5. `Noira/Views/Settings/SettingsView.swift` — removed broken theme picker, fixed singleton access
6. `Noira/Navigation/Destination.swift` — added .nowPlaying(Book)
7. `Noira/Views/RootView.swift` — updated navigation handling
8. `Noira/Views/Book/BookDetailView.swift` — wired play button
9. `Noira/Views/NowPlaying/NowPlayingView.swift` — complete rewrite
10. `Noira/App/ContentView.swift` — added AudioPlayerService injection

### Deleted Files (2)
1. `Noira.xcodeproj/AudioBookshelfModels.swift`
2. `Noira/Views/Home/Components/StandardBookCard.swift`
