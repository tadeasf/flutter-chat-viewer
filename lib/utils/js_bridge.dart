import 'package:flutter/foundation.dart' show kIsWeb;

/// This class provides a platform-independent way to interact with JavaScript
/// It avoids using direct web imports to be compatible with all platforms
class JsBridge {
  /// Get a property from the global window object
  /// Returns null on non-web platforms or if property doesn't exist
  static dynamic getWindowProperty(String propertyPath) {
    if (!kIsWeb) return null;

    // We use a function pointer approach to avoid direct imports
    // The actual implementation is injected at runtime only on web
    return _getProperty?.call(propertyPath);
  }

  /// Open a URL in a new tab (web only)
  /// Does nothing on non-web platforms
  static void openInNewTab(String url) {
    if (!kIsWeb) return;

    // We use a function pointer approach to avoid direct imports
    // The actual implementation is injected at runtime only on web
    _openWindow?.call(url, '_blank');
  }

  // Function pointers that will be set by the web initialization code
  // These will remain null on non-web platforms
  static Function(String path)? _getProperty;
  static Function(String url, String target)? _openWindow;

  /// Set the property getter implementation
  static void setPropertyGetter(Function(String path) implementation) {
    _getProperty = implementation;
  }

  /// Set the window opener implementation
  static void setWindowOpener(
      Function(String url, String target) implementation) {
    _openWindow = implementation;
  }

  /// Initialize the JS bridge
  /// This should be called early in the app lifecycle
  static void init() {
    if (!kIsWeb) return;

    // Web-specific implementation will be injected here
    // This will be handled in the web bootstrap code
    _registerWebImpl();
  }

  /// Registers web implementation - this is overridden at runtime for web
  static void _registerWebImpl() {
    // This implementation is replaced on web platform
    // Does nothing on non-web platforms
  }
}
