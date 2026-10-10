import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../components/chat/audio_message_player.dart';
import '../../components/chat/video_tile.dart';
import '../../stores/store_provider.dart';
import '../../theme.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/text_match.dart';
import '../../widgets/gallery/photo_thumbnail.dart';
import 'photo_view_gallery.dart';

/// Media of a conversation in three tabs: the photos the other person sent
/// (`/photos`), and all videos and voice messages (`/media`).
class PhotoGallery extends StatefulWidget {
  final String collectionName;
  final String title;

  /// Pops back to the chat and shows the message at [timestamp].
  final void Function(int timestamp, String? id) onShowInChat;

  const PhotoGallery({
    super.key,
    required this.collectionName,
    required this.title,
    required this.onShowInChat,
  });

  static void open(
    BuildContext context,
    String collectionName, {
    String? title,
    required void Function(int timestamp, String? id) onShowInChat,
  }) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoGallery(
            collectionName: collectionName,
            title: title ?? collectionName,
            onShowInChat: onShowInChat,
          ),
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

  void _showInChat(int? timestamp, String? id) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (timestamp != null) widget.onShowInChat(timestamp, id);
  }

  void _openViewer(int index) {
    final stores = StoreProvider.of(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoViewGalleryScreen(
        photos: stores.galleryStore.getPhotosForGallery(),
        initialIndex: index,
        title: widget.title,
        onShowInChat: (photo) =>
            _showInChat(photo['message_timestamp'] as int?, null),
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
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Media · ${widget.title}'),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(
                    child: Observer(
                      builder: (_) => Text(gallery.isLoading
                          ? 'Photos'
                          : 'Photos · ${formatCount(gallery.photos.length)}'),
                    ),
                  ),
                  const Tab(text: 'Videos'),
                  const Tab(text: 'Voice messages'),
                ],
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
            body: TabBarView(children: [
              Observer(builder: (_) {
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
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
              _MediaTab(
                collectionName: widget.collectionName,
                type: 'videos',
                empty: 'No videos in this conversation',
                onShowInChat: _showInChat,
              ),
              _MediaTab(
                collectionName: widget.collectionName,
                type: 'audio_files',
                empty: 'No voice messages in this conversation',
                onShowInChat: _showInChat,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Videos or voice messages from `/media`, newest first, with the date and
/// sender of each and a way back to the message.
class _MediaTab extends StatefulWidget {
  final String collectionName;
  final String type;
  final String empty;
  final void Function(int? timestamp, String? id) onShowInChat;

  const _MediaTab({
    required this.collectionName,
    required this.type,
    required this.empty,
    required this.onShowInChat,
  });

  @override
  State<_MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends State<_MediaTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _items = _load();

  /// One entry per file, carrying its message's id, time and sender.
  Future<List<Map<String, dynamic>>> _load() async => [
        for (final m
            in await ApiService.fetchMedia(widget.collectionName, widget.type))
          for (final f in (m[widget.type] as List).cast<Map>())
            {
              'uri': f['uri'],
              '_id': m['_id'],
              'timestamp_ms': m['timestamp_ms'],
              'sender_name': m['sender_name'],
            },
      ];

  @override
  bool get wantKeepAlive => true;

  Widget _caption(BuildContext context, Map<String, dynamic> item) {
    final ts = item['timestamp_ms'] as int?;
    return Row(
      children: [
        Expanded(
          child: Text(
            [
              if (ts != null) '${formatShortDate(ts)} ${formatTime(ts)}',
              item['sender_name'] ?? '',
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Show in chat',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: () => widget.onShowInChat(ts, item['_id'] as String?),
          icon: const Icon(Icons.forum_outlined),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(() => _items = _load()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
              child: Text(widget.empty,
                  style: Theme.of(context).textTheme.bodyLarge));
        }
        if (widget.type == 'videos') {
          return Scrollbar(
            child: GridView.builder(
              padding: const EdgeInsets.all(Space.m),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 196,
                mainAxisSpacing: Space.m,
                crossAxisSpacing: Space.m,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => Column(
                children: [
                  Expanded(
                    child: VideoTile(
                        uri: items[i]['uri'] as String,
                        width: double.infinity,
                        height: double.infinity),
                  ),
                  _caption(context, items[i]),
                ],
              ),
            ),
          );
        }
        return Scrollbar(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.l, vertical: Space.m),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.s),
            itemBuilder: (context, i) => Row(
              children: [
                AudioMessagePlayer(
                    key: ValueKey(items[i]['uri']),
                    uri: items[i]['uri'] as String),
                const SizedBox(width: Space.l),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _caption(context, items[i]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
