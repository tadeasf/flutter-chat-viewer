import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

// Add this import
import 'components/messages/message_selector.dart';
import 'stores/store_provider.dart';
import 'stores/theme_store.dart';
// Use JsBridge for JS interactions
import 'utils/js_bridge.dart';
// Import web initialization
import 'utils/web_init.dart' if (dart.library.io) 'utils/web_init_stub.dart';
// Use the imported AppColors from ThemeStore

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Use print in development, but in production this could be connected to
    // a more sophisticated logging system
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
    if (record.error != null) {
      if (kDebugMode) {
        print('Error: ${record.error}');
      }
    }
    if (record.stackTrace != null) {
      if (kDebugMode) {
        print('Stack trace: ${record.stackTrace}');
      }
    }
  });

  // Initialize JavaScript bridge for web
  if (kIsWeb) {
    // We use dynamic imports to avoid including web-specific code in native builds
    try {
      // Initialize web-specific features
      initializeForWeb();

      if (kDebugMode) {
        print('Web initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing web features: $e');
      }
    }
  }

  // Set up method channel for web JavaScript interop
  if (kIsWeb) {
    const platform = MethodChannel('app.meta_elysia/js_interop');
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getApiKey':
          try {
            // Access the API key from window.FLUTTER_ENV
            final apiKey = JsBridge.getWindowProperty('FLUTTER_ENV.X_API_KEY');
            return apiKey?.toString() ?? '';
          } catch (e) {
            Logger('JSInterop').warning('Error accessing API key: $e');
            return '';
          }
        case 'openInNewTab':
          try {
            final url = call.arguments['url'] as String;
            JsBridge.openInNewTab(url);
            return true;
          } catch (e) {
            Logger('JSInterop').warning('Error opening URL: $e');
            return false;
          }
        default:
          throw PlatformException(
            code: 'UNSUPPORTED_METHOD',
            message: 'Method ${call.method} not supported',
          );
      }
    });
  }

  // Load environment variables
  if (kIsWeb) {
    // For web, we'll set a dummy value initially
    // The API key will be injected by the Dockerfile into window.FLUTTER_ENV
    // and ApiService will read it directly from the HTML when needed
    dotenv.testLoad(
        fileInput:
            "X_API_KEY=4lFAmnt2FuHLDSKrka9cdI5loz0D90pyidtXKsR2hYuYcG5EHnUX5TV0H6Y3y");

    // dotenv.testLoad(fileInput: "X_API_KEY=dummy api key");
    if (kDebugMode) {
      print(
          "Web environment: API key will be read from window.FLUTTER_ENV at runtime");
    }
  } else {
    // Load from .env file for native platforms
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print("Native environment: Loaded API key from .env file");
      // Log the API key to verify it loaded correctly
      print("API Key from .env: ${dotenv.env['X_API_KEY'] ?? 'Not found'}");
    }
  }

  runApp(
    StoreProvider(
      profilePhotoStore: Stores.profilePhotoStore,
      collectionStore: Stores.collectionStore,
      messageStore: Stores.messageStore,
      themeStore: Stores.themeStore,
      fileStore: Stores.fileStore,
      photoStore: Stores.photoStore,
      galleryStore: Stores.galleryStore,
      messageIndexStore: Stores.messageIndexStore,
      navigationStore: Stores.navigationStore,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      // Permission granted
    } else {
      // Handle the case when permission is not granted
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStore = StoreProvider.of(context).themeStore;

    return Observer(
      builder: (_) => MaterialApp(
        title: 'Meta Elysia',
        theme: AppColors.getLightTheme(themeStore.fontSize),
        darkTheme: AppColors.getDarkTheme(themeStore.fontSize),
        themeMode: themeStore.themeMode,
        home: FocusScope(
          autofocus: true,
          child: MessageSelectorShortcuts(
            onSearchTriggered: () {
              // Global handler
            },
            onPreviousResult: () {
              // Global handler
            },
            onNextResult: () {
              // Global handler
            },
            onGalleryOpen: () {
              // Global handler
            },
            onCollectionSelectorToggle: () {
              // Global handler
            },
            child: MessageSelector(
              setThemeMode: (ThemeMode mode) => themeStore.setThemeMode(mode),
              themeMode: themeStore.themeMode,
            ),
          ),
        ),
      ),
    );
  }
}
