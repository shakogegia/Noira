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
