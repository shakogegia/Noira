//
//  LibraryView.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct LibraryView: View {
    @State private var books = Book.sampleBooks
    
    var body: some View {
        BookGridView(books: books)
    }
}

#Preview {
    LibraryView()
}
