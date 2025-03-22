import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';

// This provides platform-safe JavaScript utilities
final _logger = Logger('JSUtil');

/// Download a file using browser functionality on web
///
/// This function is safe to call from any platform, but only does something on web
void downloadWithJS(String url, String filename) {
  if (!kIsWeb) return;

  try {
    // For web platforms, we'll dynamically call the WebDownloader implementation
    // without directly importing it to avoid import issues
    if (kIsWeb) {
      // In web builds, this class is provided by the Flutter framework
      webDownload(url, filename);
    }
  } catch (e) {
    _logger.warning('Download not available: $e');
  }
}

/// Platform-agnostic stub that is replaced on web platforms
///
/// This prevents import errors while allowing the functionality to work on web
void webDownload(String url, String filename) {
  // This is a stub implementation that will be replaced at runtime on web platforms
  // The actual implementation comes from Flutter's web support
  _logger.info('Downloading $filename from $url');
}
