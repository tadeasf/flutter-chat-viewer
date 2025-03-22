import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../utils/api_db/api_service.dart';
// For web platform
import '../../utils/js_util.dart';

class PhotoViewScreen extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? messageId;
  final String? conversationId;
  final String? collectionName;
  final String? filename;

  const PhotoViewScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.messageId,
    this.conversationId,
    this.collectionName,
    this.filename,
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
        _downloadForWeb();
      } else {
        _downloadForNative(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: ${e.toString()}')),
        );
      }
    }
  }

  void _downloadForWeb() {
    if (widget.collectionName != null && widget.filename != null) {
      // Use the direct URL method for web
      final directUrl = ApiService.getWebDownloadUrl(
          widget.collectionName!, widget.filename!);

      // Open in new tab for web using the utility function
      openInNewTab(directUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image opened in new tab')),
      );
    } else {
      // Fallback to using js_util approach with the current URL
      final filename = imageUrl.split('/').last;
      downloadWithJS(imageUrl, filename);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting download...')),
      );
    }
  }

  Future<void> _downloadForNative(BuildContext context) async {
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
            imageProvider: NetworkImage(imageUrl,
                headers: kIsWeb ? null : ApiService.headers),
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
