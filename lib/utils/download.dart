import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'api_db/api_service.dart';

/// Saves the media file at [url]: to ~/Downloads on desktop, to the photo
/// gallery on mobile. Reports the result in a snack bar.
Future<void> saveMedia(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final response =
        await http.get(Uri.parse(url), headers: ApiService.headersFor(url));
    if (response.statusCode != 200) {
      throw ApiException.fromStatus(response.statusCode);
    }
    final name = Uri.parse(url).pathSegments.last;

    if (!kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('No downloads directory');
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(response.bodyBytes);
      messenger.showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } else {
      final result = await ImageGallerySaverPlus.saveImage(response.bodyBytes,
          quality: 100, name: name);
      if (result['isSuccess'] != true) throw Exception('Gallery refused file');
      messenger.showSnackBar(const SnackBar(content: Text('Saved to gallery')));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not save file: $e')));
  }
}
