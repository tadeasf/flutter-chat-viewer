import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/store_provider.dart';
import 'dart:convert';

/// A widget that displays search results across multiple collections
/// and allows navigation to specific messages
class CrossCollectionNavigator extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onNavigationComplete;

  const CrossCollectionNavigator({
    super.key,
    required this.searchQuery,
    this.onNavigationComplete,
  });

  @override
  Widget build(BuildContext context) {
    final messageStore = StoreProvider.of(context).messageStore;
    final navigationStore = StoreProvider.of(context).navigationStore;

    // Helper function to decode text if needed
    String decodeIfNeeded(dynamic text) {
      if (text == null) return '';
      try {
        return utf8.decode(text.toString().codeUnits);
      } catch (e) {
        return text.toString();
      }
    }

    // Show a summary of content based on search query
    String getContentSummary(String content, String query) {
      if (content.isEmpty) return '';

      // Find the index of the query in the content (case insensitive)
      final index = content.toLowerCase().indexOf(query.toLowerCase());
      if (index == -1) {
        return content.length > 100
            ? '${content.substring(0, 100)}...'
            : content;
      }

      // Get a substring of content around the query
      final start = (index - 40) < 0 ? 0 : (index - 40);
      final end = (index + query.length + 40) > content.length
          ? content.length
          : (index + query.length + 40);

      String excerpt = content.substring(start, end);
      if (start > 0) excerpt = '...$excerpt';
      if (end < content.length) excerpt = '$excerpt...';

      return excerpt;
    }

    return Observer(
      builder: (_) {
        if (messageStore.isCrossCollectionSearching) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = messageStore.crossCollectionResults;

        if (results.isEmpty) {
          return const Center(
            child: Text('No matching messages found'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Found ${results.length} results across collections',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final message = results[index];
                  final content = decodeIfNeeded(message['content']);
                  final senderName = decodeIfNeeded(message['sender_name']);
                  final collectionName =
                      decodeIfNeeded(message['collectionName']);
                  final timestamp = message['timestamp_ms'] as int? ?? 0;

                  // Get a content summary that shows context around the search query
                  final contentSummary =
                      getContentSummary(content, searchQuery);

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      title: Text(senderName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contentSummary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Collection: $collectionName',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Date: ${DateTime.fromMillisecondsSinceEpoch(timestamp).toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        // Use NavigationStore to navigate to the specific message
                        final success = await navigationStore.navigateToMessage(
                          context,
                          collectionName,
                          timestamp,
                          onScrollComplete: (int index) {
                            // This will be called when scrolling is complete
                          },
                          popCurrent: true,
                        );

                        // Call onNavigationComplete callback if provided
                        if (success && onNavigationComplete != null) {
                          onNavigationComplete!();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dialog that displays the CrossCollectionNavigator
class CrossCollectionSearchDialog extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onNavigationComplete;

  const CrossCollectionSearchDialog({
    super.key,
    required this.searchQuery,
    this.onNavigationComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required String searchQuery,
    VoidCallback? onNavigationComplete,
  }) async {
    // Perform the search first
    final messageStore = StoreProvider.of(context).messageStore;
    messageStore.searchAcrossCollections(searchQuery);

    return showDialog(
      context: context,
      builder: (context) => CrossCollectionSearchDialog(
        searchQuery: searchQuery,
        onNavigationComplete: onNavigationComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Search results for: "$searchQuery"',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: CrossCollectionNavigator(
                searchQuery: searchQuery,
                onNavigationComplete: () {
                  Navigator.of(context).pop();
                  if (onNavigationComplete != null) {
                    onNavigationComplete!();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
