import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/api_db/api_service.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'photo_view_gallery.dart';
import '../search/scroll_to_highlighted_message.dart';
import '../search/search_type.dart';
import '../messages/message_index_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  final List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger('PhotoGallery');

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_scrollListener);

    if (widget.targetPhoto != null) {
      _loadPhotosAndScroll();
    }
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photos = await ApiService.fetchPhotos(widget.collectionName);
      setState(() {
        _photos.addAll(photos);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading photos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhotosAndScroll() async {
    await _loadPhotos();
    if (mounted && widget.targetPhoto != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final index = _photos.indexWhere(
            (photo) => photo['photos'][0]['uri'] == widget.targetPhoto!['uri']);
        if (index != -1) {
          scrollToIndex(index);
        }
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadPhotos();
    }
  }

  void _handleJumpToMessage(Map<String, dynamic> photo) {
    final manager = MessageIndexManager();
    manager.updateMessages(widget.messages);

    final timestamp = photo['creation_timestamp'];
    _logger.info('Photo data: $photo');
    _logger.info('photo timestamp: ${photo['creation_timestamp']}');
    _logger.info('Timestamp: $timestamp');

    if (timestamp == null) {
      _logger.warning('Error: creation_timestamp is null in photo data');
      return;
    }

    final messageIndex = manager.getIndexForTimestamp(
      timestamp as int,
      isPhotoTimestamp: true,
      useCreationTimestamp: true,
    );

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
      _logger
          .warning('Error: No message index found for timestamp: $timestamp');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Photos - ${widget.collectionName}'),
      ),
      body: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
        ),
        itemCount: _photos.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _photos.length && _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (index >= _photos.length) {
            return Container();
          }
          final photo = _photos[index]['photos'][0];
          final photoUri = photo['uri'] as String;
          final imageUrl = photo['fullUri'] ??
              ApiService.getPhotoUrl(
                  widget.collectionName,
                  photoUri.contains('/photos/')
                      ? photoUri
                      : photoUri.split('/').last);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoViewGalleryScreen(
                    collectionName: widget.collectionName,
                    initialIndex: index,
                    photos: _photos
                        .map((photo) =>
                            Map<String, dynamic>.from(photo['photos'][0]))
                        .toList(),
                    showAppBar: true,
                    onJumpToMessage: _handleJumpToMessage,
                    onJumpToGallery: (currentIndex) {
                      final currentPhoto = _photos[currentIndex]['photos'][0];
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
            child: Hero(
              tag: 'photo_${photo['uri']}',
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                httpHeaders: ApiService.headers,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
