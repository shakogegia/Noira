//
//  BookGridView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct BookGridView: View {
    let title: String
    let books: [Book]
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
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
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(books) { book in
                            StandardBookCard(book: book)
                                .onTapGesture {
                                    // TODO: Navigate to book detail
                                    print("Tapped book: \(book.title)")
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book) // 👈 destination for a book
            }
        }
    }
}

#Preview("With Books") {
    BookGridView(title: "Fantasy", books: Book.sampleBooks)
}

#Preview("Empty State") {
    BookGridView(title: "Mystery", books: [])
}

#Preview("Few Books") {
    BookGridView(title: "Recently Added", books: Array(Book.sampleBooks.prefix(2)))
}

#Preview("Many Books") {
    // Simulate lots of books
    let manyBooks = Array(repeating: Book.sampleBooks, count: 5).flatMap { $0 }
    BookGridView(title: "Your Library", books: manyBooks)
}
