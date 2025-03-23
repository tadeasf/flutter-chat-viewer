import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'message_item.dart';
import '../ui_utils/custom_scroll_behavior.dart';
import '../../stores/store_provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class MessageList extends StatefulWidget {
  final List<Map<dynamic, dynamic>> messages;
  final List<int> searchResults;
  final int currentSearchIndex;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final bool isSearchActive;
  final String selectedCollectionName;
  final String? profilePhotoUrl;
  final bool isCrossCollectionSearch;
  final Function(String collectionName, int timestamp) onMessageTap;

  const MessageList({
    super.key,
    required this.messages,
    required this.searchResults,
    required this.currentSearchIndex,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isSearchActive,
    required this.selectedCollectionName,
    required this.profilePhotoUrl,
    required this.isCrossCollectionSearch,
    required this.onMessageTap,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  @override
  void initState() {
    super.initState();
  }

  bool isHighlighted(int index) {
    if (!widget.isSearchActive ||
        widget.searchResults.isEmpty ||
        widget.currentSearchIndex < 0) {
      return false;
    }

    final targetIndex = widget.searchResults[widget.currentSearchIndex];
    return index == targetIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Get the MessageIndexStore from provider
    final messageIndexStore = StoreProvider.of(context).messageIndexStore;

    // Update messages in the store
    messageIndexStore.updateMessagesFromRaw(widget.messages);

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: Observer(
        builder: (_) => ScrollablePositionedList.builder(
          itemCount: widget.messages.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final message = Map<String, dynamic>.from(widget.messages[index]);
            final collectionName = widget.isCrossCollectionSearch
                ? message['collectionName']
                : widget.selectedCollectionName;

            return MessageItem(
              message: Map<String, dynamic>.from({
                ...message,
                'is_instagram': message['is_instagram'] ??
                    message.containsKey('is_geoblocked_for_viewer'),
              }),
              isAuthor: message['sender_name'] == 'Tadeáš Fořt',
              isHighlighted: isHighlighted(index),
              isSearchActive: widget.isSearchActive,
              selectedCollectionName: collectionName,
              profilePhotoUrl: widget.profilePhotoUrl,
              isCrossCollectionSearch: widget.isCrossCollectionSearch,
              onMessageTap: widget.onMessageTap,
              messages: widget.messages,
              itemScrollController: widget.itemScrollController,
            );
          },
          itemScrollController: widget.itemScrollController,
          itemPositionsListener: widget.itemPositionsListener,
          // Add performance optimizations
          minCacheExtent: 800, // Cache more items for smoother scrolling
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}
