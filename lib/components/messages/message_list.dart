import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../stores/message_store.dart';
import '../ui_utils/custom_scroll_behavior.dart';
import 'message_item.dart';

const ownerName = 'Tadeáš Fořt';

/// The loaded window of a conversation.
///
/// Messages before the store's anchor are laid out upwards from it and the
/// rest downwards, so pages loaded at either end never move what is on
/// screen. Scrolling near either end loads the next page.
class MessageList extends StatefulWidget {
  final MessageStore store;
  final String? profilePhotoUrl;

  const MessageList({
    super.key,
    required this.store,
    required this.profilePhotoUrl,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  static const _centerKey = ValueKey('anchor');
  static const _loadAhead = 1500.0;
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (m.pixels - m.minScrollExtent < _loadAhead) widget.store.loadOlder();
    if (m.maxScrollExtent - m.pixels < _loadAhead) widget.store.loadNewer();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final store = widget.store;
      final messages = store.messages;
      final anchor = store.anchor;
      final count = messages.length;
      final highlightId = store.highlightId;

      Widget item(int i) {
        final message = messages[i];
        return MessageItem(
          key: ValueKey(message['_id'] ?? i),
          message: message,
          isAuthor: message['sender_name'] == ownerName,
          isHighlighted: highlightId != null && message['_id'] == highlightId,
          selectedCollectionName: store.collection ?? '',
          profilePhotoUrl: widget.profilePhotoUrl,
          isCrossCollectionSearch: false,
          onMessageTap: (_, __) {},
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ScrollConfiguration(
          behavior: CustomScrollBehavior(),
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
            ],
          ),
        ),
      );
    });
  }
}
