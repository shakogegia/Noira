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
