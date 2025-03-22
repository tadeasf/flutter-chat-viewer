import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../utils/api_db/api_service.dart';
// Conditionally import dart:js only for web
import '../../utils/js_util.dart';

class PhotoViewScreen extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? messageId;
  final String? conversationId;

  const PhotoViewScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.messageId,
    this.conversationId,
  });

  @override
  State<PhotoViewScreen> createState() => PhotoViewScreenState();
}

class PhotoViewScreenState extends State<PhotoViewScreen> {
  late String imageUrl;

  @override
  void initState() {
    super.initState();
    imageUrl = widget.imageUrl;
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      if (kIsWeb) {
        // For web, trigger browser's download dialog using JS interop
        _downloadImageWithJS(imageUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting download...')),
          );
        }
      } else {
        // For native platforms, download using platform-specific methods
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: ${e.toString()}')),
        );
      }
    }
  }

  // Use JavaScript to download the image in web browsers
  void _downloadImageWithJS(String url) {
    if (kIsWeb) {
      final filename = url.split('/').last;
      downloadWithJS(url, filename);
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
                child: Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'CaskaydiaCove Nerd Font',
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _downloadImage(context),
              backgroundColor: Colors.black.withValues(alpha: 178),
              child: const Icon(Icons.download, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
