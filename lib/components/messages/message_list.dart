import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'message_item.dart';
import '../ui_utils/custom_scroll_behavior.dart';

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

  Map<String, dynamic> _ensureStringDynamicMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    } else if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    // If it's not a Map at all, return an empty Map
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: ScrollablePositionedList.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = _ensureStringDynamicMap(messages[index]);
          final isHighlighted = isSearchActive &&
              searchResults.contains(index) &&
              searchResults.indexOf(index) == currentSearchIndex;

          return MessageItem(
            message: message,
            isAuthor: message['sender_name'] == 'Tadeáš Fořt',
            isHighlighted: isHighlighted,
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
