import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'message_item.dart';
import '../ui_utils/custom_scroll_behavior.dart';
import '../../stores/store_provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class MessageList extends StatelessWidget {
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

  bool isHighlighted(int index) {
    if (!isSearchActive || searchResults.isEmpty || currentSearchIndex < 0) {
      return false;
    }

    final targetIndex = searchResults[currentSearchIndex];
    return index == targetIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Get the MessageIndexStore from provider
    final messageIndexStore = StoreProvider.of(context).messageIndexStore;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Update messages in the store
    messageIndexStore.updateMessagesFromRaw(messages);

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: Observer(
        builder: (_) => Container(
          color: isDarkMode ? Color(0xFF121214) : null,
          child: ScrollablePositionedList.builder(
            itemCount: messages.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final message = Map<String, dynamic>.from(messages[index]);
              final collectionName = isCrossCollectionSearch
                  ? message['collectionName']
                  : selectedCollectionName;

              return MessageItem(
                message: Map<String, dynamic>.from({
                  ...message,
                  'is_instagram': message['is_instagram'] ??
                      message.containsKey('is_geoblocked_for_viewer'),
                }),
                isAuthor: message['sender_name'] == 'Tadeáš Fořt',
                isHighlighted: isHighlighted(index),
                isSearchActive: isSearchActive,
                selectedCollectionName: collectionName,
                profilePhotoUrl: profilePhotoUrl,
                isCrossCollectionSearch: isCrossCollectionSearch,
                onMessageTap: onMessageTap,
                messages: messages,
                itemScrollController: itemScrollController,
              );
            },
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
          ),
        ),
      ),
    );
  }
}
