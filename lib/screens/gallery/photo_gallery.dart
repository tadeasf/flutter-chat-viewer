import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../../screens/gallery/photo_view_gallery.dart';
import '../../utils/search/scroll_to_highlighted_message.dart';
import '../../utils/search/search_type.dart';
import '../../widgets/gallery/photo_thumbnail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../stores/store_provider.dart';
import '../../stores/file_store.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class PhotoGallery extends StatefulWidget {
  final String collectionName;
  final List<Map<dynamic, dynamic>> messages;
  final ItemScrollController itemScrollController;
  final Map<String, dynamic>? targetPhoto;

  const PhotoGallery({
    super.key,
    required this.collectionName,
    required this.messages,
    required this.itemScrollController,
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
    _scrollController.addListener(_scrollListener);

    // Load photos through store when component is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final galleryStore = StoreProvider.of(context).galleryStore;
      _logger
          .info('Setting up gallery for collection: ${widget.collectionName}');

      // Get the current user's name to filter out their photos
      String? senderFilter;
      if (widget.messages.isNotEmpty) {
        // Find a message with sender_name that is not the author (you)
        for (final message in widget.messages) {
          if (message.containsKey('sender_name') &&
              !message['sender_name'].toString().contains('Tadeáš Fořt')) {
            senderFilter = message['sender_name'];
            break;
          }
        }
      }

      _logger.info('Using sender filter: $senderFilter');

      // Setup the gallery store for this collection with sender filter
      galleryStore.setupGalleryForCollection(
          widget.collectionName, widget.targetPhoto,
          sender: senderFilter);

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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    // Dispose of all reactions
    for (final disposer in _disposers) {
      disposer();
    }

    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more photos through the store
      final galleryStore = StoreProvider.of(context).galleryStore;
      galleryStore.loadMorePhotos();
    }
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
    final messageIndexStore = StoreProvider.of(context).messageIndexStore;
    messageIndexStore.updateMessagesFromRaw(widget.messages);

    // Get the creation_timestamp from the photo data
    final timestamp = photo['creation_timestamp'];
    _logger.info('Photo data: $photo');
    _logger.info('photo timestamp: ${photo['creation_timestamp']}');
    _logger.info('Timestamp: $timestamp');

    if (timestamp == null) {
      _logger.warning('Error: creation_timestamp is null in photo data');
      return;
    }

    // In PhotoModel.fromMessageJson, the creation_timestamp is multiplied by 1000
    // We need to do the same here to match the timestamps
    int photoTimestamp = (timestamp as int) * 1000;
    _logger.info('Modified photo timestamp (x1000): $photoTimestamp');

    // First try searching with the modified timestamp
    var messageIndex = messageIndexStore.getIndexForTimestampRaw(
      photoTimestamp,
      isPhotoTimestamp: true,
    );

    // If not found, try with the original timestamp
    if (messageIndex == null) {
      _logger.info('Trying original timestamp as fallback');
      messageIndex = messageIndexStore.getIndexForTimestampRaw(
        timestamp,
        isPhotoTimestamp: true,
      );
    }

    _logger.info('Message index: $messageIndex');

    if (messageIndex != null) {
      Navigator.pop(context);
      _logger.info('Closed photo gallery view');

      Navigator.pop(context);
      _logger.info('Closed app drawer');

      scrollToHighlightedMessage(
        messageIndex,
        [messageIndex],
        widget.itemScrollController,
        SearchType.photoView,
      );
      _logger.info('Scrolled to message');
    } else {
      _logger.warning(
          'Error: No message index found for timestamp: $timestamp (or modified: $photoTimestamp)');

      // Show a snackbar to notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the original message for this photo'),
          duration: Duration(seconds: 3),
        ),
      );
    }
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
    List<Map<dynamic, dynamic>> messages,
    ItemScrollController itemScrollController,
  ) {
    // Get gallery store and set target photo before navigation
    final galleryStore = StoreProvider.of(context).galleryStore;
    galleryStore.setTargetPhoto(targetPhoto);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGallery(
          collectionName: collectionName,
          messages: messages,
          itemScrollController: itemScrollController,
          targetPhoto: targetPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryStore = StoreProvider.of(context).galleryStore;
    final fileStore = StoreProvider.of(context).fileStore;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Color(0xFF121214) : null,
        appBar: AppBar(
          title: Text('Photos - ${widget.collectionName}'),
          backgroundColor: isDarkMode ? Color(0xFF17171B) : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              tooltip: 'Clear image cache',
              onPressed: () {
                fileStore.clearTypeCache(MediaType.image);
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
              itemCount:
                  galleryStore.photos.length + (galleryStore.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == galleryStore.photos.length &&
                    galleryStore.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (index >= galleryStore.photos.length) {
                  return Container();
                }

                final photo = galleryStore.getPhotoAt(index);
                final imageUrl =
                    galleryStore.getPhotoUrl(photo, widget.collectionName);

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
                              widget.messages,
                              widget.itemScrollController,
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
    );
  }
}
