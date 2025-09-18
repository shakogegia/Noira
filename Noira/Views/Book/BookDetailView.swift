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
    @State private var prominentColor: Color = Color.clear
    @State private var vibrantColor: Color = Color.clear
    @State private var secondaryColor: Color = Color.clear

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    secondaryColor,
                    prominentColor,
                    vibrantColor,
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

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

                    Button(
                        action: {

                        },
                        label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                        }
                    )

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

                    // Genres
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: [.all])
        .onAppear{
            extractColors()
        }
    }

    private func extractColors() {
        // Convert SwiftUI Image to UIImage and extract colors
        DispatchQueue.global(qos: .background).async {
            // This is a simplified approach - in reality you'd need to
            // convert the SwiftUI Image to UIImage properly
            // For now, we'll use a fallback approach with URL
            if let urlString = book.coverImageURL,
                let url = URL(string: urlString),
                let data = try? Data(contentsOf: url),
                let uiImage = UIImage(data: data)
            {
                let prominent = uiImage.prominentSwiftUIColor
                let vibrant = uiImage.vibrantSwiftUIColor
                let secondary = uiImage.secondarySwiftUIColor
                
                DispatchQueue.main.async {
                    prominentColor = prominent ?? .clear
                    vibrantColor = vibrant ?? .clear
                    secondaryColor = secondary ?? .clear
                }
            }
        }
    }
}

#Preview("Book 1") {
    NavigationView {
        BookDetailView(book: Book.sampleBooks[0])  // The Hobbit with 30% progress
    }
}

#Preview("Book 2") {
    NavigationView {
        BookDetailView(book: Book.sampleBooks[1])  // Dune with 0% progress
    }
}
