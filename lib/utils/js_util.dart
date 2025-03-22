import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:logging/logging.dart';

// Use conditional import for web-specific functionality
import 'dart:js_interop' if (dart.library.io) 'js_util_stub.dart';

final _logger = Logger('JSUtil');

// Web-specific API key access
/// Gets the API key from window.FLUTTER_ENV.X_API_KEY
String? getApiKey() {
  if (!kIsWeb) return null;
  
  try {
    final env = _getFlutterEnv();
    if (env == null) return null;
    
    // Access the X_API_KEY property
    final apiKey = _getProperty(env, 'X_API_KEY');
    return apiKey;
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
    _openWindow(url, '_blank');
    _logger.info('Opened in new tab: $url');
  } catch (e) {
    _logger.warning('Failed to open in new tab: $e');
  }
}

// JS interop definitions - these only work on web
@JS('window.FLUTTER_ENV')
external JSObject? get _flutterEnvJS;

@JS('window.open')
external JSAny _openWindow(String url, String target);

// Helper functions with null safety for non-web platforms
JSObject? _getFlutterEnv() {
  if (!kIsWeb) return null;
  return _flutterEnvJS;
}

/// Helper function to safely get a property from a JSObject
String? _getProperty(JSObject obj, String prop) {
  if (!kIsWeb) return null;
  
  try {
    // Access the property dynamically
    final result = _getJsProperty(obj, prop);
    return result?.toString();
  } catch (e) {
    if (kDebugMode) {
      print('Error getting property $prop: $e');
    }
    return null;
  }
}

@JS('Reflect.get')
external JSAny? _getJsProperty(JSObject obj, String prop);