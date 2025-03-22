import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import '../utils/api_db/load_collections.dart' as collection_loader;

// Include the generated file
part 'collection_store.g.dart';

// This is the class used by rest of the codebase
class CollectionStore = CollectionStoreBase with _$CollectionStore;

// The store class
abstract class CollectionStoreBase with Store {
  final Logger _logger = Logger('CollectionStore');

  // Observable lists for collections
  @observable
  ObservableList<Map<String, dynamic>> collections =
      ObservableList<Map<String, dynamic>>();

  @observable
  ObservableList<Map<String, dynamic>> filteredCollections =
      ObservableList<Map<String, dynamic>>();

  // Observable for loading state
  @observable
  bool isLoading = false;

  // Observable for filter query
  @observable
  String filterQuery = '';

  // Computed property to check if there's an active filter
  @computed
  bool get hasActiveFilter => filterQuery.isNotEmpty;

  // Initialize store
  CollectionStoreBase() {
    // Initial load when store is created
    loadCollections();
  }

  // Action to load collections
  @action
  Future<void> loadCollections() async {
    isLoading = true;

    try {
      await collection_loader.loadCollections((loadedCollections) {
        // Filter out unified_collection from the list
        final filteredList = loadedCollections
            .where((collection) => collection['name'] != 'unified_collection')
            .toList();

        // Sort collections according to requirements
        _sortCollections(filteredList);

        // Update observable lists
        collections.clear();
        collections.addAll(filteredList);

        // Apply current filter if exists
        _applyFilter();

        isLoading = false;
      });
    } catch (e) {
      _logger.warning('Error loading collections: $e');
      isLoading = false;
    }
  }

  // Action to load more collections (for pagination)
  @action
  Future<void> loadMoreCollections() async {
    if (isLoading) return;

    isLoading = true;

    try {
      final newCollections = await collection_loader.loadMoreCollections();

      // Filter out unified_collection from new collections too
      final filteredNewCollections = newCollections
          .where((collection) => collection['name'] != 'unified_collection')
          .toList();

      // Add to existing collections
      collections.addAll(filteredNewCollections);

      // Sort all collections
      _sortCollections(collections);

      // Apply current filter
      _applyFilter();

      isLoading = false;
    } catch (e) {
      _logger.warning('Error loading more collections: $e');
      isLoading = false;
    }
  }

  // Action to refresh collections
  @action
  Future<void> refreshCollections() async {
    isLoading = true;

    try {
      // Clear any existing cache
      await collection_loader.retryLoadCollections((loadedCollections) {
        // Filter out unified_collection
        final filteredList = loadedCollections
            .where((collection) => collection['name'] != 'unified_collection')
            .toList();

        // Sort collections
        _sortCollections(filteredList);

        // Update observable lists
        collections.clear();
        collections.addAll(filteredList);

        // Apply current filter
        _applyFilter();

        isLoading = false;
      });
    } catch (e) {
      _logger.warning('Error refreshing collections: $e');
      isLoading = false;
    }
  }

  // Action to set filter query and apply filter
  @action
  void setFilterQuery(String query) {
    filterQuery = query;
    _applyFilter();
  }

  // Internal method to apply filter
  void _applyFilter() {
    if (filterQuery.isEmpty) {
      // If no filter, use all collections
      filteredCollections.clear();
      filteredCollections.addAll(collections);
    } else {
      // Apply filter
      final filtered = collections
          .where((collection) => collection['name']
              .toLowerCase()
              .contains(filterQuery.toLowerCase()))
          .toList();

      filteredCollections.clear();
      filteredCollections.addAll(filtered);
    }
  }

  // Helper method to sort collections by hits DESC, then by message count DESC
  void _sortCollections(List<Map<String, dynamic>> collectionsList) {
    collectionsList.sort((a, b) {
      // First sort by hits in descending order
      final int hitsA = a['hits'] ?? 0;
      final int hitsB = b['hits'] ?? 0;

      final int hitComparison = hitsB.compareTo(hitsA);

      // If hits are the same, sort by message count in descending order
      if (hitComparison == 0) {
        final int messageCountA = a['messageCount'] ?? 0;
        final int messageCountB = b['messageCount'] ?? 0;
        return messageCountB.compareTo(messageCountA);
      }

      return hitComparison;
    });
  }

  // Action to clear filter
  @action
  void clearFilter() {
    filterQuery = '';
    _applyFilter();
  }
}
