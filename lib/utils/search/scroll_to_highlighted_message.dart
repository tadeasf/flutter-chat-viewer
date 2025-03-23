import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'search_type.dart';

final Logger _logger = Logger('ScrollToHighlightedMessage');

/// Scroll to a highlighted message in the list
///
/// [index] - The index of the message to scroll to
/// [allHighlightedIndices] - All highlighted indices for context
/// [itemScrollController] - The controller for the list
/// [searchType] - The type of search operation
Future<void> scrollToHighlightedMessage(
  int index,
  List<int> allHighlightedIndices,
  ItemScrollController itemScrollController,
  SearchType searchType,
) async {
  try {
    if (!itemScrollController.isAttached) {
      _logger.info('ScrollController not attached, waiting...');

      // Increase delay for cross-collection search to ensure list has fully loaded
      final delay = searchType == SearchType.crossCollection
          ? const Duration(milliseconds: 500)
          : const Duration(milliseconds: 200);

      await Future.delayed(delay);
      if (!itemScrollController.isAttached) {
        _logger.warning('ScrollController still not attached after delay');
        return;
      }
    }

    // For cross-collection searches, we use the index directly
    // For regular searches, we look up the index in searchResults
    final targetIndex = searchType == SearchType.searchWidget &&
            allHighlightedIndices.isNotEmpty
        ? allHighlightedIndices[index]
        : index;

    // Use different alignment for different search types
    double alignment;
    switch (searchType) {
      case SearchType.crossCollection:
        alignment = 0.1;
        break;
      case SearchType.photoView:
        alignment = 0.5; // Center for photo view
        break;
      default:
        alignment = 0.3; // Default alignment
    }

    _logger.info(
        'Scrolling to message at index $targetIndex, search type: $searchType');

    await itemScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      alignment: alignment,
    );
  } catch (e) {
    _logger.severe('Error scrolling to message: $e');
  }
}
