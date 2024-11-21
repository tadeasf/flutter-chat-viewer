import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/image_downloader.dart';
import 'package:flutter/services.dart';

class PhotoViewGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  final Function(Map<String, dynamic>)? onLongPress;
  final String collectionName;
  final bool showAppBar;
  final Function(int)? onJumpToGallery;
  final Function(Map<String, dynamic>)? onJumpToMessage;

  const PhotoViewGalleryScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.onLongPress,
    required this.collectionName,
    this.showAppBar = true,
    this.onJumpToGallery,
    this.onJumpToMessage,
  });

  @override
  State<PhotoViewGalleryScreen> createState() => _PhotoViewGalleryScreenState();
}

class _PhotoViewGalleryScreenState extends State<PhotoViewGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
          _currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          _currentIndex < widget.photos.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  String _getPhotoUrl(Map<String, dynamic> photo) {
    if (photo['fullUri'] != null) return photo['fullUri'] as String;

    final uri = photo['uri'] as String;
    if (uri.startsWith('messages/inbox/')) {
      final collectionName = uri.split('/')[2];
      final filename = uri.split('/').last;
      return ApiService.getPhotoUrl(collectionName, filename);
    }

    return ApiService.getPhotoUrl(widget.collectionName, uri);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: GestureDetector(
        onLongPress: widget.onLongPress != null
            ? () => widget.onLongPress!(widget.photos[_currentIndex])
            : null,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: widget.showAppBar
              ? AppBar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
                  actions: [
                    if (widget.onJumpToGallery != null)
                      IconButton(
                        icon: const Icon(Icons.grid_view),
                        onPressed: () =>
                            widget.onJumpToGallery?.call(_currentIndex),
                        tooltip: 'Jump to Gallery',
                      ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadCurrentImage(),
                    ),
                  ],
                )
              : null,
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final photo = widget.photos[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(
                  _getPhotoUrl(photo),
                  headers: ApiService.headers,
                ),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes:
                    PhotoViewHeroAttributes(tag: 'photo_${photo['uri']}'),
              );
            },
            itemCount: widget.photos.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCurrentImage() async {
    if (!mounted) return;

    final photo = widget.photos[_currentIndex];
    final imageUrl = _getPhotoUrl(photo);

    // Show a confirmation dialog
    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Download Image'),
          content: const Text('Do you want to download this image?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Download'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDownload == true && mounted) {
      await ImageDownloader.downloadImage(context, imageUrl);
    }
  }
}
