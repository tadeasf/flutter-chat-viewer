import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'message_item.dart';
import '../ui_utils/custom_scroll_behavior.dart';
import 'message_index_manager.dart';

class MessageList extends StatelessWidget {
  final List<dynamic> messages;
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
  Widget build(BuildContext context) {
    final manager = MessageIndexManager();
    manager.updateMessages(messages);

    final updatedSearchResults = searchResults;

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: ScrollablePositionedList.builder(
        itemCount: manager.sortedMessages.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final message = manager.sortedMessages[index];
          final isHighlighted = isSearchActive &&
              updatedSearchResults.contains(index) &&
              updatedSearchResults.indexOf(index) == currentSearchIndex;

          return MessageItem(
            message: message,
            isAuthor: message['sender_name'] == 'Tadeáš Fořt',
            isHighlighted: isHighlighted,
            isSearchActive: isSearchActive,
            selectedCollectionName: selectedCollectionName,
            profilePhotoUrl: profilePhotoUrl,
            isCrossCollectionSearch: isCrossCollectionSearch,
            onMessageTap: onMessageTap,
          );
        },
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
      ),
    );
  }
}
