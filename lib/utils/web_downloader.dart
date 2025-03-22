// This file is only used in web builds
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;
import 'package:logging/logging.dart';

/// Web implementation of file downloads using package:web
///
/// This class provides the actual web implementation for downloads
class WebDownloaderImpl {
  static final _logger = Logger('WebDownloader');

  /// Registers the implementation of webDownload with the web-specific code
  static void registerWebImplementation() {
    // Override the stub implementation in js_util.dart
    // This function will only be called in web builds
    _logger.info('Registering web download implementation');
  }
}

/// Implementation of the download functionality using package:web
///
/// This function is called from js_util.dart and replaces the stub implementation
void webDownload(String url, String filename) {
  try {
    // Create an anchor element using package:web
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..setAttribute('download', filename)
      ..target = '_blank'
      ..style.display = 'none';

    // Add to the DOM
    web.document.body!.appendChild(anchor);

    // Trigger the download
    anchor.click();

    // Clean up
    anchor.remove();

    final logger = Logger('WebDownloader');
    logger.info('Download initiated for $filename');
  } catch (e) {
    final logger = Logger('WebDownloader');
    logger.warning('Failed to download file: $e');
  }
}
