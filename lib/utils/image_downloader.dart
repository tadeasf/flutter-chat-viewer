import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'api_db/api_service.dart';

class ImageDownloader {
  static Future<void> downloadImage(
      BuildContext context, String imageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) throw Exception('Cannot access storage');

        final fileName = imageUrl.split('/').last;
        final filePath = '${directory.path}/$fileName';

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image downloaded successfully')),
          );
        }
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
        );
      }
    }
  }
}
