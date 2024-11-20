import 'dart:async';
import 'package:diacritic/diacritic.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../messages/message_index_manager.dart';

void searchMessages(
    String query,
    Timer? debounce,
    Function setState,
    List<dynamic> messages,
    Function(int, List<int>, ItemScrollController) scrollToHighlightedMessage,
    Function(List<int>) updateSearchResults,
    Function(int) updateCurrentSearchIndex,
    Function(bool) updateIsSearchActive,
    String? selectedCollection,
    ItemScrollController itemScrollController) {
  // Clear existing results if query is empty
  if (query.isEmpty) {
    setState(() {
      updateSearchResults(<int>[]);
      updateCurrentSearchIndex(-1);
      updateIsSearchActive(false);
    });
    return;
  }

  final normalizedQuery = removeDiacritics(query.toLowerCase());
  List<int> newSearchResults = [];

  // Show loading state
  setState(() {
    updateIsSearchActive(true);
  });

  // Process in chunks to avoid UI freezing
  const chunkSize = 5000;
  int processedCount = 0;

  Future<void> processChunk() async {
    final end = (processedCount + chunkSize) < messages.length
        ? processedCount + chunkSize
        : messages.length;

    final manager = MessageIndexManager();
    manager.updateMessages(messages);

    for (int i = processedCount; i < end; i++) {
      final message = messages[i];
      final timestamp = message['timestamp_ms'] as int;
      final sortedIndex = manager.getIndexForTimestamp(timestamp);

      if (sortedIndex == null) continue;

      if (normalizedQuery == "photo") {
        if (message['photos'] != null && message['photos'].isNotEmpty) {
          newSearchResults.add(sortedIndex);
        }
      } else {
        final normalizedMessageContent = message['content'] != null
            ? removeDiacritics(message['content'].toString().toLowerCase())
            : "";
        final normalizedSenderName = message['sender_name'] != null
            ? removeDiacritics(message['sender_name'].toString().toLowerCase())
            : "";

        if (normalizedMessageContent.contains(normalizedQuery) ||
            normalizedSenderName.contains(normalizedQuery)) {
          newSearchResults.add(sortedIndex);
        }
      }
    }

    processedCount = end;

    // Update progress
    setState(() {
      updateSearchResults(List<int>.from(newSearchResults));
      if (newSearchResults.isNotEmpty) {
        updateCurrentSearchIndex(0);
      }
    });

    // Process next chunk or finish
    if (processedCount < messages.length) {
      await Future.delayed(const Duration(milliseconds: 1));
      await processChunk();
    } else {
      // Final update with scroll
      setState(() {
        if (newSearchResults.isNotEmpty) {
          updateSearchResults(List<int>.from(newSearchResults));
          updateCurrentSearchIndex(0);
          // Delay scroll to ensure UI is updated
          Future.delayed(const Duration(milliseconds: 100), () {
            scrollToHighlightedMessage(
                0, newSearchResults, itemScrollController);
          });
        } else {
          updateCurrentSearchIndex(-1);
        }
      });
    }
  }

  // Start processing
  processChunk();
}
