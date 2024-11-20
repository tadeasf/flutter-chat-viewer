import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';

Future<void> scrollToHighlightedMessage(
    int currentSearchIndex,
    List<int> searchResults,
    ItemScrollController itemScrollController) async {
  if (currentSearchIndex < 0 || 
      currentSearchIndex >= searchResults.length || 
      !itemScrollController.isAttached) {
    return;
  }

  final int messageIndex = searchResults[currentSearchIndex];
  
  try {
    await itemScrollController.scrollTo(
      index: messageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
    );
  } catch (e) {
    debugPrint('Error scrolling to message: $e');
  }
}
