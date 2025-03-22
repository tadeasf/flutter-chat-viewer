# Meta Chat Viewer

A Flutter application for viewing and searching through Facebook Messenger chat history with advanced features.

## Building the Application

### Important Build Instructions

- **Android APK**:
  ```bash
  flutter build apk --release
  ```

- **Linux (Arch)**:
  ```bash
  flutter build linux --release
  sudo ./install.sh  # Important: Kill any running instances first or it will error out
  ```

- **Web**:
  ```bash
  X_API_KEY={api_key} docker compose up -d --build
  ```
  **Note**: Use Modheader extension and include x-api-key header to get image access (without it you'll only get messages)

### Prerequisites

- Flutter SDK
- Java 17.0.13 (mise recommended for version management)
- For web build: Docker and Docker Compose

## Features

- 📱 View and search through Facebook Messenger conversations
- 🔍 Cross-collection search functionality
- 📸 Support for photos, videos, and audio messages
- 🎨 Dark/Light theme support
- 🔄 Automatic retry mechanism for failed requests
- 📊 Collection statistics and message count visualization

## Setup

Create a `.env` file in the root directory:

```env
X_API_KEY=your_api_key_here
```

## Architecture

The app uses Flutter for the UI, HTTP for API communication, and communicates with a backend server at `backend.jevrej.cz` for fetching message collections, cross-collection search, and media handling.

## License

GPL-3.0
