//
//  BookGridView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct BookGridView: View {
    let books: [Book]
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 240), spacing: 40)
    ]
    
    var body: some View {
        ScrollView {
            if books.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No books found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("This section doesn't have any books yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: columns) {
                    ForEach(books) { book in
                        StandardBookCard(book: book)
                    }
                }
                .padding()
                .focusSection()
            }
        }
        .scrollClipDisabled()
    }
}

#Preview("With Books") {
    BookGridView(books: Book.sampleBooks)
}

#Preview("Empty State") {
    BookGridView(books: [])
}

#Preview("Few Books") {
    BookGridView(books: Array(Book.sampleBooks.prefix(2)))
}

#Preview("Many Books") {
    // Simulate lots of books
    let manyBooks = Array(repeating: Book.sampleBooks, count: 5).flatMap { $0 }
    BookGridView(books: manyBooks)
}
