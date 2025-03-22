// This file is only used in web builds
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:logging/logging.dart';
import 'api_db/api_service.dart';
import 'package:web/web.dart';

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
    final logger = Logger('WebDownloader');

    // Create an XMLHttpRequest to fetch with headers
    final xhr = XMLHttpRequest();
    xhr.open('GET', url);
    xhr.responseType = 'blob';
    xhr.setRequestHeader('x-api-key', ApiService.apiKey);

    xhr.onLoad.listen((event) {
      if (xhr.status == 200) {
        final blob = xhr.response as Blob;
        final blobUrl = URL.createObjectURL(blob);

        // Create an anchor element using package:web
        final anchor = document.createElement('a') as HTMLAnchorElement
          ..href = blobUrl
          ..download = filename
          ..target = '_blank'
          ..style.display = 'none';

        // Add to the DOM
        document.body!.appendChild(anchor);

        // Trigger the download
        anchor.click();

        // Clean up
        anchor.remove();
        URL.revokeObjectURL(blobUrl);

        logger.info('Download initiated for $filename');
      } else {
        logger.warning('Failed to download file: HTTP ${xhr.status}');
      }
    });

    xhr.onError.listen((event) {
      logger.warning('XHR error during download: $event');
    });

    xhr.send();
  } catch (e) {
    final logger = Logger('WebDownloader');
    logger.warning('Failed to download file: $e');
  }
}
