import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/services.dart';
import '../../utils/js_util.dart';
import '../../utils/web_image_viewer.dart';
import '../../stores/store_provider.dart';
import '../../stores/file_store.dart';

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

    // Update the galleryStore with current index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final galleryStore = StoreProvider.of(context).galleryStore;
        galleryStore.setCurrentPhotoIndex(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
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

  @override
  Widget build(BuildContext context) {
    final galleryStore = StoreProvider.of(context).galleryStore;
    final fileStore = StoreProvider.of(context).fileStore;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: GestureDetector(
        onLongPress: widget.onLongPress != null
            ? () => widget.onLongPress!(widget.photos[_currentIndex])
            : null,
        child: Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 127),
          appBar: widget.showAppBar
              ? AppBar(
                  backgroundColor: Colors.black.withValues(alpha: 127),
                  title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
                  actions: [
                    if (widget.onJumpToMessage != null)
                      IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () => widget.onJumpToMessage
                            ?.call(widget.photos[_currentIndex]),
                        tooltip: 'Jump to Message',
                      ),
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
                      tooltip: 'Download Image',
                    ),
                  ],
                )
              : null,
          body: kIsWeb
              ? _buildWebGallery()
              : PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    final photo = widget.photos[index];
                    final imageUrl =
                        galleryStore.getPhotoUrl(photo, widget.collectionName);

                    return PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(
                        imageUrl,
                        headers: {'x-api-key': fileStore.apiKey},
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
                    galleryStore.setCurrentPhotoIndex(index);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _downloadCurrentImage(),
            backgroundColor: Colors.black.withValues(alpha: 178),
            child: const Icon(Icons.download, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildWebGallery() {
    final galleryStore = StoreProvider.of(context).galleryStore;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            galleryStore.setCurrentPhotoIndex(index);
          },
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            final imageUrl =
                galleryStore.getPhotoUrl(photo, widget.collectionName);

            return Center(
              child: Hero(
                tag: 'photo_${photo['uri']}',
                child: WebImageViewer(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
            );
          },
        ),
        if (!widget.showAppBar) // Only show this if AppBar is hidden
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _downloadCurrentImage(),
              backgroundColor: Colors.black.withValues(alpha: 178),
              child: const Icon(Icons.download, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _downloadCurrentImage() async {
    if (!mounted) return;

    final galleryStore = StoreProvider.of(context).galleryStore;
    final fileStore = StoreProvider.of(context).fileStore;
    final photo = widget.photos[_currentIndex];
    final imageUrl = galleryStore.getPhotoUrl(photo, widget.collectionName);
    final filename = galleryStore.getFilename(photo);

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
      if (kIsWeb) {
        _downloadForWeb(filename);
      } else {
        await fileStore.downloadFile(context, imageUrl, MediaType.image);
      }
    }
  }

  void _downloadForWeb(String filename) {
    try {
      if (kIsWeb) {
        // Debug logging
        if (kDebugMode) {
          print('PhotoViewGallery._downloadForWeb');
          print('Collection name: ${widget.collectionName}');
          print('Filename: $filename');
        }

        final galleryStore = StoreProvider.of(context).galleryStore;
        final webDownloadUrl =
            galleryStore.getWebDownloadUrl(widget.collectionName, filename);

        // Log the generated URL
        if (kDebugMode) {
          print('Generated URL: $webDownloadUrl');
        }

        // Open in new tab using the utility function
        openInNewTab(webDownloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image opened in new tab')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open image: $e')),
      );
    }
  }
}
