//
//  ABSLibraryItemMapper.swift
//  Noira
//
//  Created by Shalva Gegia on 23/12/2025.
//

import Foundation

struct ABSLibraryItemMapper {
    /// Maps API library items to app Book models
    static func mapToBooks(
        from items: [ABSLibraryItem],
        serverURL: String
    ) -> [Book] {
        let books = items.compactMap { item -> Book? in
            mapToBook(from: item, serverURL: serverURL)
        }

        // Sort by addedAt descending (newest first)
        return books.sorted { ($0.addedAt ?? .distantPast) > ($1.addedAt ?? .distantPast) }
    }

    // MARK: - Private Mapping Methods

    private static func mapToBook(from item: ABSLibraryItem, serverURL: String) -> Book? {
        // Only process book media types
        guard item.mediaType == "book" else { return nil }

        let metadata = item.media.metadata
        let authors = mapAuthors(from: metadata.authorName, itemId: item.id)
        let narrators = mapNarrators(from: metadata.narratorName)
        let coverURL = buildCoverURL(coverPath: item.media.coverPath, itemId: item.id, serverURL: serverURL)
        let series = mapSeries(from: metadata)
        let addedAt = mapDate(from: item.addedAt)

        return Book(
            id: item.id,
            title: metadata.title,
            subtitle: metadata.subtitle,
            authors: authors,
            narrators: narrators,
            genres: metadata.genres ?? [],
            description: metadata.description ?? "",
            duration: item.media.duration ?? 0,
            coverImageURL: coverURL,
            progress: 0.0, // TODO: Fetch from progress endpoint
            lastPlayedDate: nil, // TODO: Fetch from progress endpoint
            addedAt: addedAt,
            publisher: metadata.publisher,
            publishedYear: metadata.publishedYear,
            series: series
        )
    }

    private static func mapAuthors(from authorName: String?, itemId: String) -> [Author] {
        guard let authorName = authorName, !authorName.isEmpty else {
            return []
        }

        // Split multiple authors by comma
        let authorNames = authorName.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return authorNames.enumerated().map { index, name in
            Author(id: "\(itemId)_author_\(index)", name: name)
        }
    }

    private static func mapNarrators(from narratorName: String?) -> [String] {
        guard let narratorName = narratorName, !narratorName.isEmpty else {
            return []
        }

        return narratorName.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }

    private static func buildCoverURL(coverPath: String?, itemId: String, serverURL: String) -> String? {
        guard coverPath != nil, !coverPath!.isEmpty else { return nil }
        return "\(serverURL)/audiobookshelf/api/items/\(itemId)/cover"
    }

    private static func mapSeries(from metadata: ABSLibraryItem.Media.Metadata) -> Serie? {
        guard let seriesName = metadata.seriesName, !seriesName.isEmpty else {
            return nil
        }

        return Serie(
            id: seriesName.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: seriesName,
            sequence: "" // API doesn't provide sequence info in this endpoint
        )
    }

    private static func mapDate(from milliseconds: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
