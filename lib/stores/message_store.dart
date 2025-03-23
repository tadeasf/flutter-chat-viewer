import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_db/api_service.dart';

// Include the generated file
part 'message_store.g.dart';

// This is the class used by rest of the codebase
class MessageStore = MessageStoreBase with _$MessageStore;

// The store class
abstract class MessageStoreBase with Store {
  final Logger _logger = Logger('MessageStore');

  // Cache time for messages (10 minutes)
  final Duration _messageCacheTime = const Duration(minutes: 10);

  // Observable lists for messages
  @observable
  ObservableList<Map<String, dynamic>> messages =
      ObservableList<Map<String, dynamic>>();

  // Observable list for filtered messages by date
  @observable
  ObservableList<Map<String, dynamic>> filteredMessages =
      ObservableList<Map<String, dynamic>>();

  // Current collection name
  @observable
  String? currentCollection;

  // Timestamp for last fetch
  @observable
  DateTime lastMessageFetch = DateTime.fromMillisecondsSinceEpoch(0);

  // Loading state
  @observable
  bool isLoading = false;

  // Error state
  @observable
  String? errorMessage;

  // Date range filters
  @observable
  DateTime? fromDate;

  @observable
  DateTime? toDate;

  // Cross-collection search results
  @observable
  ObservableList<Map<String, dynamic>> searchResults =
      ObservableList<Map<String, dynamic>>();

  // Search is active
  @observable
  bool isSearchActive = false;

  // Current search query
  @observable
  String? searchQuery;

  // Observable for cross-collection search
  @observable
  bool isCrossCollectionSearching = false;

  // Observable for cross-collection search results
  @observable
  ObservableList<Map<String, dynamic>> crossCollectionResults =
      ObservableList<Map<String, dynamic>>();

  // Computed property to check if message cache needs refresh
  @computed
  bool get needsMessageRefresh =>
      DateTime.now().difference(lastMessageFetch) > _messageCacheTime;

  // Computed property for active date filtering
  @computed
  bool get hasDateFilter => fromDate != null || toDate != null;

  // Action to change collection and load messages
  @action
  Future<void> setCollection(String? collectionName) async {
    if (collectionName == currentCollection &&
        messages.isNotEmpty &&
        !needsMessageRefresh) {
      return; // No need to reload if collection hasn't changed and cache is valid
    }

    // Clear current messages and set loading state
    messages.clear();
    filteredMessages.clear();
    errorMessage = null;
    isLoading = true;
    currentCollection = collectionName;

    // Reset date filters
    fromDate = null;
    toDate = null;

    if (collectionName == null) {
      isLoading = false;
      return;
    }

    try {
      // Try to load from cache first
      final cachedMessages = await _loadFromCache(collectionName);

      if (cachedMessages.isNotEmpty) {
        messages.addAll(cachedMessages);
        filteredMessages.addAll(cachedMessages);

        // If cache is old, refresh in background
        if (needsMessageRefresh) {
          _fetchMessages(collectionName, updateUI: false);
        } else {
          isLoading = false;
        }
      } else {
        // No cache, fetch directly
        await _fetchMessages(collectionName);
      }
    } catch (e) {
      _logger.warning('Error setting collection: $e');
      errorMessage = 'Failed to load messages: $e';
      isLoading = false;
    }
  }

  // Action to refresh messages for current collection
  @action
  Future<void> refreshMessages() async {
    if (currentCollection == null) return;

    isLoading = true;
    errorMessage = null;

    try {
      await _fetchMessages(currentCollection!, forceRefresh: true);
    } catch (e) {
      _logger.warning('Error refreshing messages: $e');
      errorMessage = 'Failed to refresh messages: $e';
      isLoading = false;
    }
  }

  // Action to fetch messages with date range filtering
  @action
  Future<void> fetchMessagesForDateRange(
      String collectionName, DateTime? from, DateTime? to) async {
    isLoading = true;
    errorMessage = null;
    fromDate = from;
    toDate = to;

    // If collection has changed, clear and load new collection
    if (collectionName != currentCollection) {
      await setCollection(collectionName);
    }

    // Apply date filters to existing messages
    _applyDateFilter();
    isLoading = false;
  }

  // Private method to apply date filters to messages
  void _applyDateFilter() {
    filteredMessages.clear();

    if (!hasDateFilter) {
      // If no date filters, use all messages
      filteredMessages.addAll(messages);
      return;
    }

    // Filter messages by date range
    final filtered = messages.where((message) {
      final timestamp = message['timestamp_ms'] as int? ?? 0;
      final messageDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Apply from date filter
      if (fromDate != null) {
        final fromStart =
            DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
        if (messageDate.isBefore(fromStart)) {
          return false;
        }
      }

      // Apply to date filter
      if (toDate != null) {
        final toEnd =
            DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
        if (messageDate.isAfter(toEnd)) {
          return false;
        }
      }

      return true;
    }).toList();

    filteredMessages.addAll(filtered);
  }

  // Action to search messages
  @action
  Future<void> searchMessages(String query,
      {bool isCrossCollection = false}) async {
    searchResults.clear();
    searchQuery = query;
    isSearchActive = true;

    if (isCrossCollection) {
      try {
        final results = await ApiService.performCrossCollectionSearch(query);
        _processCrossCollectionResults(results);
      } catch (e) {
        _logger.warning('Error in cross-collection search: $e');
        errorMessage = 'Search failed: $e';
      }
    } else {
      // Local search in current filtered messages
      if (filteredMessages.isEmpty || currentCollection == null) return;

      searchResults.addAll(filteredMessages.where((message) {
        final content = message['content']?.toString().toLowerCase() ?? '';
        final sender = message['sender_name']?.toString().toLowerCase() ?? '';
        return content.contains(query.toLowerCase()) ||
            sender.contains(query.toLowerCase());
      }).toList());
    }
  }

  // Action to clear search
  @action
  void clearSearch() {
    searchResults.clear();
    searchQuery = null;
    isSearchActive = false;
  }

  // Private method to fetch messages from API
  Future<void> _fetchMessages(String? collectionName,
      {bool updateUI = true, bool forceRefresh = false}) async {
    if (collectionName == null) return;

    try {
      final loadedMessages = await ApiService.fetchMessages(collectionName);

      // Process and convert messages
      final processedMessages = loadedMessages.map((message) {
        if (message is! Map) return <String, dynamic>{};
        return Map<String, dynamic>.from(message);
      }).toList();

      // Update cache
      await _saveToCache(collectionName, processedMessages);

      // Update UI if needed
      if (updateUI) {
        messages.clear();
        messages.addAll(processedMessages);

        // Apply date filters if active
        _applyDateFilter();

        lastMessageFetch = DateTime.now();
        isLoading = false;
      }
    } catch (e) {
      _logger.warning('Error fetching messages: $e');

      if (updateUI) {
        errorMessage = 'Failed to load messages: $e';
        isLoading = false;

        // Try loading from cache as fallback
        if (messages.isEmpty) {
          final cachedMessages = await _loadFromCache(collectionName);
          if (cachedMessages.isNotEmpty) {
            messages.addAll(cachedMessages);
            // Apply date filters to cached messages too
            _applyDateFilter();
          }
        }
      }
    }
  }

  // Process cross-collection search results
  void _processCrossCollectionResults(List<dynamic> results) {
    searchResults.clear();

    final processed = results.map((result) {
      if (result is! Map) return <String, dynamic>{};

      // Check if this is an Instagram message by the presence of is_geoblocked_for_viewer
      final isInstagramMessage = result.containsKey('is_geoblocked_for_viewer');

      return {
        'content': _decodeIfNeeded(result['content']),
        'sender_name': _decodeIfNeeded(result['sender_name']),
        'collectionName': _decodeIfNeeded(result['collectionName']),
        'timestamp_ms': result['timestamp_ms'] ?? 0,
        'photos': result['photos'] ?? [],
        'is_geoblocked_for_viewer': result['is_geoblocked_for_viewer'],
        'is_online': result['is_online'] ?? false,
        'is_instagram': isInstagramMessage, // Add this flag for styling
      };
    }).toList();

    searchResults.addAll(processed);
  }

  // Helper method to decode text if needed
  String _decodeIfNeeded(dynamic text) {
    if (text == null) return '';
    try {
      return utf8.decode(text.toString().codeUnits);
    } catch (e) {
      return text.toString();
    }
  }

  // Cache operations - save messages to cache
  Future<void> _saveToCache(
      String collectionName, List<dynamic> messagesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a cache key for this collection
      final cacheKey = 'messages_${collectionName.replaceAll(' ', '_')}';

      // Store messages as JSON string
      await prefs.setString(cacheKey, json.encode(messagesList));

      // Store timestamp
      await prefs.setInt(
          '${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.warning('Error saving messages to cache: $e');
    }
  }

  // Load messages from cache
  Future<List<Map<String, dynamic>>> _loadFromCache(
      String collectionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a cache key for this collection
      final cacheKey = 'messages_${collectionName.replaceAll(' ', '_')}';

      // Get cached data
      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt('${cacheKey}_timestamp') ?? 0;

      if (cachedData != null) {
        // Update last fetch time based on cache timestamp
        lastMessageFetch = DateTime.fromMillisecondsSinceEpoch(timestamp);

        // Decode and return messages
        return List<Map<String, dynamic>>.from(
            json.decode(cachedData).map((m) => Map<String, dynamic>.from(m)));
      }
    } catch (e) {
      _logger.warning('Error loading messages from cache: $e');
    }

    return [];
  }

  // Action to search across all collections
  @action
  Future<void> searchAcrossCollections(String query) async {
    if (query.isEmpty) {
      crossCollectionResults.clear();
      return;
    }

    isCrossCollectionSearching = true;
    crossCollectionResults.clear();

    try {
      final results = await ApiService.searchAcrossCollections(query);

      // Process search results
      final processedResults = results.map<Map<String, dynamic>>((result) {
        if (result is! Map) return <String, dynamic>{};

        // Check if this is an Instagram message
        final isInstagramMessage =
            result.containsKey('is_geoblocked_for_viewer');

        return Map<String, dynamic>.from({
          'content': _decodeIfNeeded(result['content']),
          'sender_name': _decodeIfNeeded(result['sender_name']),
          'collectionName': _decodeIfNeeded(result['collectionName']),
          'timestamp_ms': result['timestamp_ms'] ?? 0,
          'photos': result['photos'] ?? [],
          'is_geoblocked_for_viewer': result['is_geoblocked_for_viewer'],
          'is_online': result['is_online'] ?? false,
          'is_instagram': isInstagramMessage,
        });
      }).toList();

      crossCollectionResults.addAll(processedResults);
      isCrossCollectionSearching = false;
    } catch (e) {
      _logger.warning('Error searching across collections: $e');
      isCrossCollectionSearching = false;
      errorMessage = 'Failed to search across collections: ${e.toString()}';
    }
  }
}
