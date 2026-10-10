import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../../screens/gallery/photo_view_gallery.dart';
import '../../widgets/gallery/photo_thumbnail.dart';
import '../../stores/store_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class PhotoGallery extends StatefulWidget {
  static void open(BuildContext context, String collectionName) =>
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PhotoGallery(collectionName: collectionName)),
      );

  final String collectionName;
  final Map<String, dynamic>? targetPhoto;

  const PhotoGallery({
    super.key,
    required this.collectionName,
    this.targetPhoto,
  });

  @override
  PhotoGalleryState createState() => PhotoGalleryState();
}

class PhotoGalleryState extends State<PhotoGallery> {
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger('PhotoGallery');
  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();

    // Load photos through store when component is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final galleryStore = StoreProvider.of(context).galleryStore;
      _logger
          .info('Setting up gallery for collection: ${widget.collectionName}');

      galleryStore.setupGalleryForCollection(
          widget.collectionName, widget.targetPhoto);

      // Set up reaction to scroll to target photo when photos are loaded
      _setupReactions();
    });
  }

  void _setupReactions() {
    final galleryStore = StoreProvider.of(context).galleryStore;

    // React to photo loading completion to scroll to target photo
    _disposers.add(reaction((_) => galleryStore.isLoading, (isLoading) {
      if (!isLoading && galleryStore.hasTargetPhoto && mounted) {
        _scrollToTargetPhoto();
      }
    }));
  }

  @override
  void dispose() {
    _scrollController.dispose();

    // Dispose of all reactions
    for (final disposer in _disposers) {
      disposer();
    }

    super.dispose();
  }

  Future<void> _scrollToTargetPhoto() async {
    final galleryStore = StoreProvider.of(context).galleryStore;

    if (mounted && galleryStore.targetPhotoIndex != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        scrollToIndex(galleryStore.targetPhotoIndex!);
      });
    }
  }

  void _handleJumpToMessage(Map<String, dynamic> photo) {
    final timestamp = photo['message_timestamp'] as int?;
    if (timestamp == null) return;
    // Close the photo viewer and the gallery, then show the message.
    Navigator.of(context).popUntil((route) => route.isFirst);
    StoreProvider.of(context).messageStore.jumpTo(timestamp);
  }

  void scrollToIndex(int index) {
    _logger.info('Scrolling to index: $index');

    final crossAxisCount = 3;
    final rowIndex = index ~/ crossAxisCount;
    final itemHeight = MediaQuery.of(context).size.width / crossAxisCount;
    final offset = rowIndex * itemHeight;

    _logger.info('Row index: $rowIndex, Offset: $offset');

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  static void navigateToGalleryAndScroll(
    BuildContext context,
    String collectionName,
    Map<String, dynamic> targetPhoto,
  ) {
    // Get gallery store and set target photo before navigation
    final galleryStore = StoreProvider.of(context).galleryStore;
    galleryStore.setTargetPhoto(targetPhoto);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGallery(
          collectionName: collectionName,
          targetPhoto: targetPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryStore = StoreProvider.of(context).galleryStore;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // A new FocusNode was created on every build (leaked, and lost focus, so
    // Esc did nothing). Focus(autofocus) owns its node.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: isDarkMode ? Color(0xFF121214) : null,
          appBar: AppBar(
            title: Text('Photos - ${widget.collectionName}'),
            backgroundColor: isDarkMode ? Color(0xFF17171B) : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_backup_restore),
                tooltip: 'Clear image cache',
                onPressed: () async {
                  await DefaultCacheManager().emptyCache();
                  PaintingBinding.instance.imageCache.clear();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image cache cleared')),
                  );
                },
              ),
            ],
          ),
          body: Observer(
            builder: (_) {
              if (galleryStore.isLoading && galleryStore.photos.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (galleryStore.photos.isEmpty && !galleryStore.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No photos found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This collection does not have any photos',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                ),
                itemCount: galleryStore.photos.length +
                    (galleryStore.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == galleryStore.photos.length &&
                      galleryStore.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (index >= galleryStore.photos.length) {
                    return Container();
                  }

                  final photo = galleryStore.getPhotoAt(index);
                  final imageUrl = galleryStore.getPhotoUrl(photo);

                  return GestureDetector(
                    onTap: () {
                      galleryStore.setCurrentPhotoIndex(index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoViewGalleryScreen(
                            collectionName: widget.collectionName,
                            initialIndex: index,
                            photos: galleryStore.getPhotosForGallery(),
                            showAppBar: true,
                            onJumpToMessage: _handleJumpToMessage,
                            onJumpToGallery: (currentIndex) {
                              final currentPhoto =
                                  galleryStore.getPhotoAt(currentIndex);
                              PhotoGalleryState.navigateToGalleryAndScroll(
                                context,
                                widget.collectionName,
                                currentPhoto,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: isDarkMode
                          ? Color(0xFF1E1E24)
                          : Theme.of(context).cardColor,
                      child: PhotoThumbnail(
                        imageUrl: imageUrl,
                        collectionName: widget.collectionName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
