import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:diacritic/diacritic.dart';

Future<List<int>> _computeSearchResults(List<dynamic> params) async {
  final String query = params[0];
  final List<dynamic> messages = params[1];

  final normalizedQuery = removeDiacritics(query.toLowerCase());

  if (normalizedQuery == "photo") {
    // Debug: Print total messages and photos found
    int totalPhotos = 0;
    List<int> photoIndices = [];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final senderName = message['sender_name']?.toString().toLowerCase() ?? '';
      final hasPhotos =
          message['photos'] != null && (message['photos'] as List).isNotEmpty;

      if (hasPhotos && senderName != "tadeáš fořt") {
        totalPhotos += (message['photos'] as List).length;
        photoIndices.add(i);
      }
    }

    if (kDebugMode) {
      print('Total messages: ${messages.length}');
    }
    if (kDebugMode) {
      print('Total photo messages found: ${photoIndices.length}');
    }
    if (kDebugMode) {
      print('Total photos count: $totalPhotos');
    }

    return photoIndices;
  }

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
