import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../utils/search/search_type.dart';

void navigateSearch(
    int direction,
    List<int> searchResults,
    int currentSearchIndex,
    Function(int) updateCurrentSearchIndex,
    Function(int, List<int>, ItemScrollController, SearchType)
        scrollToHighlightedMessage,
    ItemScrollController itemScrollController) {
  if (searchResults.isEmpty) return;

  int newIndex = (currentSearchIndex + direction) % searchResults.length;
  if (newIndex < 0) newIndex = searchResults.length - 1;

  updateCurrentSearchIndex(newIndex);
  scrollToHighlightedMessage(
    newIndex,
    searchResults,
    itemScrollController,
    SearchType.searchWidget,
  );
}
