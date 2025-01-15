# Meta Chat Viewer

A Flutter application for viewing and searching through Facebook Messenger chat history with advanced features.

## Building Locally

### Prerequisites

- Flutter SDK
- Java 17.0.13 (mise recommended for version management)
- macOS for building the macOS app

### Debug Build

```bash
./scripts/build-debug.sh
```

This will:

1. Clean the project
2. Get & upgrade dependencies
3. Build debug APK and macOS app
4. Copy builds to Desktop with versioning

### Release Build

```bash
./scripts/build-release.sh
```

This will:

1. Clean the project
2. Get & upgrade dependencies
3. Build release APK and macOS app
4. Copy builds to Desktop with versioning

Build outputs will be saved to:

- APK: `~/Desktop/meta-chat-viewer_{debug|release}_latest.apk`
- macOS: `~/Desktop/Meta Elysia_{debug|release}_latest.app`

## Features

- 📱 View and search through Facebook Messenger conversations
- 🔍 Cross-collection search functionality
- 📸 Support for photos, videos, and audio messages
- 🎨 Dark/Light theme support
- 🔄 Automatic retry mechanism for failed requests
- 📊 Collection statistics and message count visualization

## Setup

1. Create a `.env` file in the root directory:

    ```env
    X_API_KEY=your_api_key_here
    ```

2. Install dependencies:

    ```bash
    flutter pub get
    ```

3. Run the app:

    ```bash
    flutter run
    ```

## Architecture

The app uses:

- Flutter for the UI
- HTTP for API communication
- GitHub Actions for CI/CD
- Shared Preferences for local storage

## API Integration

The app communicates with a backend server at `backend.jevrej.cz` for:

- Fetching message collections
- Cross-collection search
- Media handling (photos, videos, audio)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

GPL-3.0
