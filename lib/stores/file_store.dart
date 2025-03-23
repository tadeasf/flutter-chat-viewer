import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/api_db/api_service.dart';
import 'package:http/http.dart' as http;

// Include the generated file
part 'file_store.g.dart';

// This is the class used by rest of the codebase
class FileStore = FileStoreBase with _$FileStore;

enum MediaType { image, video, audio }

// The store class
abstract class FileStoreBase with Store {
  final Logger _logger = Logger('FileStore');

  // Cache directories
  Directory? _cacheDir;
  bool _initialized = false;

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

  // Get file path based on media type
  String? _getFilePath(String url, MediaType type) {
    switch (type) {
      case MediaType.image:
        return imagePaths[url];
      case MediaType.video:
        return videoPaths[url];
      case MediaType.audio:
        return audioPaths[url];
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
    }
  }

  // Action to fetch and cache a file
  @action
  Future<String?> getFile(String url, MediaType type) async {
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

  // Helper to get extension based on URL and type
  String _getExtension(String url, MediaType type) {
    // Try to extract extension from URL
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;
      if (lastSegment.contains('.')) {
        return '.${lastSegment.split('.').last}';
      }
    }

    // Default extensions if we can't extract from URL
    switch (type) {
      case MediaType.image:
        return '.jpg';
      case MediaType.video:
        return '.mp4';
      case MediaType.audio:
        return '.aac';
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
  bool isLoading(String url) {
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
}
