import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../stores/store_provider.dart';
import '../../theme.dart';
import '../../widgets/gallery/photo_thumbnail.dart';
import 'photo_view_gallery.dart';

/// Grid of the photos the other person sent in a conversation.
class PhotoGallery extends StatefulWidget {
  final String collectionName;
  final String title;

  const PhotoGallery(
      {super.key, required this.collectionName, required this.title});

  static void open(BuildContext context, String collectionName,
          {String? title}) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoGallery(
              collectionName: collectionName, title: title ?? collectionName),
        ),
      );

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of(context)
            .galleryStore
            .setupGalleryForCollection(widget.collectionName);
      }
    });
  }

  void _openViewer(int index) {
    final stores = StoreProvider.of(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoViewGalleryScreen(
        photos: stores.galleryStore.getPhotosForGallery(),
        initialIndex: index,
        title: widget.title,
        onShowInChat: (photo) {
          final ts = photo['message_timestamp'] as int?;
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (ts != null) stores.messageStore.jumpTo(ts);
        },
      ),
    ));
  }

  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Image cache cleared')));
  }

  @override
  Widget build(BuildContext context) {
    final gallery = StoreProvider.of(context).galleryStore;
    final theme = Theme.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Observer(
              builder: (_) => Text(gallery.isLoading
                  ? 'Photos · ${widget.title}'
                  : 'Photos · ${widget.title} · ${gallery.photos.length}'),
            ),
            actions: [
              IconButton(
                tooltip: 'Clear image cache',
                onPressed: _clearCache,
                icon: const Icon(Icons.cleaning_services_outlined),
              ),
              const SizedBox(width: Space.s),
            ],
          ),
          body: Observer(builder: (_) {
            if (gallery.isLoading && gallery.photos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (gallery.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load photos: ${gallery.error}'),
                    TextButton(
                      onPressed: () => gallery
                          .setupGalleryForCollection(widget.collectionName),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (gallery.photos.isEmpty) {
              return Center(
                child: Text('No photos from ${widget.title}',
                    style: theme.textTheme.bodyLarge),
              );
            }
            return Scrollbar(
              child: GridView.builder(
                padding: const EdgeInsets.all(Space.s),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: gallery.photos.length,
                itemBuilder: (context, i) {
                  final photo = gallery.getPhotoAt(i);
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openViewer(i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.s),
                        child: PhotoThumbnail(
                          imageUrl: gallery.getPhotoUrl(photo),
                          collectionName: widget.collectionName,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
