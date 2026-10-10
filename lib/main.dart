import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/home_screen.dart';
import 'stores/store_provider.dart';
import 'utils/api_db/api_service.dart';
import 'theme.dart';
// Use JsBridge for JS interactions
import 'utils/js_bridge.dart';
// Import web initialization
import 'utils/web_init.dart' if (dart.library.io) 'utils/web_init_stub.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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

  if (ApiService.apiKey.isEmpty) {
    Logger('main').severe(
        'API_KEY is not set. Build with --dart-define-from-file=.env.json');
  }

  runApp(
    StoreProvider(
      profilePhotoStore: Stores.profilePhotoStore,
      collectionStore: Stores.collectionStore,
      messageStore: Stores.messageStore,
      themeStore: Stores.themeStore,
      galleryStore: Stores.galleryStore,
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
  final _light = buildTheme(Brightness.light);
  final _dark = buildTheme(Brightness.dark);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStore = StoreProvider.of(context).themeStore;
    return Observer(
      builder: (_) => MaterialApp(
        title: 'Meta Elysia',
        debugShowCheckedModeBanner: false,
        theme: _light,
        darkTheme: _dark,
        themeMode: themeStore.themeMode,
        home: const HomeScreen(),
      ),
    );
  }
}
