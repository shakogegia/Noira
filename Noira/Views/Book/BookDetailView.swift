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
                            Image(systemName: "play.fill")
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
