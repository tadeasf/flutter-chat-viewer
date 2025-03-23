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
  bool _isLoadingMore = false;
  bool _showScrollToBottomButton = false;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    // Listen to scroll positions
    widget.itemPositionsListener.itemPositions.addListener(_onPositionsChange);
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions
        .removeListener(_onPositionsChange);
    super.dispose();
  }

  void _onPositionsChange() {
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Get message store
    final messageStore = StoreProvider.of(context).messageStore;

    // Check if we need to load more messages (when we're near the end)
    if (!_isLoadingMore &&
        !messageStore.isLoading &&
        messageStore.hasMoreMessages &&
        !widget.isCrossCollectionSearch) {
      final lastVisibleItem = positions.last.index;
      if (lastVisibleItem >= widget.messages.length - 10) {
        _loadMoreMessages();
      }
    }

    // Show/hide scroll to bottom button
    if (positions.length > 1) {
      final firstVisibleItem = positions.first.index;
      final newShowButton = firstVisibleItem > 20;

      // Track scroll direction
      final visibleItemPositions = positions.toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      if (visibleItemPositions.isNotEmpty) {
        final currentOffset = visibleItemPositions.first.itemLeadingEdge;
        final isScrollingDown = currentOffset < _lastScrollOffset;
        _lastScrollOffset = currentOffset;

        if (newShowButton != _showScrollToBottomButton && mounted) {
          setState(() {
            _showScrollToBottomButton = newShowButton && isScrollingDown;
          });
        }
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Get message store
    final messageStore = StoreProvider.of(context).messageStore;

    // Load more messages
    await messageStore.loadMoreMessages();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _scrollToBottom() {
    if (widget.messages.isEmpty) return;

    widget.itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    final messageStore = StoreProvider.of(context).messageStore;

    // Update messages in the store
    messageIndexStore.updateMessagesFromRaw(widget.messages);

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: CustomScrollBehavior(),
          child: Observer(
            builder: (_) => ScrollablePositionedList.builder(
              itemCount: widget.messages.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final message =
                    Map<String, dynamic>.from(widget.messages[index]);
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
        ),

        // Loading indicator at the bottom when loading more messages
        if (messageStore.isLoading && !widget.isCrossCollectionSearch)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading more messages...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Scroll to bottom button
        if (_showScrollToBottomButton)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: _scrollToBottom,
              child: Icon(
                Icons.arrow_downward,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
