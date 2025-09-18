//
//  RootView.swift
//  Noira
//
//  Created by Shalva Gegia on 16/09/2025.
//

import SwiftUI

struct RootView: View {

    var body: some View {
        NavigationStack {
            TabView {
                // Library
                LibraryView()
                    .tabItem {
                        Text("Library")
                    }

                // Now Playing
                NowPlayingView()
                    .tabItem {
                        Label("Now Playing", systemImage: "waveform")
                    }

                // Settings
                SettingsView()
                    .tabItem {
                        Text("Settings")
                    }

                // Search
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                    }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .detail(let book):
                    BookDetailView(book: book)
                case .search:
                    SearchView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }

}
