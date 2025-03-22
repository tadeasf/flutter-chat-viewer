// This file is only imported in web builds
// @dart=2.12

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_interop';
import 'js_bridge.dart';
import 'package:logging/logging.dart';

final _logger = Logger('JSBridge');

@JS('globalThis')
external JSObject get _globalThis;

@JS('window')
external JSObject get _window;

/// Initialize the JavaScript bridge for web
void initJSBridge() {
  if (!kIsWeb) return;

  // Register the implementations using the public setters
  JsBridge.setPropertyGetter(_getJsProperty);
  JsBridge.setWindowOpener(_openJsWindow);

  // Log success
  _logger.info('JS Bridge initialized for web');
}

/// Implementation of property access for web
dynamic _getJsProperty(String propertyPath) {
  if (!kIsWeb) return null;

  try {
    // Get the global object
    final JSObject global = _globalThis;

    // Handle nested properties (e.g., 'FLUTTER_ENV.X_API_KEY')
    if (propertyPath.contains('.')) {
      final parts = propertyPath.split('.');
      JSObject? current = global;

      // Navigate through the property path
      for (final part in parts) {
        if (current == null) {
          return null;
        }

        // Convert the property name to a JSString
        final JSString jsKey = part.toJS;

        // Check if the property exists using in operator
        // Use the extension method .hasProperty() if available in your version
        // or fall back to dynamic type
        final bool hasProperty = (current as dynamic).hasProperty(jsKey);
        if (!hasProperty) {
          return null;
        }

        // Get the property value using dynamic access
        final dynamic nextValue = (current as dynamic)[jsKey];
        if (nextValue == null) {
          return null;
        }

        // Instead of using instanceof check which isn't platform-consistent,
        // try to access it as an object and continue if possible
        try {
          // If it's a leaf value (not an object), dartify will convert it properly
          // If it's an object, we'll continue traversing
          current = nextValue as JSObject?;
        } catch (_) {
          // If we can't cast to JSObject, it's a leaf value
          return nextValue.dartify();
        }
      }

      return current?.dartify();
    } else {
      // Direct property access
      final JSString jsKey = propertyPath.toJS;

      // Use dynamic to access hasProperty and property
      final dynamic dynamicGlobal = global;
      final bool hasProperty = dynamicGlobal.hasProperty(jsKey);

      if (hasProperty) {
        final dynamic result = dynamicGlobal[jsKey];
        return result?.dartify();
      }
      return null;
    }
  } catch (e) {
    _logger.warning('Error accessing JS property: $e');
    return null;
  }
}

/// Implementation of window.open for web
void _openJsWindow(String url, String target) {
  if (!kIsWeb) return;

  try {
    // Use JS interop to call window.open
    final JSString jsUrl = url.toJS;
    final JSString jsTarget = target.toJS;
    (_window as dynamic).open(jsUrl, jsTarget);
  } catch (e) {
    _logger.warning('Error opening window: $e');
  }
}
