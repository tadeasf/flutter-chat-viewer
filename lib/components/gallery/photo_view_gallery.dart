import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/image_downloader.dart';

class PhotoViewGalleryScreen extends StatefulWidget {
  final String collectionName;
  final int initialIndex;
  final List<Map<String, dynamic>> photos;
  final bool showAppBar;
  final void Function(Map<String, dynamic>)? onLongPress;

  const PhotoViewGalleryScreen({
    super.key,
    required this.collectionName,
    required this.initialIndex,
    required this.photos,
    this.showAppBar = true,
    this.onLongPress,
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
    return GestureDetector(
      onLongPress: () {
        if (widget.onLongPress != null) {
          final currentPhoto = widget.photos[currentIndex];
          widget.onLongPress!(currentPhoto);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                title: Text('${currentIndex + 1} / ${widget.photos.length}'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadImage(context),
                  ),
                ],
              )
            : null,
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
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    final photo = widget.photos[currentIndex];
    final imageUrl = _getPhotoUrl(photo);
    await ImageDownloader.downloadImage(context, imageUrl);
  }
}
