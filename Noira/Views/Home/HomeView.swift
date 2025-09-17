//
//  HomeView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var books = Book.sampleBooks
    @State private var showingLibrary = false
    @State private var showingRecentlyAdded = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.plain)
                }
                .focusSection()
                
                // Continue Reading Section
                if !continueReadingBooks.isEmpty {
                    BookSection(
                        title: "Continue where you left off",
                        books: continueReadingBooks,
                        maxItems: 3,
                        cardStyle: .featured
                    ) {
                        // TODO: Navigate to continue reading view
                        print("See all continue reading")
                    }
                    .focusSection()
                }
                
                // Recently Added Section
                BookSection(
                    title: "Recently added",
                    books: recentlyAddedBooks,
                    maxItems: 6,
                    cardStyle: .standard
                ) {
                    showingRecentlyAdded = true
                }
                .focusSection()
                
                // Your Library Section
                BookSection(
                    title: "Your library",
                    books: books,
                    maxItems: 8,
                    cardStyle: .standard
                ) {
                    showingLibrary = true
                }
                .focusSection()
            }
            .padding(.vertical)
        }
        .navigationDestination(for: Book.self) { book in
            BookDetailView(book: book)
        }
        // Navigation sheets
        .fullScreenCover(isPresented: $showingLibrary) {
            BookGridView(books: books)
        }
        .fullScreenCover(isPresented: $showingRecentlyAdded) {
            BookGridView(books: recentlyAddedBooks)
        }
    }
    
    // MARK: - Computed Properties
    
    private var continueReadingBooks: [Book] {
        books.filter { $0.progress > 0 && $0.progress < 1.0 }
            .sorted {
                ($0.lastPlayedDate ?? Date.distantPast) > ($1.lastPlayedDate ?? Date.distantPast)
            }
    }
    
    private var recentlyAddedBooks: [Book] {
        // For now, just reverse the sample books
        // In real app, this would be sorted by date added
        books.reversed()
    }
    
    private var fantasyBooks: [Book] {
        books.filter { $0.genres.contains("Fantasy") }
    }
    
    private var sciFiBooks: [Book] {
        books.filter { $0.genres.contains("Science Fiction") }
    }
}

#Preview {
    HomeView()
}
