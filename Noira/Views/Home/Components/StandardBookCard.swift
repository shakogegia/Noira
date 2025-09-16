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
        NavigationLink(value: book) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover Image
                AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 160)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .overlay(
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.gray.opacity(0.6))
                                .hoverEffectDisabled(true)
                        )
                }
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isFocused ? 3 : 0)
                )
                
                // Book Information
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(book.authors.map(\.name).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(width: 160, alignment: .leading)
            }
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .focused($isFocused)
        .buttonStyle(.borderless)
        
    }
}

#Preview("Single Card") {
    StandardBookCard(book: Book.sampleBooks[0])
        .background(Color.black)
        .padding()
}

#Preview("Multiple Cards") {
    HStack(spacing: 20) {
        ForEach(Book.sampleBooks.prefix(3)) { book in
            StandardBookCard(book: book)
        }
    }
    .background(Color.black)
    .padding()
}

#Preview("Grid Layout") {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(160)), count: 3), spacing: 20) {
        ForEach(Book.sampleBooks) { book in
            StandardBookCard(book: book)
        }
    }
    .background(Color.black)
    .padding()
}
