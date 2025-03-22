// This is the web entrypoint file, used in web builds only
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter/material.dart';
import 'package:meta_chat_viewer/main.dart' as app;
import 'package:meta_chat_viewer/utils/web_downloader.dart';

void main() {
  // Configure Flutter for web
  usePathUrlStrategy();

  // Register our web-specific implementations
  // This makes the download feature work in web browsers
  WidgetsFlutterBinding.ensureInitialized();
  WebDownloaderImpl.registerWebImplementation();

  // Launch the app
  app.main();
}
