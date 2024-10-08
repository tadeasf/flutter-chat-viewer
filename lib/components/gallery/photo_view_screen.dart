import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../api_db/api_service.dart';

class PhotoViewScreen extends StatelessWidget {
  final String imageUrl;
  final String collectionName;

  const PhotoViewScreen({
    super.key,
    required this.imageUrl,
    required this.collectionName,
  });

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final response =
          await http.get(Uri.parse(imageUrl), headers: ApiService.headers);

      if (Platform.isMacOS) {
        final directory = await getDownloadsDirectory();
        final fileName =
            "downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final filePath = '${directory?.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to $filePath')),
          );
        }
      } else {
        final result = await ImageGallerySaverPlus.saveImage(
          response.bodyBytes,
          quality: 100,
          name: "downloaded_image_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (context.mounted) {
          if (result['isSuccess']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image saved to gallery')),
            );
          } else {
            throw Exception('Failed to save image');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(imageUrl, headers: ApiService.headers),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                  child: Text('Failed to load image',
                      style: TextStyle(color: Colors.white)));
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _downloadImage(context),
              backgroundColor: Colors.black.withOpacity(0.7),
              child: const Icon(Icons.download, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
