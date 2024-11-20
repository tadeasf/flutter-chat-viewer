import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../api_db/api_service.dart';

class PhotoViewGalleryScreen extends StatefulWidget {
  final String collectionName;
  final int initialIndex;
  final List<Map<String, dynamic>> photos;
  final bool showAppBar;

  const PhotoViewGalleryScreen({
    super.key,
    required this.collectionName,
    required this.initialIndex,
    required this.photos,
    this.showAppBar = true,
  });

  @override
  PhotoViewGalleryScreenState createState() => PhotoViewGalleryScreenState();
}

class PhotoViewGalleryScreenState extends State<PhotoViewGalleryScreen> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    print('PhotoViewGalleryScreen initialIndex: ${widget.initialIndex}');
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  String _getPhotoUrl(Map<String, dynamic> photo) {
    if (photo['fullUri'] != null) {
      return photo['fullUri'];
    }
    final uri = photo['uri'] ?? photo['filename'];
    if (uri == null) return 'placeholder_image_url';
    
    return '${ApiService.baseUrl}/inbox/${widget.collectionName}/photos/${uri.split('/').last}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text('${currentIndex + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final photo = widget.photos[index];
              final imageUrl = _getPhotoUrl(photo);
              
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(
                  imageUrl,
                  headers: ApiService.headers,
                ),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'photo_${photo['uri'] ?? photo['filename'] ?? index}',
                ),
              );
            },
            itemCount: widget.photos.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
          if (!widget.showAppBar)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '${currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.white),
                      onPressed: () => _downloadImage(context),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    // Copy the download logic from PhotoViewScreen
    // Lines 19-61 from photo_view_screen.dart
  }
} 