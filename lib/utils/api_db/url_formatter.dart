class UrlFormatter {
  static const String baseUrl = 'https://backend.jevrej.cz';

  static String formatMediaUrl({
    required String collectionName,
    required String uri,
    required MediaType type,
  }) {
    // If it's already a full URL, return it
    if (uri.startsWith('https://')) {
      return uri;
    }

    // For videos and audio that come with full path from MongoDB
    if (uri.startsWith('messages/inbox/')) {
      // Remove the 'messages/' prefix and prepend baseUrl
      final path = uri.substring('messages/'.length);
      return '$baseUrl/$path';
    }

    // For standard media files (mainly photos)
    final mediaFolder = _getMediaFolder(type);
    return '$baseUrl/inbox/$collectionName/$mediaFolder/$uri';
  }

  static String _getMediaFolder(MediaType type) {
    switch (type) {
      case MediaType.photo:
        return 'photos';
      case MediaType.video:
        return 'videos';
      case MediaType.audio:
        return 'audio';
    }
  }

  static String formatProfilePhotoUrl(String collectionName) {
    return '$baseUrl/serve/photo/${Uri.encodeComponent(collectionName)}';
  }
}

enum MediaType {
  photo,
  video,
  audio,
}
