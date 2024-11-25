# Meta Chat Viewer

A Flutter application for viewing and searching through Facebook Messenger chat history with advanced features.

## Features

- 📱 View and search through Facebook Messenger conversations
- 🔍 Cross-collection search functionality
- 📸 Support for photos, videos, and audio messages
- 🎨 Dark/Light theme support
- 🔄 Automatic retry mechanism for failed requests
- 📊 Collection statistics and message count visualization

## Setup

- Create a `.env` file in the root directory with:

```env
X_API_KEY=your_api_key_here
```

- Install dependencies:

```bash
flutter pub get
```

- Run the app:

```bash
flutter run
```

## Building

To build a release APK:

```bash
flutter build apk --release
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
