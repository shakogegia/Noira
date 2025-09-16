//
//  RootView.swift
//  Noira
//
//  Created by Shalva Gegia on 16/09/2025.
//

import SwiftUI

struct RootView: View {
    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .detail(let book):
                    BookDetailView(book: book)
                case .search:
                    LoginView()
                case .settings:
                    LoginView()
                }
            }
        }
    }
    
}
