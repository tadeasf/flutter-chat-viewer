import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' show ReactionDisposer, reaction;

import '../../screens/gallery/photo_gallery.dart';
import '../../stores/message_store.dart';
import '../../stores/store_provider.dart';
import '../../theme.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/text_match.dart';
import '../avatar.dart';
import 'bookmarks_dialog.dart';
import 'details_dialog.dart';
import 'jump_to_date_dialog.dart';
import 'message_bubble.dart';
import 'message_list.dart';
import 'stats_dialog.dart';
import 'timeline_rail.dart';

/// The open conversation: header, find bar and the message list.
class ChatView extends StatefulWidget {
  final String collection;
  final String? avatarUrl;

  /// Shown in the narrow layout to go back to the list.
  final VoidCallback? onBack;

  /// Called after the profile photo was uploaded or deleted.
  final VoidCallback onProfilePhotoChanged;

  const ChatView({
    super.key,
    required this.collection,
    required this.avatarUrl,
    required this.onProfilePhotoChanged,
    this.onBack,
  });

  @override
  State<ChatView> createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  final _listKey = GlobalKey<MessageListState>();
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  bool _findOpen = false;
  String? _query;
  List<Map<String, dynamic>> _hits = [];
  int _hit = -1;
  bool _searching = false;
  String? _findError;
  Timer? _debounce;

  /// Timestamp of the message at the top of the screen (null: newest).
  final _position = ValueNotifier<int?>(null);
  ReactionDisposer? _windowReaction;

  MessageStore get _store => StoreProvider.of(context).messageStore;

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection != widget.collection) closeFind();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // After a jump nothing has scrolled yet: take the position from the
    // new window's anchor.
    _windowReaction ??= reaction((_) => _store.generation, (_) {
      final store = _store;
      _position.value =
          store.anchoredAtBottom || store.anchor >= store.messages.length
              ? null
              : store.messages[store.anchor]['timestamp_ms'] as int?;
    });
  }

  @override
  void dispose() {
    _windowReaction?.call();
    _position.dispose();
    _debounce?.cancel();
    _findController.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  // ----- actions used by keyboard shortcuts -----

  void openFind() {
    setState(() => _findOpen = true);
    _findFocus.requestFocus();
    _findController.selection =
        TextSelection(baseOffset: 0, extentOffset: _findController.text.length);
  }

  void closeFind() {
    if (!_findOpen) return;
    _debounce?.cancel();
    setState(() {
      _findOpen = false;
      _query = null;
      _hits = [];
      _hit = -1;
      _findError = null;
    });
  }

  void showNewest() => _listKey.currentState?.showNewest();
  void showOldest() => _store.jumpToStart();
  void pageUp() => _listKey.currentState?.scrollByPage(-1);
  void pageDown() => _listKey.currentState?.scrollByPage(1);
  void openPhotos() =>
      PhotoGallery.open(context, widget.collection, title: _title());

  Future<void> openJumpToDate() async {
    final store = _store;
    final timestamp = await showDialog<int>(
      context: context,
      builder: (_) => JumpToDateDialog(store: store),
    );
    if (timestamp != null) await store.jumpTo(timestamp);
  }

  Future<void> openStats() async {
    final store = _store;
    final timestamp = await showDialog<int>(
      context: context,
      builder: (_) => StatsDialog(store: store, title: _title()),
    );
    if (timestamp != null) await store.jumpTo(timestamp);
  }

  Future<void> openBookmarks() async {
    final store = _store;
    final bookmark = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BookmarksDialog(collection: widget.collection),
    );
    if (bookmark != null) {
      await store.jumpTo(bookmark['timestamp_ms'] as int,
          id: bookmark['_id'] as String?);
    }
  }

  Future<void> openDetails() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => DetailsDialog(
        collection: widget.collection,
        title: _title(),
        avatarUrl: widget.avatarUrl,
      ),
    );
    if (changed == true) widget.onProfilePhotoChanged();
  }

  // ----- find in chat (server-side substring search) -----

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _runFind(value.trim()));
  }

  Future<void> _runFind(String query) async {
    if (query == _query && _hits.isNotEmpty) return;
    setState(() {
      _query = query;
      _hits = [];
      _hit = -1;
      _findError = null;
      _searching = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    try {
      final hits =
          await ApiService.search(query, collectionName: widget.collection);
      if (!mounted || _query != query) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
      // Start at the newest hit: the list opens at the newest messages.
      if (hits.isNotEmpty) _showHit(hits.length - 1);
    } catch (e) {
      if (!mounted || _query != query) return;
      setState(() {
        _searching = false;
        _findError = '$e';
      });
    }
  }

  void _showHit(int index) {
    if (_hits.isEmpty) return;
    final i = index % _hits.length;
    setState(() => _hit = i);
    final hit = _hits[i];
    _store.jumpTo(hit['timestamp_ms'] as int, id: hit['_id'] as String?);
  }

  /// Hits are oldest first and the search starts at the newest, so Enter
  /// (and the up arrow) walk back in time.
  void olderHit() => _showHit(_hit - 1);
  void newerHit() => _showHit(_hit + 1);

  // ----- layout -----

  /// The other person's real name (with diacritics) from /stats, or the
  /// conversation's id until that has loaded.
  String _title() {
    final senders = (_store.stats?['senders'] as List?) ?? const [];
    for (final s in senders) {
      final name = s['name'] as String?;
      if (name != null && name != ownerName) return name;
    }
    return widget.collection;
  }

  String _subtitle() {
    final store = _store;
    final stats = store.stats;
    final parts = <String>[
      if (store.total > 0) '${formatCount(store.total)} messages',
      if (stats?['firstMessageAt'] is int && stats?['lastMessageAt'] is int)
        '${DateTime.fromMillisecondsSinceEpoch(stats!['firstMessageAt']).year}'
            ' – ${DateTime.fromMillisecondsSinceEpoch(stats['lastMessageAt']).year}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = _store;

    final header = Observer(
      builder: (_) => Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            if (widget.onBack != null) ...[
              IconButton(
                tooltip: 'Back to conversations',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: Space.xs),
            ],
            Avatar(name: _title(), photoUrl: widget.avatarUrl, size: 36),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title(),
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  Text(_subtitle(), style: monoStyle(context)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Find in chat (Ctrl+F)',
              onPressed: openFind,
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Jump to date (Ctrl+G)',
              onPressed: openJumpToDate,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
            IconButton(
              tooltip: 'Photos (Ctrl+P)',
              onPressed: openPhotos,
              icon: const Icon(Icons.photo_library_outlined),
            ),
            IconButton(
              tooltip: 'Statistics (Ctrl+I)',
              onPressed: openStats,
              icon: const Icon(Icons.insights_outlined),
            ),
            IconButton(
              tooltip: 'Bookmarks (Ctrl+B)',
              onPressed: openBookmarks,
              icon: const Icon(Icons.bookmarks_outlined),
            ),
            IconButton(
              tooltip: 'Details and profile photo',
              onPressed: openDetails,
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );

    final findBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border:
            Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): olderHit,
                const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                    newerHit,
                const SingleActivator(LogicalKeyboardKey.escape): closeFind,
              },
              child: TextField(
                controller: _findController,
                focusNode: _findFocus,
                onChanged: _onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Find in this conversation',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.m),
          SizedBox(
            width: 96,
            child: Text(
              _searching
                  ? 'Searching…'
                  : _findError != null
                      ? 'Error'
                      : _query == null || _query!.isEmpty
                          ? ''
                          : _hits.isEmpty
                              ? 'No results'
                              : '${_hit + 1} / ${_hits.length}',
              textAlign: TextAlign.center,
              style: monoStyle(context, size: 12),
            ),
          ),
          IconButton(
            tooltip: 'Older (Enter)',
            onPressed: _hits.isEmpty ? null : olderHit,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: 'Newer (Shift+Enter)',
            onPressed: _hits.isEmpty ? null : newerHit,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          IconButton(
            tooltip: 'Close (Esc)',
            onPressed: closeFind,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );

    final body = Observer(builder: (_) {
      if (store.isLoading && store.messages.isEmpty) {
        return const _SkeletonMessages();
      }
      if (store.error != null && store.messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 32, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: Space.s),
              Text('Could not load messages',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: Space.xs),
              Text(store.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: Space.m),
              FilledButton.tonal(
                onPressed: () => store.open(widget.collection),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (store.messages.isEmpty) {
        return Center(
            child: Text('This conversation has no messages',
                style: theme.textTheme.bodyMedium));
      }
      return Stack(
        children: [
          MessageList(
            key: _listKey,
            store: store,
            userData: StoreProvider.of(context).userDataStore,
            avatarUrl: widget.avatarUrl,
            query: _findOpen ? _query : null,
            onPosition: (ts) {
              _position.value = ts;
              StoreProvider.of(context)
                  .userDataStore
                  .setPosition(widget.collection, ts);
            },
          ),
          if (store.isLoading)
            const Positioned(
                top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        ],
      );
    });

    return Column(
      children: [
        header,
        if (_findOpen) findBar,
        Expanded(
          child: Row(
            children: [
              Expanded(child: body),
              TimelineRail(store: store, position: _position),
            ],
          ),
        ),
      ],
    );
  }
}

/// Placeholder bubbles while the first page loads.
class _SkeletonMessages extends StatelessWidget {
  const _SkeletonMessages();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    const rows = [
      (false, 220.0),
      (false, 160.0),
      (true, 240.0),
      (false, 280.0),
      (true, 120.0),
      (true, 200.0),
      (false, 180.0),
      (true, 260.0),
    ];
    return ListView(
      reverse: true,
      padding: const EdgeInsets.all(Space.xl),
      children: [
        for (final (mine, width) in rows)
          Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: Space.s),
              width: width,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Radii.bubble),
              ),
            ),
          ),
      ],
    );
  }
}
