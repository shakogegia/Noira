//
//  LibraryView.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var absLibraryService = ABSLibraryService()

    var body: some View {
        Group {
            // Loading
            if absLibraryService.isLoading {
                ProgressView("Loading library...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = absLibraryService.error {
                // Error
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)

                    Text("Error loading library")
                        .font(.headline)

                    Text(error.localizedDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Retry") {
                        Task {
                            await absLibraryService.fetchLibraryItems()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Book grid
                        BookGridView(books: absLibraryService.books)
                            .refreshable {
                                await absLibraryService.fetchLibraryItems()
                            }

                        // Refrehs
                        Button(
                            action: {
                                Task {
                                    await absLibraryService.fetchLibraryItems()
                                }
                            },
                            label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh")
                                }
                            }
                        )
                    }
                }
            }
        }
        .task {
            await absLibraryService.fetchLibraryItems()
        }
    }
}

#Preview {
    LibraryView()
}
