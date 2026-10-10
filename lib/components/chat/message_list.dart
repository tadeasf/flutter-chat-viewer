import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../stores/message_store.dart';
import '../../stores/user_data_store.dart';
import '../../theme.dart';
import '../../utils/text_match.dart';
import 'message_bubble.dart';

/// The loaded window of a conversation.
///
/// Messages before the store's anchor are laid out upwards from it and the
/// rest downwards, so pages loaded at either end never move what is on
/// screen. Scrolling near either end loads the next page.
class MessageList extends StatefulWidget {
  final MessageStore store;
  final UserDataStore userData;
  final String? avatarUrl;

  /// Text to mark in the bubbles (the find-in-chat query).
  final String? query;

  /// Reading position: the timestamp of the message at the top while away
  /// from the newest messages, null when back at them.
  final ValueChanged<int?>? onPosition;

  const MessageList({
    super.key,
    required this.store,
    required this.userData,
    this.avatarUrl,
    this.query,
    this.onPosition,
  });

  @override
  State<MessageList> createState() => MessageListState();
}

class MessageListState extends State<MessageList> {
  static const _centerKey = ValueKey('anchor');
  static const _loadAhead = 1500.0;
  static const _groupGap = Duration(minutes: 5);

  // The window is replaced on every jump; restoring a saved offset (all
  // lists without a PageStorageKey share one) would hide the anchor.
  final _controller = ScrollController(keepScrollOffset: false);
  final _viewportKey = GlobalKey();
  bool _awayFromEnd = false;
  int _generation = -1;
  int? _floatingDay;
  Timer? _hideDay;

  @override
  void dispose() {
    _hideDay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Newest messages: scrolls down, or reloads the window when newer pages
  /// are not loaded yet.
  Future<void> showNewest() async {
    final store = widget.store;
    if (store.hasNewer) {
      await store.jumpToLatest();
    } else if (_controller.hasClients) {
      await _controller.animateTo(_controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void scrollByPage(double direction) {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    _controller.animateTo(
        (p.pixels + direction * p.viewportDimension * 0.85)
            .clamp(p.minScrollExtent, p.maxScrollExtent),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut);
  }

  bool _onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (m.pixels - m.minScrollExtent < _loadAhead) widget.store.loadOlder();
    if (m.maxScrollExtent - m.pixels < _loadAhead) widget.store.loadNewer();

    final away = m.maxScrollExtent - m.pixels > 400;
    if (away != _awayFromEnd) setState(() => _awayFromEnd = away);

    if (n is ScrollUpdateNotification) {
      final top = _showDayAtTop();
      if (!away && !widget.store.hasNewer) {
        widget.onPosition?.call(null);
      } else if (top != null) {
        widget.onPosition?.call(top);
      }
    }
    return false;
  }

  /// Finds the message at the top of the viewport (each item carries its
  /// timestamp in a MetaData) and shows its day in a floating chip.
  int? _showDayAtTop() {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final result = BoxHitTestResult();
    box.hitTest(result, position: Offset(box.size.width / 2, 12));
    int? ts;
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData && target.metaData is int) {
        ts = target.metaData as int;
        break;
      }
    }
    if (ts == null) return null;
    if (_floatingDay == null || !sameDay(_floatingDay!, ts)) {
      setState(() => _floatingDay = ts);
    }
    _hideDay?.cancel();
    _hideDay = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _floatingDay = null);
    });
    return ts;
  }

  int _ts(Map<String, dynamic> m) => m['timestamp_ms'] as int? ?? 0;

  bool _sameGroup(Map<String, dynamic> a, Map<String, dynamic> b) =>
      a['sender_name'] == b['sender_name'] &&
      (_ts(b) - _ts(a)).abs() < _groupGap.inMilliseconds &&
      sameDay(_ts(a), _ts(b));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Observer(builder: (_) {
      final store = widget.store;
      final messages = store.messages;
      final anchor = store.anchor;
      final count = messages.length;
      final highlightId = store.highlightId;
      final hasOlder = store.hasOlder;
      final hasNewer = store.hasNewer;
      if (store.generation != _generation) {
        // A new window starts at its anchor; nothing is scrolled yet.
        _generation = store.generation;
        _awayFromEnd = false;
      }
      final collection = store.collection ?? '';
      final bookmarkIds = {
        for (final b in widget.userData.bookmarks[collection] ?? const [])
          b['_id']
      };

      Widget item(int i) {
        final message = messages[i];
        final prev = i > 0 ? messages[i - 1] : null;
        final next = i < count - 1 ? messages[i + 1] : null;
        final newDay =
            prev == null ? !hasOlder : !sameDay(_ts(prev), _ts(message));
        return MetaData(
          key: ValueKey(message['_id'] ?? i),
          metaData: _ts(message),
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newDay) _DayChip(timestamp: _ts(message)),
              MessageBubble(
                message: message,
                position: GroupPosition(
                  first: prev == null || newDay || !_sameGroup(prev, message),
                  last: next == null || !_sameGroup(message, next),
                ),
                highlighted:
                    highlightId != null && message['_id'] == highlightId,
                query: widget.query,
                avatarUrl: widget.avatarUrl,
                bookmarked: bookmarkIds.contains(message['_id']),
                onToggleBookmark: () =>
                    widget.userData.toggleBookmark(collection, message),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Scrollbar(
              key: _viewportKey,
              controller: _controller,
              // A new scroll view per window, so it starts at the anchor
              // instead of keeping the previous window's offset.
              child: CustomScrollView(
                key: ValueKey(store.generation),
                controller: _controller,
                center: _centerKey,
                anchor: store.anchoredAtBottom ? 1.0 : 0.2,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => item(anchor - 1 - i),
                      childCount: anchor,
                    ),
                  ),
                  SliverList(
                    key: _centerKey,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => item(anchor + i),
                      childCount: count - anchor,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
                ],
              ),
            ),
          ),
          Positioned(
            top: Space.s,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _floatingDay == null ? 0 : 1,
                child: Center(
                  child: _floatingDay == null
                      ? const SizedBox.shrink()
                      : _DayChip(timestamp: _floatingDay!, floating: true),
                ),
              ),
            ),
          ),
          Positioned(
            right: Space.xl,
            bottom: Space.l,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: hasNewer || _awayFromEnd ? 1 : 0,
              child: FloatingActionButton.extended(
                heroTag: null,
                elevation: 2,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
                onPressed: showNewest,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                label: const Text('Newest'),
                tooltip: 'Newest messages (End)',
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _DayChip extends StatelessWidget {
  final int timestamp;
  final bool floating;

  const _DayChip({required this.timestamp, this.floating = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: floating
            ? EdgeInsets.zero
            : const EdgeInsets.only(top: Space.l, bottom: Space.xs),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(999),
          boxShadow: floating
              ? const [BoxShadow(blurRadius: 4, color: Color(0x22000000))]
              : null,
        ),
        child: Text(formatDay(timestamp),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ),
    );
  }
}
