# PromptBuddy Mobile App

A Flutter mobile application for browsing, searching, creating, editing, organizing, and sharing text prompts.

## Features

### Core Functionality
- ✅ **Offline-first architecture** - Works without internet, syncs when online
- ✅ **Global search** - Full-text search across prompts with debouncing
- ✅ **Category organization** - Browse prompts by categories
- ✅ **Variable parsing** - Automatically detects {{variables}} in prompts
- ✅ **Favorites system** - Mark prompts as favorites for quick access
- ✅ **Usage tracking** - Track how often prompts are used
- ✅ **Native sharing** - Share prompts using platform share sheet

### User Interface
- ✅ **Material Design 3** - Modern, accessible design system
- ✅ **Light/Dark themes** - Automatic or manual theme switching
- ✅ **Text scaling** - Support for large text and accessibility
- ✅ **Responsive layout** - Works on phones and tablets
- ✅ **Smooth navigation** - Declarative routing with animations

### Data Management
- ✅ **Local SQLite database** - Fast offline storage with FTS
- ✅ **Background sync** - Automatic synchronization with API
- ✅ **Conflict resolution** - Handle simultaneous edits gracefully
- ✅ **Import/Export** - JSON import/export for data portability
- ✅ **Delta sync** - Only sync changed data for efficiency

## Architecture

### State Management
- **Riverpod** - Modern, compile-safe state management
- **Provider pattern** - Clean separation of concerns
- **Reactive UI** - UI updates automatically with state changes

### Data Layer
- **Repository pattern** - Abstract data sources
- **Local-first** - SQLite database with full-text search
- **API integration** - REST API communication
- **Sync service** - Background synchronization

### Navigation
- **GoRouter** - Declarative routing with deep links
- **Type-safe routes** - Compile-time route validation
- **Deep linking** - Direct links to specific prompts/categories

## Quick Start

### Prerequisites
- Flutter SDK 3.16+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK / iOS SDK

### Installation

1. **Get dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate code:**
   ```bash
   flutter packages pub run build_runner build
   ```

3. **Run the app:**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Configuration

The app connects to the PromptBuddy API service. Update the base URL in `lib/config/app_config.dart`:

```dart
static const String baseUrl = 'http://your-api-server:3001/api';
```

## Project Structure

```
lib/
├── config/           # App configuration and routing
├── models/           # Data models and JSON serialization
├── providers/        # Riverpod state providers
├── screens/          # UI screens and pages
├── services/         # Business logic and data services
├── utils/            # Utility functions and helpers
└── widgets/          # Reusable UI components
```

## Key Services

### DatabaseService
- SQLite database management
- Full-text search with FTS5
- Local data persistence
- CRUD operations

### ApiService
- REST API communication
- HTTP client with interceptors
- Error handling and retries
- Response parsing

### SyncService
- Background synchronization
- Conflict resolution
- Delta sync optimization
- Network connectivity handling

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## Building

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

## Features in Detail

### Offline-First Architecture
- Works completely offline with local SQLite database
- Background sync when network is available
- Conflict resolution with last-write-wins strategy
- Smart delta sync to minimize data transfer

### Search and Filtering
- Full-text search across titles, content, and tags
- Real-time search with debouncing
- Tag-based filtering with include/exclude modes
- Sort by date, usage, or alphabetical

### Variable System
- Automatic detection of {{variable}} syntax
- Preview rendered prompts with filled variables
- Variable list management
- Template sharing with or without variables

### Sync and Data Management
- Automatic background sync every 15 minutes
- Manual sync trigger in settings
- Wi-Fi only sync option for data savings
- Import/export JSON for backup and sharing

## Customization

### Themes
- Modify `lib/providers/theme_provider.dart` for custom themes
- Uses FlexColorScheme for consistent Material Design 3 theming
- Support for custom color schemes and branding

### API Configuration
- Update `lib/config/app_config.dart` for API endpoints
- Modify sync intervals and retry logic
- Configure offline behavior preferences

## Performance

### Optimizations
- Lazy loading with pagination
- Image caching and optimization
- Database indexing for fast search
- Efficient state management with Riverpod

### Memory Management
- Proper disposal of controllers and streams
- Image memory caching limits
- Database connection pooling

## Accessibility

- Screen reader support
- High contrast themes
- Large text support
- Semantic labels and focus management
- Keyboard navigation support

## Security

- No sensitive data stored locally
- Secure HTTP communication
- Input validation and sanitization
- No hardcoded credentials

## License

MIT License - see LICENSE file for details.