//
//  SampleData.swift
//  Noira
//
//  Created by Shalva Gegia on 16/09/2025.
//

import Foundation


struct SampleData {
    static let libraries: [Library] = [
        Library(id: 1, name: "NAS"),
        Library(id: 2, name: "My Library")
    ]
    
    static let authors: [Author] = [
        Author(id: "1", name: "Pierce Brown"),
        Author(id: "2", name: "Andy Weir"),
    ]
    
    static let books: [Book] = [
        Book (
            id: "1",
            title: "Red Rising",
            authors: [ authors[1] ],
            narrators: ["Jenna Sharpe"],
            genres: ["Fantasy", "Adventure"],
            description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
            duration: 36000, // 10 hours
            coverImageURL: "https://www.graphicaudiointernational.net/media/catalog/product/cache/0164cd528593768540930b5b640a411b/r/e/red_rising_saga_1_red_rising_1_of_2_1.jpg",
            progress: 0.7,
            lastPlayedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        ),
    ]
}


extension Book {
    static let sampleBooks = [
        Book(
            id: "1",
            title: "The Hobbit",
            authors: [Author(id: "1", name: "J.R.R. Tolkien")],
            narrators: ["Andy Serkis"],
            genres: ["Fantasy", "Adventure"],
            description: "A reluctant Hobbit, Bilbo Baggins, sets out to the Lonely Mountain with a spirited group of dwarves to reclaim their mountain home and the gold within it from the dragon Smaug.",
            duration: 36000, // 10 hours
            coverImageURL: "https://audiobookshelf.wibautstraat.me/audiobookshelf/api/items/a3940781-61c5-40a0-a3d8-85a683b00180/cover?ts=1757516905307&raw=1",
            progress: 0.7,
            lastPlayedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        ),
        Book(
            id: "2",
            title: "Dune",
            authors: [Author(id: "1", name: "Frank Herbert")],
            narrators: ["Scott Brick", "Orlagh Cassidy", "Euan Morton"],
            genres: ["Science Fiction", "Epic"],
            description: "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world.",
            duration: 75600, // 21 hours
            coverImageURL: "https://audiobookshelf.wibautstraat.me/audiobookshelf/api/items/6f22d592-fb54-42d0-bc63-563b136b8f0f/cover?ts=1739203911222&raw=1",
            progress: 0.0,
            lastPlayedDate: nil
        ),
        Book(
            id: "3",
            title: "Project Hail Mary",
            authors: [Author(id: "1", name: "Andy Weir")],
            narrators: ["Ray Porter"],
            genres: ["Science Fiction", "Thriller"],
            description: "Ryland Grace is the sole survivor on a desperate, last-chance mission—and if he fails, humanity and the earth itself will perish.",
            duration: 57600, // 16 hours
            coverImageURL: "https://audiobookshelf.wibautstraat.me/audiobookshelf/api/items/ac511d8d-6a92-45e5-a302-2093a920c37e/cover?ts=1746015572644&raw=1",
            progress: 0.7,
            lastPlayedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        ),
        Book(
            id: "4",
            title: "1984",
            authors: [Author(id: "1", name: "George Orwell")],
            narrators: ["Simon Prebble"],
            genres: ["Dystopian", "Political Fiction"],
            description: "A chilling prophecy about the future, 1984 presents a totalitarian world where Big Brother watches every move.",
            duration: 40000, // ~11 hours
            coverImageURL: "https://audiobookshelf.wibautstraat.me/audiobookshelf/api/items/713007db-0cce-4b4d-8b56-fa5b393e749e/cover?ts=1757516905396&raw=1",
            progress: 0.1,
            lastPlayedDate: Date().addingTimeInterval(-172800) // 2 days ago
        ),
        Book(
            id: "5",
            title: "Becoming",
            authors: [Author(id: "1", name: "Michelle Obama")],
            narrators: ["Michelle Obama"],
            genres: ["Memoir", "Biography"],
            description: "An intimate, powerful, and inspiring memoir by the former First Lady of the United States.",
            duration: 67800, // ~18.8 hours
            coverImageURL: nil,
            progress: 0.5,
            lastPlayedDate: Date().addingTimeInterval(-7200) // 2 hours ago
        ),
        Book(
            id: "6",
            title: "The Martian",
            authors: [Author(id: "1", name: "Andy Weir")],
            narrators: ["R.C. Bray"],
            genres: ["Science Fiction", "Adventure"],
            description: "An astronaut becomes stranded on Mars and must rely on his ingenuity to survive until rescue is possible.",
            duration: 42000, // ~11.6 hours
            coverImageURL: nil,
            progress: 0.9,
            lastPlayedDate: Date().addingTimeInterval(-300000) // ~3.5 days ago
        ),
        Book(
            id: "7",
            title: "Educated",
            authors: [Author(id: "1", name: "Tara Westover")],
            narrators: ["Julia Whelan"],
            genres: ["Memoir", "Nonfiction"],
            description: "The memoir of a woman who grows up in a strict and abusive household in rural Idaho but eventually escapes to learn about the wider world through education.",
            duration: 43200, // 12 hours
            coverImageURL: nil,
            progress: 0.2,
            lastPlayedDate: nil
        ),
        Book(
            id: "8",
            title: "Harry Potter and the Sorcerer’s Stone",
            authors: [Author(id: "1", name: "J.K. Rowling")],
            narrators: ["Jim Dale"],
            genres: ["Fantasy", "Young Adult"],
            description: "Harry discovers on his 11th birthday that he is a wizard and attends Hogwarts School of Witchcraft and Wizardry.",
            duration: 28800, // 8 hours
            coverImageURL: nil,
            progress: 0.65,
            lastPlayedDate: Date().addingTimeInterval(-600) // 10 minutes ago
        )
    ]
}
