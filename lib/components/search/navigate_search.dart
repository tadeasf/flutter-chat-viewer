void navigateSearch(
    int direction,
    List<int> searchResults,
    int currentSearchIndex,
    Function(int) updateCurrentSearchIndex,
    Function scrollToHighlightedMessage) {
  if (searchResults.isEmpty) return;

  int newIndex = (currentSearchIndex + direction) % searchResults.length;
  if (newIndex < 0) newIndex = searchResults.length - 1;

  updateCurrentSearchIndex(newIndex);
  scrollToHighlightedMessage();
}
