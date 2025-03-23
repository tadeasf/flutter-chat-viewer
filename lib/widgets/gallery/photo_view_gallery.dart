import 'package:flutter/material.dart';

class PhotoViewGalleryScreen extends StatelessWidget {
  final String collectionName;
  final int initialIndex;
  final List<Map<String, dynamic>> photos;
  final bool showAppBar;
  final Function(Map<String, dynamic>)? onJumpToMessage;
  final Function(int)? onJumpToGallery;

  const PhotoViewGalleryScreen({
    super.key,
    required this.collectionName,
    required this.initialIndex,
    required this.photos,
    this.showAppBar = true,
    this.onJumpToMessage,
    this.onJumpToGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text('Photo - $collectionName'),
              actions: [
                if (onJumpToMessage != null)
                  IconButton(
                    icon: const Icon(Icons.message),
                    tooltip: 'Jump to message',
                    onPressed: () {
                      if (initialIndex < photos.length) {
                        onJumpToMessage!(photos[initialIndex]);
                      }
                    },
                  ),
              ],
            )
          : null,
      body: Center(
        child: Text('Photo Gallery View - To be implemented'),
      ),
    );
  }
}
