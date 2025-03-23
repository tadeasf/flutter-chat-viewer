// This file is only used in web builds
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'js_bridge.dart';

/// Web implementation of file downloads
class WebDownloaderImpl {
  static final _logger = Logger('WebDownloader');

  /// Registers the implementation of webDownload with the web-specific code
  static void registerWebImplementation() {
    if (kIsWeb) {
      _logger.info('Registering web download implementation');
    }
  }
}

/// Implementation of the download functionality for web
/// This function is called from js_util.dart and replaces the stub implementation
void webDownload(String url, String filename) {
  if (!kIsWeb) return;

  try {
    final logger = Logger('WebDownloader');
    logger.info('Initiating download for $filename');

    // Use JS interop approach via JsBridge instead of direct web package
    // This delegates to the openInNewTab function which is safer and more compatible
    _downloadViaNewTab(url, filename);
  } catch (e) {
    final logger = Logger('WebDownloader');
    logger.warning('Failed to download file: $e');
  }
}

/// Uses a simpler approach by opening a new tab
/// Browser will handle the download when it receives proper content-disposition headers
void _downloadViaNewTab(String url, String filename) {
  if (!kIsWeb) return;

  // Use the openInNewTab function from JsBridge
  JsBridge.openInNewTab(url);
}
