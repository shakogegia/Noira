//
//  RootView.swift
//  Noira
//
//  Created by Shalva Gegia on 16/09/2025.
//

import SwiftUI

struct RootView: View {

    var body: some View {
        TabView {
            // Library
            NavigationStack {
                LibraryView()
                    .navigationDestination(for: Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
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
            NavigationStack {
                SearchView()
                    .navigationDestination(for: Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
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
