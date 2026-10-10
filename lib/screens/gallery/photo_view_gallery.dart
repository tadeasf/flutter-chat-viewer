import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../components/ui_utils/media_unavailable.dart';
import '../../theme.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/download.dart';
import '../../utils/js_util.dart';
import '../../utils/text_match.dart';

/// Full-window photo viewer. Dark in both themes.
/// Keys: left/right to move, Esc to close.
class PhotoViewGalleryScreen extends StatefulWidget {
  /// Photo objects with `uri` and, when known, `message_timestamp`.
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  final String title;

  /// Closes the viewer and shows the photo's message in the chat.
  final void Function(Map<String, dynamic> photo)? onShowInChat;

  const PhotoViewGalleryScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.title,
    this.onShowInChat,
  });

  @override
  State<PhotoViewGalleryScreen> createState() => _PhotoViewGalleryScreenState();
}

class _PhotoViewGalleryScreenState extends State<PhotoViewGalleryScreen> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  final _strip = ScrollController();
  late int _index = widget.initialIndex;

  static const _thumb = 56.0;
  static const _fg = Color(0xFFE8EDED);
  static const _bg = Color(0xFF0B0D0E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerStrip());
  }

  @override
  void dispose() {
    _pages.dispose();
    _strip.dispose();
    super.dispose();
  }

  String _url(int i) => ApiService.mediaUrl(widget.photos[i]['uri'] as String);

  void _go(int delta) {
    final target = (_index + delta).clamp(0, widget.photos.length - 1);
    if (target != _index) {
      _pages.animateToPage(target,
          duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    }
  }

  void _centerStrip() {
    if (!_strip.hasClients) return;
    final target = _index * (_thumb + 6) -
        (_strip.position.viewportDimension - _thumb) / 2;
    _strip.animateTo(target.clamp(0, _strip.position.maxScrollExtent),
        duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    final ts = photo['message_timestamp'] as int?;
    final label = [
      if (widget.title.isNotEmpty) widget.title,
      if (ts != null) formatDateTime(ts),
      '${_index + 1} / ${widget.photos.length}',
    ].join(' · ');

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            foregroundColor: _fg,
            title: Text(label,
                style: const TextStyle(fontSize: 14, color: _fg),
                overflow: TextOverflow.ellipsis),
            actions: [
              if (widget.onShowInChat != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: _fg),
                  onPressed: () => widget.onShowInChat!(photo),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Show in chat'),
                ),
              IconButton(
                tooltip: kIsWeb ? 'Open in new tab' : 'Save to Downloads',
                color: _fg,
                onPressed: () => kIsWeb
                    ? openInNewTab(_url(_index))
                    : saveMedia(context, _url(_index)),
                icon: const Icon(Icons.download_rounded),
              ),
              const SizedBox(width: Space.s),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PhotoViewGallery.builder(
                      pageController: _pages,
                      itemCount: widget.photos.length,
                      backgroundDecoration: const BoxDecoration(color: _bg),
                      onPageChanged: (i) {
                        setState(() => _index = i);
                        _centerStrip();
                      },
                      loadingBuilder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      builder: (context, i) => PhotoViewGalleryPageOptions(
                        imageProvider: CachedNetworkImageProvider(_url(i),
                            headers: ApiService.headersFor(_url(i))),
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 3,
                        errorBuilder: (_, __, ___) => const Center(
                            child: MediaUnavailable(width: 240, height: 160)),
                      ),
                    ),
                    if (_index > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _NavButton(
                            icon: Icons.chevron_left, onTap: () => _go(-1)),
                      ),
                    if (_index < widget.photos.length - 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _NavButton(
                            icon: Icons.chevron_right, onTap: () => _go(1)),
                      ),
                  ],
                ),
              ),
              if (widget.photos.length > 1)
                SizedBox(
                  height: _thumb + 24,
                  child: ListView.separated(
                    controller: _strip,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.l, vertical: Space.m),
                    itemCount: widget.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _pages.jumpToPage(i),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: i == _index ? 1 : 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Radii.s),
                            border: i == _index
                                ? Border.all(
                                    color: const Color(0xFF85D2DB), width: 2)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.s - 1),
                            child: CachedNetworkImage(
                              imageUrl: _url(i),
                              httpHeaders: ApiService.headersFor(_url(i)),
                              width: _thumb,
                              height: _thumb,
                              memCacheWidth: (_thumb * 2).round(),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const MediaUnavailable(
                                      width: _thumb, height: _thumb),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(Space.m),
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x33FFFFFF),
            foregroundColor: Colors.white,
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 28),
        ),
      );
}
