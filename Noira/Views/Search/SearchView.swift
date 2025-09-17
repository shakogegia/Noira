//
//  SearchView.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct SearchView: View {
    @State private var books = Book.sampleBooks

    @State var searchTerm: String = ""

    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 10)

    var body: some View {
        BookGridView(books: filteredBooks)
            .scrollClipDisabled()
            .searchable(text: $searchTerm)
            .searchSuggestions {
                ForEach(suggestedSearchTerms, id: \.self) { suggestion in
                    Text(suggestion)
                }
            }
    }

    private var filteredBooks: [Book] {
        if searchTerm.isEmpty {
            return books
        }

        return books.filter {
            $0.title.localizedLowercase.contains(searchTerm.localizedLowercase)
        }
    }

    private var suggestedSearchTerms: [String] {
        // If there's no search term yet, suggest a few popular/recent titles from the catalog
        let titles = books.map { $0.title }
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Return up to 8 unique titles as generic suggestions
            return Array(Set(titles)).prefix(8).map { String($0) }
        }

        // When the user types, suggest titles that contain the term (case-insensitive)
        let lower = searchTerm.localizedLowercase
        let matches = titles.filter { $0.localizedLowercase.contains(lower) }

        // De-duplicate while preserving order, and cap the list
        var seen = Set<String>()
        var unique: [String] = []
        for t in matches {
            if !seen.contains(t) {
                unique.append(t)
                seen.insert(t)
            }
            if unique.count >= 8 { break }
        }
        return unique
    }
}

#Preview {
    SearchView()
}
