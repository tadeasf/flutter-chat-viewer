import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:logging/logging.dart';
import 'js_bridge.dart';

// Use a different approach for JS interop that's more compatible

final _logger = Logger('JSUtil');

// Web-specific API key access
/// Gets the API key from window.FLUTTER_ENV.X_API_KEY
String? getApiKey() {
  if (!kIsWeb) return null;

  try {
    final apiKey = JsBridge.getWindowProperty('FLUTTER_ENV.X_API_KEY');
    return apiKey?.toString();
  } catch (e) {
    if (kDebugMode) {
      print('Error accessing window.FLUTTER_ENV: $e');
    }
    return null;
  }
}

/// Download a file using browser functionality on web
/// This function is safe to call from any platform, but only does something on web
void downloadWithJS(String url, String filename) {
  if (!kIsWeb) return;

  try {
    openInNewTab(url);
    _logger.info('Opening $filename in new tab from $url');
  } catch (e) {
    _logger.warning('Download not available: $e');
  }
}

/// Open URL in a new tab (web only)
void openInNewTab(String url) {
  if (!kIsWeb) return;

  try {
    JsBridge.openInNewTab(url);
    _logger.info('Opened in new tab: $url');
  } catch (e) {
    _logger.warning('Failed to open in new tab: $e');
  }
}
