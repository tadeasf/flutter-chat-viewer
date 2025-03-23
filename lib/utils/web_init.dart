// This file is responsible for initializing web-specific features
// It's imported conditionally only on web platform

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'js_bridge.dart';
import 'js_bridge_web.dart' as js_web;

/// Initialize web-specific features
void initializeForWeb() {
  if (!kIsWeb) return;

  try {
    // Initialize the JavaScript bridge for web
    _initializeJsBridge();

    if (kDebugMode) {
      print('Web features initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing web features: $e');
    }
  }
}

/// Initialize the JavaScript bridge for web
void _initializeJsBridge() {
  if (!kIsWeb) return;

  // Call the initialization function in js_bridge_web.dart
  js_web.initJSBridge();

  // Also initialize the JsBridge class
  JsBridge.init();

  if (kDebugMode) {
    print('JavaScript bridge initialized for web');
  }
}
