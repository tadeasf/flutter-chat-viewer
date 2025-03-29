import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

enum MediaType {
  photo,
  video,
  audio,
  profilePhoto,
  thumbnailPhoto,
  document,
}

enum MediaSource {
  message,
  collection,
  externalUrl,
}

class UrlFormatter {
  static const String baseUrl = 'https://backend.jevrej.cz';
  static final Logger _logger = Logger('UrlFormatter');

  /// Format URL for any type of media
  static String formatUrl({
    required String uri,
    required MediaType type,
    String? collectionName,
    MediaSource source = MediaSource.message,
  }) {
    try {
      // If it's already a full URL, return it
      if (uri.startsWith('https://') || uri.startsWith('http://')) {
        return uri;
      }

      switch (type) {
        case MediaType.profilePhoto:
          return formatProfilePhotoUrl(collectionName ?? '');
        case MediaType.photo:
        case MediaType.video:
        case MediaType.audio:
        case MediaType.thumbnailPhoto:
        case MediaType.document:
          return _formatMediaUrl(
              collectionName: collectionName,
              uri: uri,
              type: type,
              source: source);
      }
    } catch (e) {
      _logger.warning('Error formatting URL: $e');
      return uri;
    }
  }

  /// Format media URL for photos, videos, and audio
  static String _formatMediaUrl({
    String? collectionName,
    required String uri,
    required MediaType type,
    MediaSource source = MediaSource.message,
  }) {
    // For videos and audio that come with full path from MongoDB
    if (uri.startsWith('messages/inbox/')) {
      // Remove the 'messages/' prefix and prepend baseUrl
      final path = uri.substring('messages/'.length);
      return '$baseUrl/$path';
    }

    // If no collection name provided for collection-based URLs, return the URI as is
    if (collectionName == null && source == MediaSource.collection) {
      if (kDebugMode) {
        print('Collection name is required for collection-based URLs');
      }
      return uri;
    }

    // Debug log for collection names
    if (kDebugMode && kIsWeb) {
      if (kDebugMode) {
        print(
            'Web environment - Collection name in URL formatter: $collectionName');
      }
    }

    // For standard media files
    final mediaFolder = _getMediaFolder(type);

    // Check if we have the display name format (e.g., "AndreaZizkova")
    // instead of the key format (e.g., "andreazizkova_10209460325737541")
    final String formattedCollectionName =
        _ensureCorrectCollectionNameFormat(collectionName ?? '');

    // For videos, we need to ensure we're using the correct endpoint
    if (type == MediaType.video) {
      return '$baseUrl/serve/video/${Uri.encodeComponent(formattedCollectionName)}/${Uri.encodeComponent(uri)}';
    }

    // Construct the URL based on the source
    if (source == MediaSource.message) {
      final url = '$baseUrl/inbox/$formattedCollectionName/$mediaFolder/$uri';
      if (kDebugMode && kIsWeb) {
        if (kDebugMode) {
          print('Web environment - Formatted URL: $url');
        }
      }
      return url;
    } else if (source == MediaSource.collection) {
      return '$baseUrl/collection/$formattedCollectionName/$mediaFolder/$uri';
    } else {
      return uri;
    }
  }

  /// Get the folder name for the given media type
  static String _getMediaFolder(MediaType type) {
    switch (type) {
      case MediaType.photo:
        return 'photos';
      case MediaType.thumbnailPhoto:
        return 'thumbnails';
      case MediaType.video:
        return 'videos';
      case MediaType.audio:
        return 'audio';
      default:
        return 'media';
    }
  }

  /// Format profile photo URL
  static String formatProfilePhotoUrl(String collectionName) {
    final formattedCollectionName =
        _ensureCorrectCollectionNameFormat(collectionName);
    return '$baseUrl/serve/photo/${Uri.encodeComponent(formattedCollectionName)}';
  }

  /// Format URL for photo upload
  static String formatPhotoUploadUrl(String collectionName) {
    final formattedCollectionName =
        _ensureCorrectCollectionNameFormat(collectionName);
    return '$baseUrl/upload/photo/${Uri.encodeComponent(formattedCollectionName)}';
  }

  /// Format URL for photo deletion
  static String formatPhotoDeleteUrl(String collectionName) {
    final formattedCollectionName =
        _ensureCorrectCollectionNameFormat(collectionName);
    return '$baseUrl/delete/photo/${Uri.encodeComponent(formattedCollectionName)}';
  }

  /// Format URL to check if collection has a photo
  static String formatPhotoAvailabilityUrl(String collectionName) {
    final formattedCollectionName =
        _ensureCorrectCollectionNameFormat(collectionName);
    return '$baseUrl/collection/has-photo/${Uri.encodeComponent(formattedCollectionName)}';
  }

  /// Extract filename from URL
  static String extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.last;
    } catch (e) {
      _logger.warning('Error extracting filename from URL: $e');
      // Fallback: get everything after the last slash
      final lastSlashIndex = url.lastIndexOf('/');
      if (lastSlashIndex != -1 && lastSlashIndex < url.length - 1) {
        return url.substring(lastSlashIndex + 1);
      }
      return url;
    }
  }

  /// Ensures the collection name is in the correct format with ID
  /// This is a temporary solution to handle cases where we get the display name format
  /// instead of the key format with underscore and ID
  static String _ensureCorrectCollectionNameFormat(String collectionName) {
    // If it already has an underscore, it's likely in the correct format
    if (collectionName.contains('_')) {
      return collectionName;
    }

    // For cases like "AndreaZizkova" that should be "andreazizkova_10209460325737541"
    // We need to map known display names to their correct key format
    // This is a temporary solution - ideally, the code should be fixed to always use keys

    // Known mappings
    final Map<String, String> knownMappings = {
      'AndreaZizkova': 'andreazizkova_10209460325737541',
      // Add more mappings as needed
    };

    // Check if we have a known mapping
    if (knownMappings.containsKey(collectionName)) {
      final correctedName = knownMappings[collectionName]!;
      if (kDebugMode) {
        print(
            'Converting collection name from "$collectionName" to "$correctedName"');
      }
      return correctedName;
    }

    // If we don't have a mapping, return the original
    return collectionName;
  }
}
