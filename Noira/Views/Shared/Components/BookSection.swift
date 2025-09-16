//
//  BookSection.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct BookSection: View {
    let title: String
    let books: [Book]
    let maxItems: Int
    let cardStyle: CardStyle
    let onSeeAll: () -> Void
    
    enum CardStyle {
        case featured  // Use FeaturedBookCard
        case standard  // Use StandardBookCard
    }
    
    init(title: String, books: [Book], maxItems: Int = 8, cardStyle: CardStyle = .standard, onSeeAll: @escaping () -> Void) {
        self.title = title
        self.books = books
        self.maxItems = maxItems
        self.cardStyle = cardStyle
        self.onSeeAll = onSeeAll
    }
    
    private var displayBooks: [Book] {
        Array(books.prefix(maxItems))
    }
    
    private var shouldShowSeeAll: Bool {
        books.count > maxItems
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header (title only)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Books Scroll with See All at the end
            if !books.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: cardStyle == .featured ? 24 : 20) {
                        // Display books
                        ForEach(displayBooks) { book in
                            switch cardStyle {
                            case .featured:
                                FeaturedBookCard(book: book)
                            case .standard:
                                StandardBookCard(book: book)
                            }
                        }
                        
                        // See All card at the end
                        if shouldShowSeeAll {
                            SeeAllCard(
                                count: books.count,
                                cardStyle: cardStyle,
                                action: onSeeAll
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, cardStyle == .featured ? 15 : 10)
                }
            } else {
                Text("No books available")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
    }
}

struct SeeAllCard: View {
    let count: Int
    let cardStyle: BookSection.CardStyle
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    private var cardSize: CGSize {
        switch cardStyle {
        case .featured:
            return CGSize(width: 240, height: 360)
        case .standard:
            return CGSize(width: 160, height: 160)
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cardStyle == .featured ? 12 : 8)
            .fill(Color.gray.opacity(0.3))  // ← Gray background like book cards
            .frame(width: cardSize.width, height: cardSize.height)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: cardStyle == .featured ? 40 : 30))
                        .foregroundColor(.white)
                    
                    Text("See All")
                        .font(cardStyle == .featured ? .headline : .caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("(\(count) books)")
                        .font(cardStyle == .featured ? .subheadline : .caption2)
                        .foregroundColor(.gray)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cardStyle == .featured ? 12 : 8)
                    .stroke(Color.white, lineWidth: isFocused ? 4 : 0)
            )
            .focusable()
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .onTapGesture {
                action()
            }
    }
}

#Preview("Standard Section") {
    BookSection(
        title: "Your Library",
        books: Book.sampleBooks,
        maxItems: 6,
        cardStyle: .standard
    ) {
        print("See all tapped")
    }
    .background(Color.black)
}

#Preview("Featured Section") {
    BookSection(
        title: "Continue Reading",
        books: Book.sampleBooks.filter { $0.progress > 0 },
        maxItems: 3,
        cardStyle: .featured
    ) {
        print("See all tapped")
    }
    .background(Color.black)
}

#Preview("Short List") {
    BookSection(
        title: "Fantasy",
        books: Array(Book.sampleBooks.prefix(2)), // Only 2 books
        maxItems: 6,
        cardStyle: .standard
    ) {
        print("See all tapped")
    }
    .background(Color.black)
}
