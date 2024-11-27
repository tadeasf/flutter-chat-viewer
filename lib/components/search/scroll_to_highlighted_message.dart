import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'search_type.dart';

Future<void> scrollToHighlightedMessage(int index, List<int> searchResults,
    ItemScrollController itemScrollController, SearchType searchType) async {
  if (!itemScrollController.isAttached) {
    if (kDebugMode) {
      print('ScrollController not attached, waiting...');
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (!itemScrollController.isAttached) {
      if (kDebugMode) {
        print('ScrollController still not attached after delay');
      }
      return;
    }
  }

  final targetIndex =
      searchType == SearchType.searchWidget ? searchResults[index] : index;

  try {
    await itemScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error scrolling to message: $e');
    }
  }
}
