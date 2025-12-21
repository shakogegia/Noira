# Noira - AI Assistant Instructions

## Project Overview

**Noira** is an Apple TV (tvOS) client application for [Audiobookshelf](https://www.audiobookshelf.org/) - a self-hosted audiobook and podcast server. The app allows users to browse their audiobook library, view book details, and listen to audiobooks on Apple TV.

### Tech Stack
- **Platform**: tvOS (Apple TV)
- **Language**: Swift 5+
- **Framework**: SwiftUI
- **Architecture**: MVVM-like with Services
- **Package Dependencies**:
  - `AttributedText` - For rendering HTML descriptions

---

## Project Structure

```
Noira/
├── App/                          # App entry point
│   ├── NoiraApp.swift           # @main App struct
│   └── ContentView.swift        # Root view with auth routing
├── Models/                       # Data models
│   ├── Book.swift               # Core Book model with Author, Serie, Chapter, Progress
│   ├── Library.swift            # Library model
│   ├── SampleData.swift         # Mock data for previews
│   └── ABS/                     # Audiobookshelf API models
│       ├── ABSAuth.swift        # Login request/response models
│       ├── ABSLibrary.swift     # Library API response models
│       └── ABSUser.swift        # User model
├── Navigation/
│   └── Destination.swift        # Navigation destinations enum
├── Services/                     # Business logic & networking
│   ├── ABSService.swift         # Base ABS service (empty)
│   ├── ABSLibraryService.swift  # Library fetching service
│   ├── AuthenticationService.swift # Auth handling
│   └── UserDefaultsService.swift   # Persistent storage
├── Utilities/
│   └── Extensions/
│       ├── Color+Extensions.swift
│       ├── UIImage+Extensions.swift # Color extraction from images
│       └── View+Extensions.swift
└── Views/
    ├── RootView.swift           # Main TabView navigation
    ├── Authentication/
    │   └── LoginView.swift      # Server login form
    ├── Book/
    │   └── BookDetailView.swift # Book detail page
    ├── Home/
    │   ├── HomeView.swift
    │   └── Components/
    │       ├── FeaturedBookCard.swift
    │       └── StandardBookCard.swift
    ├── Library/
    │   └── LibraryView.swift    # Book grid library view
    ├── NowPlaying/
    │   └── NowPlayingView.swift # Currently playing (WIP)
    ├── Search/
    │   └── SearchView.swift     # Search with suggestions
    ├── Settings/
    │   └── SettingsView.swift   # App settings & logout
    └── Shared/
        └── Components/
            ├── BookGridView.swift    # Reusable book grid
            ├── BookSection.swift
            └── SquareBookCover.swift # AsyncImage cover component
```

---

## Architecture & Patterns

### State Management
- **`@StateObject`**: For owning observable objects in views
- **`@EnvironmentObject`**: For sharing `AuthenticationService` across view hierarchy
- **`@Published`**: For reactive properties in services
- **`@MainActor`**: Used on services that update UI state

### Services Pattern
Services are `ObservableObject` classes that handle:
- Network requests to Audiobookshelf API
- State management (`isLoading`, `error`, data)
- Data transformation (API models → App models)

```swift
@MainActor
class ABSLibraryService: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: ABSLibraryError?
    
    func fetchLibraryItems() async { ... }
}
```

### Navigation
- Uses `NavigationStack` with `TabView` for main navigation
- Type-safe navigation with `Destination` enum
- `NavigationLink(value:)` pattern for programmatic navigation

### Error Handling
- Custom error enums conforming to `LocalizedError`
- Each service has its own error type (e.g., `AuthenticationError`, `ABSLibraryError`)
- Errors provide user-friendly descriptions via `errorDescription`

---

## Audiobookshelf API Integration

### Authentication Flow
1. User enters server URL, username, password
2. App POSTs to `{serverURL}/login`
3. On success, stores token in `UserDefaults`
4. Token validated on app launch via `/api/me`

### API Endpoints Used
- `POST /login` - Authentication
- `GET /api/me` - Validate token
- `GET /api/libraries/{libraryId}/items` - Fetch library books
- Cover images: `{serverURL}/audiobookshelf/api/items/{id}/cover`

### Request Pattern
```swift
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

---

## Key Models

### Book
```swift
struct Book: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let authors: [Author]
    let narrators: [String]
    let genres: [String]
    let description: String
    let duration: TimeInterval
    let coverImageURL: String?
    let progress: Double
    let lastPlayedDate: Date?
}
```

### API Response Models (ABS prefix)
- `ABSLoginResponse`, `ABSLoginRequest` - Auth
- `ABSLibraryItemsResponse`, `ABSLibraryItem` - Library data
- `ABSUser` - User info with token

---

## tvOS-Specific Considerations

### Focus Management
- Use `@FocusState` for tracking focused elements
- Apply `.hoverEffect(.highlight)` for visual feedback
- Use `.focusSection()` for focus navigation
- Cards animate on focus (e.g., offset changes)

### UI Guidelines
- Large touch targets for Siri Remote
- Grid layouts with `LazyVGrid`
- Horizontal `HStack` layouts for forms
- `.scrollClipDisabled()` for edge-to-edge scrolling

### Remote Input
- Text input via tvOS keyboard
- Navigation via focus system
- Button actions via click

---

## Coding Conventions

### File Headers
```swift
//
//  FileName.swift
//  Noira
//
//  Created by Shalva Gegia on DD/MM/YYYY.
//
```

### Naming
- **Views**: `*View.swift` (e.g., `LibraryView.swift`)
- **Components**: Descriptive names (e.g., `SquareBookCover.swift`)
- **Services**: `*Service.swift` (e.g., `AuthenticationService.swift`)
- **API Models**: `ABS*` prefix (e.g., `ABSLoginResponse`)

### SwiftUI Previews
Include multiple preview variants:
```swift
#Preview("With Books") {
    BookGridView(books: Book.sampleBooks)
}

#Preview("Empty State") {
    BookGridView(books: [])
}
```

---

## Current Features (Implemented)
- ✅ Server authentication (login/logout)
- ✅ Library browsing with grid view
- ✅ Book detail view with cover, metadata, description
- ✅ Search with suggestions
- ✅ Settings screen
- ✅ Dynamic color extraction from book covers
- ✅ Persistent credentials storage

## Features In Progress / TODO
- ⏳ Audio playback (Now Playing view exists but incomplete)
- ⏳ Progress sync with Audiobookshelf
- ⏳ Chapter navigation
- ⏳ Playback controls
- ⏳ Sleep timer
- ⏳ Playback speed control
- ⏳ Multiple library support
- ⏳ Offline playback
- ⏳ Series grouping

---

## Development Tips

### Running the App
1. Open `Noira.xcodeproj` in Xcode
2. Select Apple TV simulator or device
3. Build and run (⌘R)

### Testing API
- Use a local or remote Audiobookshelf server
- Sample data available via `Book.sampleBooks` for previews

### Adding New Views
1. Create view in appropriate `Views/` subdirectory
2. Add to navigation in `RootView.swift` or `Destination.swift`
3. Include SwiftUI previews

### Adding API Endpoints
1. Add response models in `Models/ABS/`
2. Create or extend service in `Services/`
3. Handle errors with custom error enum

---

## Common Patterns to Follow

### Async Data Loading
```swift
.task {
    await service.fetchData()
}
```

### Loading States
```swift
if service.isLoading {
    ProgressView()
} else if let error = service.error {
    // Error state
} else {
    // Content
}
```

### Environment Object Injection
```swift
ContentView()
    .environmentObject(authService)
```

---

## Resources
- [Audiobookshelf API Docs](https://api.audiobookshelf.org/)
- [SwiftUI for tvOS](https://developer.apple.com/documentation/tvos-apps)
- [Human Interface Guidelines - tvOS](https://developer.apple.com/design/human-interface-guidelines/tvos)

