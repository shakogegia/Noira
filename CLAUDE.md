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
│   └── ContentView.swift        # Root view with auth routing & shared services
├── Models/                       # Data models
│   ├── Book.swift               # Core Book model with Author, Serie, metadata
│   ├── Library.swift            # Library model
│   ├── SampleData.swift         # Mock data for previews
│   └── ABS/                     # Audiobookshelf API models
│       ├── ABSAuth.swift        # Login request/response models
│       ├── ABSLibrary.swift     # Library API response models
│       └── ABSUser.swift        # User model
├── Navigation/
│   └── Destination.swift        # Navigation destinations enum
├── Services/                     # Business logic & networking
│   ├── ABSLibraryService.swift  # Library fetching service (shared)
│   ├── AuthenticationService.swift # Auth handling (shared)
│   ├── UserDefaultsService.swift   # Persistent storage
│   └── Mappers/
│       └── ABSLibraryItemMapper.swift # API to domain model transformation
├── Utilities/
│   ├── ImageColorExtractor.swift # Centralized color extraction utility
│   └── Extensions/
│       ├── Color+Extensions.swift
│       ├── String+URLExtensions.swift # URL normalization
│       ├── UIImage+Extensions.swift   # Color extraction from images
│       ├── View+Extensions.swift
│       └── View+GradientBackground.swift # Reusable gradient modifier
└── Views/
    ├── RootView.swift           # TabView with per-tab NavigationStacks
    ├── Authentication/
    │   └── LoginView.swift      # Server login form
    ├── Book/
    │   └── BookDetailView.swift # Book detail page with series info
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
            ├── BrandingView.swift    # Reusable branding component
            └── SquareBookCover.swift # AsyncImage cover component
```

---

## Architecture & Patterns

### State Management
- **`@StateObject`**: For owning observable objects (used in ContentView for service creation)
- **`@EnvironmentObject`**: For sharing services across view hierarchy
  - `AuthenticationService` - shared authentication state
  - `ABSLibraryService` - shared library data (prevents duplicate network requests)
- **`@Published`**: For reactive properties in services
- **`@MainActor`**: Used on services that update UI state

### Shared Service Pattern
Services are created once in `ContentView` and injected throughout the app via `@EnvironmentObject`:

```swift
// ContentView.swift - Create shared instances
@StateObject private var authService = AuthenticationService()
@StateObject private var absLibraryService = ABSLibraryService()

var body: some View {
    RootView()
        .environmentObject(authService)
        .environmentObject(absLibraryService)
}

// Child views - Access shared instances
struct LibraryView: View {
    @EnvironmentObject var absLibraryService: ABSLibraryService
    // ...
}
```

### Services Pattern
Services are `ObservableObject` classes that handle:
- Network requests to Audiobookshelf API
- State management (`isLoading`, `@Published var error`, data)
- Delegates data transformation to Mapper classes

```swift
@MainActor
class ABSLibraryService: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: ABSLibraryError?

    func fetchLibraryItems() async {
        // ... fetch from API ...
        books = ABSLibraryItemMapper.mapToBooks(from: response.results, serverURL: serverURL)
    }
}
```

### Mapper Pattern
Data transformation is separated into dedicated mapper classes:
- **Purpose**: Convert API models to domain models
- **Location**: `Services/Mappers/`
- **Benefits**: Cleaner services, easier testing, single responsibility

```swift
struct ABSLibraryItemMapper {
    static func mapToBooks(from items: [ABSLibraryItem], serverURL: String) -> [Book] {
        // Transform API models to domain Book models
        // Extract metadata (series, authors, narrators, etc.)
    }
}
```

### Navigation (tvOS-Specific)
- **Pattern**: `NavigationStack` inside each tab that needs navigation
- **Important**: Do NOT wrap TabView with NavigationStack - each tab needs its own
- Type-safe navigation with `Destination` enum
- `NavigationLink(value:)` pattern for programmatic navigation

```swift
// Correct pattern for tvOS
TabView {
    NavigationStack {
        LibraryView()
            .navigationDestination(for: Destination.self) { destination in
                // Handle navigation
            }
    }
    .tabItem { Text("Library") }

    NavigationStack {
        SearchView()
            .navigationDestination(for: Destination.self) { destination in
                // Handle navigation
            }
    }
    .tabItem { Text("Search") }
}
```

### Error Handling
- **Standard Pattern**: `@Published var error` in services
- Custom error enums conforming to `LocalizedError`
- Each service has its own error type (e.g., `AuthenticationError`, `ABSLibraryError`)
- Errors provide user-friendly descriptions via `errorDescription`
- Views observe errors and display alerts

```swift
// Service
@Published var error: ABSLibraryError?

func fetchData() async {
    error = nil
    // ... on failure:
    error = .networkError
}

// View
.alert("Error", isPresented: .constant(service.error != nil)) {
    Button("OK") { service.error = nil }
} message: {
    if let error = service.error {
        Text(error.localizedDescription)
    }
}
```

### Reusable Utilities
- **ImageColorExtractor**: Centralized color extraction from book covers
- **ViewModifiers**: Reusable UI modifiers (e.g., `DynamicGradientBackground`)
- **Extensions**: String URL normalization, UIImage color extraction, etc.

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
    let subtitle: String?           // NEW: Book subtitle
    let authors: [Author]
    let narrators: [String]
    let genres: [String]
    let description: String
    let duration: TimeInterval
    let coverImageURL: String?
    let progress: Double
    let lastPlayedDate: Date?
    let addedAt: Date?              // NEW: When book was added to library
    let publisher: String?          // NEW: Publisher name
    let publishedYear: String?      // NEW: Publication year
    let series: Serie?              // NEW: Series information
}
```

### Serie
```swift
struct Serie: Codable, Hashable {
    let id: String        // Generated from series name
    let name: String      // Series name (e.g., "The Lord of the Rings")
    let sequence: String  // Book's position in series (e.g., "1", "2.5")
}
```

### Author
```swift
struct Author: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}
```

### Library
```swift
struct Library: Codable, Identifiable, Hashable {
    let id: String  // Changed from Int to match API response
    let name: String
}
```

### API Response Models (ABS prefix)
- `ABSLoginResponse`, `ABSLoginRequest` - Auth
- `ABSLibraryItemsResponse`, `ABSLibraryItem` - Library data
- `ABSUser` - User info with token

**Note**: API models (with `ABS` prefix) are transformed to domain models (Book, Author, Serie) by mapper classes.

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
- ✅ Dynamic color extraction from book covers (centralized utility)
- ✅ Persistent credentials storage
- ✅ Series metadata extraction and display
- ✅ Publisher and publication year metadata
- ✅ Shared service architecture (no duplicate network requests)

## Features In Progress / TODO
- ⏳ Audio playback (Now Playing view exists but incomplete)
- ⏳ Progress sync with Audiobookshelf
- ⏳ Chapter navigation
- ⏳ Playback controls
- ⏳ Sleep timer
- ⏳ Playback speed control
- ⏳ Multiple library support
- ⏳ Offline playback
- ⏳ Series-based browsing/filtering

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

### Shared Service Access
Always use `@EnvironmentObject` to access shared services - never create new instances:

```swift
// ✅ CORRECT - Access shared instance
struct LibraryView: View {
    @EnvironmentObject var absLibraryService: ABSLibraryService
}

// ❌ WRONG - Creates duplicate instance
struct LibraryView: View {
    @StateObject private var absLibraryService = ABSLibraryService()
}
```

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

### Data Transformation (Mapper Pattern)
Keep services clean by delegating transformation to mappers:

```swift
// In Service
func fetchLibraryItems() async {
    let response = try JSONDecoder().decode(ABSLibraryItemsResponse.self, from: data)
    books = ABSLibraryItemMapper.mapToBooks(from: response.results, serverURL: serverURL)
}

// In Mapper
struct ABSLibraryItemMapper {
    static func mapToBooks(from items: [ABSLibraryItem], serverURL: String) -> [Book] {
        // Complex transformation logic here
    }
}
```

### URL Normalization
Always normalize server URLs before use:

```swift
let normalizedURL = serverURL.normalizedServerURL()
// Removes trailing slashes and whitespace
```

### Color Extraction
Use centralized ImageColorExtractor utility:

```swift
.task {
    let colors = await ImageColorExtractor.extractColors(from: book.coverImageURL)
    prominentColor = colors.prominent ?? .clear
    vibrantColor = colors.vibrant ?? .clear
    secondaryColor = colors.secondary ?? .clear
}
```

### Reusable UI with ViewModifiers
Create ViewModifiers for repeated UI patterns:

```swift
// Definition
struct DynamicGradientBackground: ViewModifier {
    let colors: [Color]
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: colors), ...)
            content
        }
    }
}

extension View {
    func dynamicGradientBackground(colors: [Color]) -> some View {
        modifier(DynamicGradientBackground(colors: colors))
    }
}

// Usage
SomeView()
    .dynamicGradientBackground(colors: [color1, color2, color3])
```

### tvOS Navigation Setup
Each tab needs its own NavigationStack:

```swift
// ✅ CORRECT - NavigationStack per tab
TabView {
    NavigationStack {
        LibraryView()
            .navigationDestination(for: Destination.self) { ... }
    }
    .tabItem { Text("Library") }
}

// ❌ WRONG - Wrapping entire TabView
NavigationStack {
    TabView {
        LibraryView()
    }
    .navigationDestination(for: Destination.self) { ... }
}
```

### Environment Object Injection
```swift
ContentView()
    .environmentObject(authService)
    .environmentObject(absLibraryService)
```

---

## Architecture Decisions & Refactoring History

### December 2025 Refactoring
A comprehensive refactoring was completed to improve code quality and architecture before implementing remaining features:

**Issues Resolved**:
1. **Duplicate Service Instances** - Fixed duplicate ABSLibraryService instances causing duplicate network requests
2. **Code Duplication** - Removed ~300 lines of duplicated code across the codebase
3. **Inconsistent Patterns** - Standardized error handling, navigation, and state management
4. **Missing Metadata** - Implemented series, subtitle, publisher, and publication year support
5. **Navigation Issues** - Fixed tvOS-specific navigation pattern

**Key Changes**:
- Introduced shared service pattern via @EnvironmentObject
- Created mapper classes for data transformation (ABSLibraryItemMapper)
- Extracted utilities (ImageColorExtractor, URL normalization, gradient backgrounds)
- Created reusable components (BrandingView)
- Fixed Library.id type mismatch (Int → String)
- Removed empty ABSService base class
- Removed HomeView (unused feature)
- Implemented proper tvOS navigation (NavigationStack per tab)

**Benefits**:
- 50% reduction in network requests (shared services)
- Cleaner, more maintainable codebase
- Consistent patterns throughout
- Better separation of concerns
- Full metadata extraction from API

---

## Resources
- [Audiobookshelf API Docs](https://api.audiobookshelf.org/)
- [SwiftUI for tvOS](https://developer.apple.com/documentation/tvos-apps)
- [Human Interface Guidelines - tvOS](https://developer.apple.com/design/human-interface-guidelines/tvos)

