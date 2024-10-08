import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:diacritic/diacritic.dart';

void searchMessages(
    String query,
    Timer? debounce,
    Function setState,
    List<dynamic> messages,
    Function scrollToHighlightedMessage,
    Function updateSearchResults,
    Function updateCurrentSearchIndex,
    Function updateIsSearchActive,
    String? selectedCollection) {
  if (debounce?.isActive ?? false) debounce!.cancel();
  debounce = Timer(const Duration(milliseconds: 500), () {
    if (query.isEmpty) {
      setState(() {
        updateSearchResults([]);
        updateCurrentSearchIndex(-1);
        updateIsSearchActive(false);
      });
    } else {
      final normalizedQuery = removeDiacritics(query.toLowerCase());
      List<int> newSearchResults = [];

      for (int i = 0; i < messages.length; i++) {
        final currentMessage = messages[i];
        final normalizedMessageContent = currentMessage['content'] != null
            ? removeDiacritics(currentMessage['content'].toLowerCase())
            : "";

        if (normalizedMessageContent.contains(normalizedQuery) ||
            (normalizedQuery == "photo" &&
                currentMessage['photos'] != null &&
                currentMessage['photos'].isNotEmpty &&
                currentMessage['sender_name'] != "Tadeáš Fořt")) {
          newSearchResults.add(i);
        }
      }

      setState(() {
        updateSearchResults(newSearchResults);
        if (newSearchResults.isNotEmpty) {
          updateCurrentSearchIndex(0);
          updateIsSearchActive(true);
          scrollToHighlightedMessage(newSearchResults[0]);
        } else {
          updateCurrentSearchIndex(-1);
          updateIsSearchActive(false);
          if (kDebugMode) {
            print("No messages with the given content found.");
          }
        }
      });
    }
  });
}

Widget buildSearchBar(
  BuildContext context,
  TextEditingController searchController,
  Function(String) onChanged,
  VoidCallback onClear,
  bool isSearchActive,
  VoidCallback toggleProfilePhotoVisibility,
  bool isProfilePhotoVisible,
) {
  return Row(
    children: [
      Expanded(
        child: TextField(
          controller: searchController,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: isSearchActive
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ),
      IconButton(
        icon: Icon(
            isProfilePhotoVisible ? Icons.visibility_off : Icons.visibility),
        onPressed: toggleProfilePhotoVisibility,
        tooltip:
            isProfilePhotoVisible ? 'Hide Profile Photo' : 'Show Profile Photo',
      ),
    ],
  );
}
