import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/api_db/api_service.dart';
import '../utils/api_db/url_formatter.dart' as url_formatter;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

// Include the generated file
part 'file_store.g.dart';

/// Enum for media types
enum MediaType { image, video, audio, document }

// This is the class used by rest of the codebase
class FileStore = FileStoreBase with _$FileStore;

// The store class
abstract class FileStoreBase with Store {
  final Logger _logger = Logger('FileStore');
  final String baseUrl = 'https://backend.jevrej.cz';

  FileStoreBase();

  // Cache directories
  Directory? _cacheDir;
  bool _initialized = false;

  // Get API key from ApiService
  String get apiKey => ApiService.apiKey;

  // Observable maps to store URLs and file paths
  @observable
  ObservableMap<String, String?> imagePaths = ObservableMap<String, String?>();

  @observable
  ObservableMap<String, String?> videoPaths = ObservableMap<String, String?>();

  @observable
  ObservableMap<String, String?> audioPaths = ObservableMap<String, String?>();

  // Observable for loading states
  @observable
  ObservableMap<String, bool> loadingStates = ObservableMap<String, bool>();

  // Observable for error states
  @observable
  ObservableMap<String, bool> errorStates = ObservableMap<String, bool>();

  @observable
  bool isLoading = false;

  @observable
  ObservableMap<String, dynamic> cache = ObservableMap<String, dynamic>();

  // Initialize the cache directory
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      _cacheDir = await getTemporaryDirectory();
      _initialized = true;
    } catch (e) {
      _logger.warning('Error initializing cache directory: $e');
      _initialized = false;
    }
  }

  // Convert our MediaType to the UrlFormatter MediaType
  url_formatter.MediaType _convertMediaType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return url_formatter.MediaType.photo;
      case MediaType.video:
        return url_formatter.MediaType.video;
      case MediaType.audio:
        return url_formatter.MediaType.audio;
      case MediaType.document:
        return url_formatter.MediaType.document;
    }
  }

  // Format a media URL using the UrlFormatter
  String formatMediaUrl({
    required String uri,
    required MediaType type,
    String? collectionName,
    url_formatter.MediaSource source = url_formatter.MediaSource.message,
  }) {
    return url_formatter.UrlFormatter.formatUrl(
      uri: uri,
      type: _convertMediaType(type),
      collectionName: collectionName,
      source: source,
    );
  }

  // Get file path based on media type
  String? _getFilePath(String url, MediaType type) {
    switch (type) {
      case MediaType.image:
        return imagePaths[url];
      case MediaType.video:
        return videoPaths[url];
      case MediaType.audio:
        return audioPaths[url];
      case MediaType.document:
        return null; // Documents are not cached locally
    }
  }

  // Set file path based on media type
  @action
  void _setFilePath(String url, String? path, MediaType type) {
    switch (type) {
      case MediaType.image:
        imagePaths[url] = path;
        break;
      case MediaType.video:
        videoPaths[url] = path;
        break;
      case MediaType.audio:
        audioPaths[url] = path;
        break;
      case MediaType.document:
        // Documents are not cached locally
        break;
    }
  }

  // Action to fetch and cache a file
  @action
  Future<String?> getFile(String uri, MediaType type,
      {String? collectionName,
      url_formatter.MediaSource source =
          url_formatter.MediaSource.message}) async {
    // Format the URL using UrlFormatter
    final url = formatMediaUrl(
      uri: uri,
      type: type,
      collectionName: collectionName,
      source: source,
    );

    // Return from cache if available
    if (_getFilePath(url, type) != null) {
      final path = _getFilePath(url, type);
      if (path != null && File(path).existsSync()) {
        return path;
      }
    }

    // Ensure the cache directory is initialized
    await _ensureInitialized();
    if (!_initialized) {
      errorStates[url] = true;
      return null;
    }

    // Set loading state
    loadingStates[url] = true;
    errorStates[url] = false;

    try {
      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${timestamp}_${url.hashCode}';
      final extension = _getExtension(url, type);
      final filePath = '${_cacheDir!.path}/$filename$extension';

      // Fetch the file
      final response =
          await http.get(Uri.parse(url), headers: ApiService.headers);

      if (response.statusCode == 200) {
        // Write the file to the cache
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Update the store
        _setFilePath(url, filePath, type);
        loadingStates[url] = false;

        return filePath;
      } else {
        // Error occurred
        _logger.warning('Failed to fetch file: ${response.statusCode}');
        errorStates[url] = true;
        loadingStates[url] = false;
        return null;
      }
    } catch (e) {
      _logger.warning('Error fetching file: $e');
      errorStates[url] = true;
      loadingStates[url] = false;
      return null;
    }
  }

  // Action to download media directly from a message
  @action
  Future<bool> downloadMediaFromMessage(BuildContext context,
      Map<String, dynamic> message, String mediaUri, MediaType type) async {
    try {
      final collectionName =
          message['collectionName'] ?? message['collection_name'];
      if (collectionName == null) {
        throw Exception('Collection name not found in message');
      }

      final url = formatMediaUrl(
        uri: mediaUri,
        type: type,
        collectionName: collectionName,
        source: url_formatter.MediaSource.message,
      );

      return await downloadFile(context, url, type);
    } catch (e) {
      _logger.warning('Error downloading media from message: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Action to download photo from a photo object
  @action
  Future<bool> downloadPhoto(
    BuildContext context,
    Map<String, dynamic> photo,
    String collectionName,
  ) async {
    try {
      if (photo['uri'] == null) {
        throw Exception('Photo URI not found');
      }

      final url = formatMediaUrl(
        uri: photo['uri'],
        type: MediaType.image,
        collectionName: collectionName,
        source: url_formatter.MediaSource.message,
      );

      return await downloadFile(context, url, MediaType.image);
    } catch (e) {
      _logger.warning('Error downloading photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Action to download file to device storage or gallery
  @action
  Future<bool> downloadFile(
      BuildContext context, String url, MediaType type) async {
    try {
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading file...')),
      );

      // Fetch the file either from cache or from network
      final bytes = await _getFileBytes(url, type);
      if (bytes == null) {
        throw Exception('Failed to get file data');
      }

      // Use the UrlFormatter to extract the filename
      final fileName = url_formatter.UrlFormatter.extractFilename(url);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithoutExt = fileName.split('.').first;
      final extension = _getExtension(url, type);
      final saveFileName = '${fileNameWithoutExt}_$timestamp$extension';

      if (kIsWeb) {
        // For web platform, we can only show a message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File downloading in browser')),
          );
        }
        // Web browser handles the download
        return true;
      } else if (Platform.isMacOS || Platform.isLinux) {
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception('Cannot access downloads directory');
        }

        final filePath =
            '${directory.path}${Platform.pathSeparator}$saveFileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to ${file.path}')),
          );
        }
        return true;
      } else {
        // For mobile platforms, save to gallery
        final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(bytes),
          quality: 100,
          name: saveFileName,
        );

        if (!context.mounted) return false;

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File saved to gallery')),
          );
          return true;
        } else {
          throw Exception('Failed to save file to gallery');
        }
      }
    } catch (e) {
      _logger.warning('Error downloading file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Helper to get file bytes (from cache or network)
  Future<List<int>?> _getFileBytes(String url, MediaType type) async {
    // Check cache first
    final cachedPath = _getFilePath(url, type);
    if (cachedPath != null && File(cachedPath).existsSync()) {
      return await File(cachedPath).readAsBytes();
    }

    // If not in cache, fetch from network
    final response =
        await http.get(Uri.parse(url), headers: ApiService.headers);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    return null;
  }

  // Helper to get extension based on URL and type
  String _getExtension(String url, MediaType type) {
    // Try to extract extension from URL
    try {
      return '.${url_formatter.UrlFormatter.extractFilename(url).split('.').last}';
    } catch (e) {
      // Default extensions if we can't extract from URL
      switch (type) {
        case MediaType.image:
          return '.jpg';
        case MediaType.video:
          return '.mp4';
        case MediaType.audio:
          return '.aac';
        case MediaType.document:
          return '.pdf';
      }
    }
  }

  // Action to clear cache for a specific URL
  @action
  Future<void> clearCache(String url, MediaType type) async {
    final path = _getFilePath(url, type);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        _logger.warning('Error deleting file: $e');
      }
    }

    // Remove from maps
    _setFilePath(url, null, type);
    loadingStates.remove(url);
    errorStates.remove(url);
  }

  // Action to clear all cache for a specific type
  @action
  Future<void> clearTypeCache(MediaType type) async {
    ObservableMap<String, String?> paths;

    switch (type) {
      case MediaType.image:
        paths = imagePaths;
        break;
      case MediaType.video:
        paths = videoPaths;
        break;
      case MediaType.audio:
        paths = audioPaths;
        break;
      case MediaType.document:
        // Documents are not cached locally
        return;
    }

    // Delete all files of this type
    for (final entry in paths.entries) {
      if (entry.value != null) {
        try {
          final file = File(entry.value!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          _logger.warning('Error deleting file: $e');
        }
      }
    }

    // Clear maps for this type
    switch (type) {
      case MediaType.image:
        imagePaths.clear();
        break;
      case MediaType.video:
        videoPaths.clear();
        break;
      case MediaType.audio:
        audioPaths.clear();
        break;
      case MediaType.document:
        // No map to clear for documents
        break;
    }

    // Remove loading and error states for these URLs
    final urlsToRemove = paths.keys.toList();
    for (final url in urlsToRemove) {
      loadingStates.remove(url);
      errorStates.remove(url);
    }
  }

  // Action to clear all cache
  @action
  Future<void> clearAllCache() async {
    // Delete all cached files
    if (_initialized && _cacheDir != null) {
      try {
        final directory = _cacheDir!;
        final files = directory.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      } catch (e) {
        _logger.warning('Error clearing cache directory: $e');
      }
    }

    // Clear all maps
    imagePaths.clear();
    videoPaths.clear();
    audioPaths.clear();
    loadingStates.clear();
    errorStates.clear();
  }

  // Helper to get loading state
  bool isFileLoading(String url) {
    return loadingStates[url] ?? false;
  }

  // Helper to get error state
  bool hasError(String url) {
    return errorStates[url] ?? false;
  }

  // Helper to check if a file is cached
  bool isCached(String url, MediaType type) {
    final path = _getFilePath(url, type);
    if (path == null) return false;

    return File(path).existsSync();
  }

  // Action to prefetch a file without returning it
  @action
  Future<void> prefetchFile(String url, MediaType type) async {
    if (isCached(url, type)) return;

    await getFile(url, type);
  }

  // Helper to get cache size
  Future<int> getCacheSize() async {
    if (!_initialized || _cacheDir == null) return 0;

    try {
      int totalSize = 0;
      final directory = _cacheDir!;
      final files = directory.listSync();

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      _logger.warning('Error calculating cache size: $e');
      return 0;
    }
  }

  // Format cache size for display
  Future<String> formatCacheSize() async {
    final size = await getCacheSize();
    return _formatBytes(size);
  }

  // Helper to format bytes
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if media is available for a collection
  Future<bool> checkMediaAvailability(
      String collectionName, MediaType type) async {
    try {
      final encodedName = Uri.encodeComponent(collectionName);
      final response = await http.head(
        Uri.parse('$baseUrl/serve/${_getMediaTypeString(type)}/$encodedName'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Error checking media availability: $e');
      return false;
    }
  }

  /// Get URL for media
  String getMediaUrl(String collectionName, String mediaId, MediaType type) {
    final encodedName = Uri.encodeComponent(collectionName);
    final encodedMediaId = Uri.encodeComponent(mediaId);

    return '$baseUrl/serve/${_getMediaTypeString(type)}/$encodedName/$encodedMediaId';
  }

  /// Add method to delete media (needed by ProfilePhotoStore)
  Future<bool> deleteMedia(String url, MediaType type) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: ApiService.headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _logger.warning('Error deleting media: $e');
      return false;
    }
  }

  /// Helper to convert MediaType to string
  String _getMediaTypeString(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'photo';
      case MediaType.video:
        return 'video';
      case MediaType.audio:
        return 'audio';
      case MediaType.document:
        return 'document';
    }
  }
}
