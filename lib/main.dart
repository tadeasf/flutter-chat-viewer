import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import 'components/messages/message_selector.dart';
import 'components/ui_utils/theme_manager.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'utils/api_db/api_service.dart';
import 'package:flutter/services.dart';
// Use JsBridge for JS interactions
import 'utils/js_bridge.dart';
// Import web initialization
import 'utils/web_init.dart' if (dart.library.io) 'utils/web_init_stub.dart';
import 'stores/store_provider.dart';

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
    dotenv.testLoad(fileInput: "X_API_KEY=dummy api key");
    if (kDebugMode) {
      print(
          "Web environment: API key will be read from window.FLUTTER_ENV at runtime");
    }
  } else {
    // Load from .env file for native platforms
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print("Native environment: Loaded API key from .env file");
    }
  }

  runApp(
    StoreProvider(
      profilePhotoStore: Stores.profilePhotoStore,
      collectionStore: Stores.collectionStore,
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
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    ThemeManager.loadThemeMode().then((mode) {
      setState(() {
        _themeMode = mode;
      });
    });
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

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemeManager.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meta Elysia',
      theme: ThemeManager.getLightTheme(),
      darkTheme: ThemeManager.getDarkTheme(),
      themeMode: _themeMode,
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
            setThemeMode: _setThemeMode,
            themeMode: _themeMode,
          ),
        ),
      ),
    );
  }
}

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final bool showButtons;

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 50.0,
    this.isOnline = false,
    this.showButtons = false,
  });

  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadCachedPhoto();
  }

  Future<void> _loadCachedPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('profile_photo_${widget.collectionName}');
    if (cachedUrl != null) {
      setState(() {
        _imageUrl = cachedUrl;
        _isLoading = false;
      });
    } else {
      _fetchProfilePhoto();
    }
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final requestUrl =
          'https://backend.jevrej.cz/messages/${widget.collectionName}/photo';
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {'X-API-KEY': dotenv.env['X_API_KEY'] ?? ''},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isPhotoAvailable'] == true && data['photoUrl'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'profile_photo_${widget.collectionName}', data['photoUrl']);
          if (mounted) {
            setState(() {
              _imageUrl = data['photoUrl'];
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isLoading)
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: const CircularProgressIndicator(),
          )
        else if (_isError || _imageUrl == null)
          Icon(
            Icons.account_circle,
            size: widget.size,
            color: Colors.grey,
          )
        else
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: _imageUrl ?? '',
              httpHeaders: ApiService.headers,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(
                Icons.account_circle,
                size: widget.size,
                color: Colors.grey,
              ),
            ),
          ),
        if (widget.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
              ),
            ),
          ),
        if (widget.showButtons)
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    // Handle message button press
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    // Handle call button press
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
