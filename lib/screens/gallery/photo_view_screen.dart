import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io';
import '../../utils/api_db/api_service.dart';
// For web platform
import '../../utils/js_util.dart';
import '../../stores/store_provider.dart';
import '../../stores/file_store.dart';

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

    // Prefetch the image if not on web platform
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fileStore = StoreProvider.of(context).fileStore;
        fileStore.prefetchFile(imageUrl, MediaType.image);
      });
    }
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final fileStore = StoreProvider.of(context).fileStore;

      if (kIsWeb && widget.collectionName != null && widget.filename != null) {
        // Debug logging
        if (kDebugMode) {
          print('PhotoViewScreen._downloadImage');
          print('Collection name: ${widget.collectionName}');
          print('Filename: ${widget.filename}');
        }

        // For web with direct URL capability
        final directUrl = ApiService.getWebDownloadUrl(
            widget.collectionName!, widget.filename!);

        // Open in new tab for web using the utility function
        openInNewTab(directUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image opened in new tab')),
        );
      } else if (kIsWeb) {
        // Fallback for web
        final filename = imageUrl.split('/').last;
        downloadWithJS(imageUrl, filename);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting download...')),
        );
      } else {
        // Use the FileStore for native platforms
        await fileStore.downloadFile(context, imageUrl, MediaType.image);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileStore = StoreProvider.of(context).fileStore;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FutureBuilder<String?>(
              future:
                  !kIsWeb ? fileStore.getFile(imageUrl, MediaType.image) : null,
              builder: (context, snapshot) {
                final ImageProvider imageProvider;

                // If we're on web or file not cached yet, use network image
                if (kIsWeb || !snapshot.hasData || snapshot.data == null) {
                  imageProvider =
                      NetworkImage(imageUrl, headers: ApiService.headers);
                } else {
                  // Use the cached file
                  imageProvider = FileImage(File(snapshot.data!));
                }

                return PhotoView(
                  imageProvider: imageProvider,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  loadingBuilder: (context, event) => Center(
                    child: CircularProgressIndicator(
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              event.expectedTotalBytes!,
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
                );
              }),
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
