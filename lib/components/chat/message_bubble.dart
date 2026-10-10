import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/gallery/photo_view_gallery.dart';
import '../../screens/media/video_player_screen.dart';
import '../../theme.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/download.dart';
import '../../utils/text_match.dart';
import 'audio_message_player.dart';
import '../avatar.dart';
import '../ui_utils/media_unavailable.dart';

const ownerName = 'Tadeáš Fořt';

/// Where a message sits in a run of messages from the same sender.
class GroupPosition {
  final bool first;
  final bool last;
  const GroupPosition({required this.first, required this.last});
}

/// One message: text bubble and/or media, grouped with its neighbours.
class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final GroupPosition position;
  final bool highlighted;
  final String? query;
  final String? avatarUrl;
  final bool bookmarked;
  final VoidCallback? onToggleBookmark;

  const MessageBubble({
    super.key,
    required this.message,
    required this.position,
    this.highlighted = false,
    this.query,
    this.avatarUrl,
    this.bookmarked = false,
    this.onToggleBookmark,
  });

  bool get mine => message['sender_name'] == ownerName;
  int get timestamp => message['timestamp_ms'] as int? ?? 0;

  BorderRadius _radius() {
    const big = Radius.circular(Radii.bubble);
    const small = Radius.circular(Radii.s);
    final top = position.first ? big : small;
    final bottom = position.last ? big : small;
    return mine
        ? BorderRadius.only(
            topLeft: big, bottomLeft: big, topRight: top, bottomRight: bottom)
        : BorderRadius.only(
            topRight: big, bottomRight: big, topLeft: top, bottomLeft: bottom);
  }

  List<Map<String, dynamic>> _media(String key) =>
      ((message[key] as List?) ?? const []).cast<Map<String, dynamic>>();

  void _openPhotos(BuildContext context, int index) {
    final photos = _media('photos')
        .map((p) => {...p, 'message_timestamp': timestamp})
        .toList();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoViewGalleryScreen(
        photos: photos,
        initialIndex: index,
        title: message['sender_name'] as String? ?? '',
      ),
    ));
  }

  Future<void> _contextMenu(BuildContext context, Offset position,
      {Map<String, dynamic>? photo}) async {
    final text = message['content'] as String?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
          position & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        if (text != null && text.isNotEmpty)
          const PopupMenuItem(value: 'copy', child: Text('Copy text')),
        const PopupMenuItem(value: 'date', child: Text('Copy date and time')),
        if (onToggleBookmark != null)
          PopupMenuItem(
              value: 'bookmark',
              child: Text(bookmarked ? 'Remove bookmark' : 'Bookmark')),
        if (photo != null) ...[
          const PopupMenuItem(value: 'open', child: Text('Open photo')),
          const PopupMenuItem(value: 'save', child: Text('Save to Downloads')),
        ],
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: text!));
      case 'date':
        Clipboard.setData(ClipboardData(text: formatDateTime(timestamp)));
      case 'bookmark':
        onToggleBookmark!();
      case 'open':
        _openPhotos(context, _media('photos').indexOf(photo!));
      case 'save':
        saveMedia(context, ApiService.mediaUrl(photo!['uri'] as String));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ChatColors.of(context);
    final text = message['content'] as String?;
    final photos = _media('photos');
    final videos = _media('videos');
    final audio = _media('audio_files');
    final fontSize = theme.textTheme.bodyLarge?.fontSize;

    final parts = <Widget>[
      if (text != null && text.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxWidth: maxBubbleWidth),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: mine ? colors.mine : colors.theirs,
            borderRadius: _radius(),
            border: highlighted
                ? Border.all(color: colors.highlight, width: 2)
                : null,
          ),
          child: Text.rich(
            TextSpan(
              children: highlightSpans(
                text,
                query,
                TextStyle(
                    backgroundColor: colors.highlight,
                    color: theme.colorScheme.onSurface),
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: mine ? colors.onMine : colors.onTheirs,
              fontSize: fontSize,
            ),
          ),
        ),
      if (photos.isNotEmpty) _photoGrid(context, photos),
      for (final v in videos) _videoTile(context, v),
      for (final a in audio)
        AudioMessagePlayer(key: ValueKey(a['uri']), uri: a['uri'] as String),
    ];
    if (parts.isEmpty) {
      parts.add(Text('(empty message)',
          style: theme.textTheme.bodySmall
              ?.copyWith(fontStyle: FontStyle.italic)));
    }

    final column = Column(
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!mine && position.first)
          Padding(
            padding: const EdgeInsets.only(left: Space.m, bottom: 2),
            child: Text(
              (message['sender_name'] as String? ?? '').split(' ').first,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        for (final (i, part) in parts.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
            child: part,
          ),
        if (position.last || bookmarked)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bookmarked) ...[
                  Icon(Icons.bookmark,
                      size: 12, color: theme.colorScheme.primary),
                  const SizedBox(width: 2),
                ],
                Text(formatTime(timestamp), style: monoStyle(context)),
              ],
            ),
          ),
      ],
    );

    return Tooltip(
      message: formatDateTime(timestamp),
      child: GestureDetector(
        onSecondaryTapDown: (d) => _contextMenu(context, d.globalPosition),
        child: Padding(
          padding: EdgeInsets.only(
              top: position.first ? Space.m : 2, left: Space.l, right: Space.l),
          child: Row(
            mainAxisAlignment:
                mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                SizedBox(
                  width: 28,
                  child: position.last
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Avatar(
                              name: message['sender_name'] as String? ?? '?',
                              photoUrl: avatarUrl,
                              size: 28),
                        )
                      : null,
                ),
                const SizedBox(width: Space.s),
              ],
              Flexible(child: column),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoGrid(BuildContext context, List<Map<String, dynamic>> photos) {
    final single = photos.length == 1;
    final cell = single ? 300.0 : 148.0;
    Widget image(int i) {
      final url = ApiService.mediaUrl(photos[i]['uri'] as String);
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openPhotos(context, i),
          onSecondaryTapDown: (d) =>
              _contextMenu(context, d.globalPosition, photo: photos[i]),
          child: CachedNetworkImage(
            imageUrl: url,
            httpHeaders: ApiService.headersFor(url),
            width: cell,
            height: single ? null : cell,
            fit: BoxFit.cover,
            memCacheWidth: (cell * 2).round(),
            placeholder: (_, __) => Container(
              width: cell,
              height: single ? 200 : cell,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            errorWidget: (_, __, ___) => MediaUnavailable(
                width: cell, height: single ? cell * 0.6 : cell),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.bubble),
      child: SizedBox(
        width: single ? cell : cell * 2 + 3,
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [for (var i = 0; i < photos.length; i++) image(i)],
        ),
      ),
    );
  }

  Widget _videoTile(BuildContext context, Map<String, dynamic> video) {
    final url = ApiService.mediaUrl(video['uri'] as String);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoUrl: url))),
        child: Container(
          width: 300,
          height: 188,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.bubble),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D3A4A), Color(0xFF11161C)],
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Color(0xE6FFFFFF), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                size: 32, color: Color(0xFF11161C)),
          ),
        ),
      ),
    );
  }
}
