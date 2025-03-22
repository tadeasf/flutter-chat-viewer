import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'api_db/api_service.dart';

class ImageDownloader {
  static Future<void> downloadImage(
      BuildContext context, String imageUrl) async {
    try {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading image...')),
      );

      final response = await http.get(
        Uri.parse(imageUrl),
        headers: kIsWeb ? null : ApiService.headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithoutExt = fileName.split('.').first;
      final extension =
          fileName.contains('.') ? '.${fileName.split('.').last}' : '';
      final saveFileName = '${fileNameWithoutExt}_$timestamp$extension';

      if (kIsWeb) {
        // For web platform, create a download link
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image downloading in browser')),
          );
        }
        // Web browser will handle the download directly
      } else if (Platform.isMacOS || Platform.isLinux) {
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception('Cannot access downloads directory');
        }

        final filePath =
            '${directory.path}${Platform.pathSeparator}$saveFileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to ${file.path}')),
          );
        }
      } else {
        final result = await ImageGallerySaverPlus.saveImage(
          response.bodyBytes,
          quality: 100,
          name: saveFileName,
        );

        if (!context.mounted) return;

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved to gallery')),
          );
        } else {
          throw Exception('Failed to save image to gallery');
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
