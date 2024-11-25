import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:diacritic/diacritic.dart';

Future<List<int>> _computeSearchResults(List<dynamic> params) async {
  final String query = params[0];
  final List<dynamic> messages = params[1];

  final normalizedQuery = removeDiacritics(query.toLowerCase());

  // Handle special search queries
  if (normalizedQuery == "photo" || normalizedQuery == "video") {
    int totalMedia = 0;
    List<int> mediaIndices = [];
    bool searchingForPhotos = normalizedQuery == "photo";

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final senderName = message['sender_name']?.toString().toLowerCase() ?? '';

      if (senderName == "tadeáš fořt") continue; // Skip author's messages

      if (searchingForPhotos) {
        final hasPhotos =
            message['photos'] != null && (message['photos'] as List).isNotEmpty;
        if (hasPhotos) {
          totalMedia += (message['photos'] as List).length;
          mediaIndices.add(i);
        }
      } else {
        // searching for videos
        final hasVideos =
            message['videos'] != null && (message['videos'] as List).isNotEmpty;
        if (hasVideos) {
          totalMedia += (message['videos'] as List).length;
          mediaIndices.add(i);
        }
      }
    }

    if (kDebugMode) {
      print('Total messages: ${messages.length}');
      print(
          'Total ${searchingForPhotos ? "photo" : "video"} messages found: ${mediaIndices.length}');
      print(
          'Total ${searchingForPhotos ? "photos" : "videos"} count: $totalMedia');
    }

    return mediaIndices;
  }

  // Regular text search
  return List<int>.generate(messages.length, (i) {
    final message = messages[i];
    final content = message['content']?.toString().toLowerCase() ?? '';
    final senderName = message['sender_name']?.toString().toLowerCase() ?? '';

    return (removeDiacritics(content).contains(normalizedQuery) ||
            removeDiacritics(senderName).contains(normalizedQuery))
        ? i
        : -1;
  }).where((i) => i != -1).toList();
}

void searchMessages(
    String query,
    Timer? debounce,
    Function setState,
    List<dynamic> messages,
    Function scrollToHighlightedMessage,
    Function(List<int>) updateSearchResults,
    Function(int) updateCurrentSearchIndex,
    Function(bool) updateIsSearchActive,
    String? selectedCollection) {
  if (query.isEmpty) {
    setState(() {
      updateSearchResults([]);
      updateCurrentSearchIndex(-1);
      updateIsSearchActive(false);
    });
    return;
  }

  compute(_computeSearchResults, [query, messages]).then((results) {
    if (results.isNotEmpty) {
      setState(() {
        updateSearchResults(results);
        updateIsSearchActive(true);
        updateCurrentSearchIndex(0);
        Future.microtask(() => scrollToHighlightedMessage(0));
      });
    } else {
      setState(() {
        updateSearchResults([]);
        updateCurrentSearchIndex(-1);
        updateIsSearchActive(false);
      });
    }
  });
}
