import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/animation.dart'; // Import the animation package

void scrollToHighlightedMessage(int currentSearchIndex, List<int> searchResults,
    ItemScrollController itemScrollController) {
  if (currentSearchIndex >= 0 && currentSearchIndex < searchResults.length) {
    final int messageIndex = searchResults[currentSearchIndex];
    itemScrollController.scrollTo(
      index: messageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves
          .easeInOutCubic, // This will align the item to the top of the viewport
      alignment: 0.0,
    );
  }
}
