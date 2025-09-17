//
//  StandardBookCard.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct StandardBookCard: View {
    let book: Book
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationLink(value: Destination.detail(book)) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover
                SquareBookCover(url: book.coverImageURL, size: 240, radius: 12)
                    .hoverEffect(.highlight)
                
                // Information
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(book.authors.map(\.name).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(width: 160, alignment: .leading)
                // if is focused move down a bit with animation
                .offset(y: isFocused ? 16 : 0)
            }
        }
        .focused($isFocused)
        .buttonStyle(.borderless)
    }
}

struct CardOverlayLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .bottomLeading) {
            configuration.icon
//                .resizable()
                .aspectRatio(400/240, contentMode: .fit)
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.6), location: 0.1),
                            .init(color: .black.opacity(0.2), location: 0.25),
                            .init(color: .black.opacity(0), location: 0.4)
                        ],
                        startPoint: .bottom, endPoint: .top
                    )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 2)
                        .foregroundStyle(.quaternary)
                }


            configuration.title
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(6)
        }
        .frame(maxWidth: 400)
    }
}

#Preview("Single Card") {
    StandardBookCard(book: Book.sampleBooks[0])
        .padding()
}

#Preview("Multiple Cards") {
    HStack(spacing: 20) {
        ForEach(Book.sampleBooks.prefix(3)) { book in
            StandardBookCard(book: book)
        }
    }
    .padding()
}

#Preview("Grid Layout") {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(160)), count: 3), spacing: 20) {
        ForEach(Book.sampleBooks) { book in
            StandardBookCard(book: book)
        }
    }
    .padding()
}
