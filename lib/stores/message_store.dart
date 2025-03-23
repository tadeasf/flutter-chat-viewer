import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_db/api_service.dart';
import 'package:diacritic/diacritic.dart';

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

  // Search index for faster text searches
  @observable
  ObservableMap<String, Map<String, List<int>>> searchIndex =
      ObservableMap<String, Map<String, List<int>>>();

  // Pagination parameters
  @observable
  int messagePageSize = 100;

  @observable
  bool hasMoreMessages = true;

  @observable
  int totalMessagesLoaded = 0;

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

        // Build search index for faster searches
        _buildSearchIndex(collectionName);

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
    hasMoreMessages = true;
    totalMessagesLoaded = 0;

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

      // Use indexed search if available
      if (searchIndex.containsKey(currentCollection!) &&
          query.trim().isNotEmpty) {
        final matchingIndices = _searchWithIndex(query);

        // Convert indices to messages
        for (final index in matchingIndices) {
          if (index >= 0 && index < filteredMessages.length) {
            searchResults.add(filteredMessages[index]);
          }
        }

        _logger.info(
            'Index search found ${searchResults.length} results for "$query"');
      } else {
        // Fallback to traditional search
        searchResults.addAll(filteredMessages.where((message) {
          final content = message['content']?.toString().toLowerCase() ?? '';
          final sender = message['sender_name']?.toString().toLowerCase() ?? '';
          return content.contains(query.toLowerCase()) ||
              sender.contains(query.toLowerCase());
        }).toList());
      }
    }
  }

  // Action to clear search
  @action
  void clearSearch() {
    searchResults.clear();
    searchQuery = null;
    isSearchActive = false;
  }

  // Action to load more messages (pagination)
  @action
  Future<void> loadMoreMessages() async {
    if (isLoading || currentCollection == null || !hasMoreMessages) return;

    _logger.info('Loading more messages, current count: ${messages.length}');
    isLoading = true;

    try {
      final loadedMessages = await ApiService.fetchMessages(
        currentCollection!,
        offset: messages.length,
        limit: messagePageSize,
      );

      // Check if we've reached the end
      if (loadedMessages.isEmpty || loadedMessages.length < messagePageSize) {
        hasMoreMessages = false;
        _logger.info('No more messages to load');
      }

      if (loadedMessages.isNotEmpty) {
        // Process and convert messages
        final processedMessages = loadedMessages.map((message) {
          if (message is! Map) return <String, dynamic>{};
          return Map<String, dynamic>.from(message);
        }).toList();

        // Add to current messages
        messages.addAll(processedMessages);
        totalMessagesLoaded = messages.length;

        // Update search index with new messages
        _updateSearchIndexWithNewMessages(
            currentCollection!, processedMessages);

        // Apply date filters if active
        _applyDateFilter();

        _logger.info(
            'Loaded ${processedMessages.length} more messages. Total: ${messages.length}');
      }

      isLoading = false;
    } catch (e) {
      _logger.warning('Error loading more messages: $e');
      errorMessage = 'Failed to load more messages: $e';
      isLoading = false;
    }
  }

  // Update search index with new messages without rebuilding the entire index
  void _updateSearchIndexWithNewMessages(
      String collectionName, List<Map<String, dynamic>> newMessages) {
    if (newMessages.isEmpty || !searchIndex.containsKey(collectionName)) return;

    final index = searchIndex[collectionName]!;
    final baseIndex = messages.length - newMessages.length;

    for (int i = 0; i < newMessages.length; i++) {
      final messageIndex = baseIndex + i;
      final message = newMessages[i];

      // Index content text
      if (message['content'] != null) {
        final content =
            removeDiacritics(message['content'].toString().toLowerCase());
        final words = content
            .split(RegExp(r'[^\w]+'))
            .where((word) => word.length > 2)
            .toSet();

        for (final word in words) {
          if (!index.containsKey(word)) {
            index[word] = <int>[];
          }
          index[word]!.add(messageIndex);
        }
      }

      // Index sender name
      if (message['sender_name'] != null) {
        final sender =
            removeDiacritics(message['sender_name'].toString().toLowerCase());
        final senderWords = sender
            .split(RegExp(r'[^\w]+'))
            .where((word) => word.length > 2)
            .toSet();

        for (final word in senderWords) {
          if (!index.containsKey(word)) {
            index[word] = <int>[];
          }
          index[word]!.add(messageIndex);
        }
      }

      // Index media types
      if (message['photos'] != null && (message['photos'] as List).isNotEmpty) {
        index['photo']!.add(messageIndex);
      }

      if (message['videos'] != null && (message['videos'] as List).isNotEmpty) {
        index['video']!.add(messageIndex);
      }

      if (message['audio_files'] != null &&
          (message['audio_files'] as List).isNotEmpty) {
        index['audio']!.add(messageIndex);
      }
    }

    // Update the index in the store
    searchIndex[collectionName] = index;
  }

  // Private method to fetch messages from API
  Future<void> _fetchMessages(String? collectionName,
      {bool updateUI = true,
      bool forceRefresh = false,
      int offset = 0,
      int limit = 0}) async {
    if (collectionName == null) return;

    try {
      // Use pagination parameters if provided
      final useLimit = limit > 0 ? limit : messagePageSize;
      final loadedMessages = await ApiService.fetchMessages(
        collectionName,
        offset: offset,
        limit: useLimit,
      );

      // Process and convert messages
      final processedMessages = loadedMessages.map((message) {
        if (message is! Map) return <String, dynamic>{};
        return Map<String, dynamic>.from(message);
      }).toList();

      // Update cache
      await _saveToCache(collectionName, processedMessages);

      // Update UI if needed
      if (updateUI) {
        if (offset == 0) {
          // Clear current messages if this is the first page
          messages.clear();
          hasMoreMessages = true;
        }

        messages.addAll(processedMessages);
        totalMessagesLoaded = messages.length;

        // Check if we've reached the end
        if (processedMessages.length < useLimit) {
          hasMoreMessages = false;
        }

        // Build or update search index
        if (offset == 0) {
          _buildSearchIndex(collectionName);
        } else {
          _updateSearchIndexWithNewMessages(collectionName, processedMessages);
        }

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
            totalMessagesLoaded = messages.length;
            // Build search index
            _buildSearchIndex(collectionName);
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

  // Build search index for faster searches
  void _buildSearchIndex(String collectionName) {
    if (messages.isEmpty) return;

    _logger.info('Building search index for $collectionName');
    final indexStartTime = DateTime.now();

    final index = <String, List<int>>{};

    // Add common search terms as keys
    index['photo'] = [];
    index['video'] = [];
    index['audio'] = [];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];

      // Index content text
      if (message['content'] != null) {
        final content =
            removeDiacritics(message['content'].toString().toLowerCase());
        final words = content
            .split(RegExp(r'[^\w]+'))
            .where((word) =>
                word.length > 2) // Only index words longer than 2 chars
            .toSet(); // Use set to remove duplicates

        for (final word in words) {
          if (!index.containsKey(word)) {
            index[word] = <int>[];
          }
          index[word]!.add(i);
        }
      }

      // Index sender name
      if (message['sender_name'] != null) {
        final sender =
            removeDiacritics(message['sender_name'].toString().toLowerCase());
        final senderWords = sender
            .split(RegExp(r'[^\w]+'))
            .where((word) => word.length > 2)
            .toSet();

        for (final word in senderWords) {
          if (!index.containsKey(word)) {
            index[word] = <int>[];
          }
          index[word]!.add(i);
        }
      }

      // Index media types
      if (message['photos'] != null && (message['photos'] as List).isNotEmpty) {
        index['photo']!.add(i);
      }

      if (message['videos'] != null && (message['videos'] as List).isNotEmpty) {
        index['video']!.add(i);
      }

      if (message['audio_files'] != null &&
          (message['audio_files'] as List).isNotEmpty) {
        index['audio']!.add(i);
      }
    }

    // Store the index
    searchIndex[collectionName] = index;

    final indexBuildTime = DateTime.now().difference(indexStartTime);
    _logger.info(
        'Search index built in ${indexBuildTime.inMilliseconds}ms with ${index.length} unique terms');
  }

  // Optimized search using index
  List<int> _searchWithIndex(String query) {
    if (currentCollection == null ||
        !searchIndex.containsKey(currentCollection!)) {
      return [];
    }

    final index = searchIndex[currentCollection!]!;
    final normalizedQuery = removeDiacritics(query.toLowerCase());

    // Special case for media types
    if (normalizedQuery == 'photo' ||
        normalizedQuery == 'video' ||
        normalizedQuery == 'audio') {
      return index[normalizedQuery] ?? [];
    }

    // For normal text search, split into words
    final queryWords = normalizedQuery
        .split(RegExp(r'[^\w]+'))
        .where((word) => word.length > 2)
        .toList();

    if (queryWords.isEmpty) {
      return [];
    }

    // Get results for first word
    Set<int> results = Set<int>.from(index[queryWords[0]] ?? []);

    // Intersect with results for other words
    for (int i = 1; i < queryWords.length; i++) {
      final wordMatches = index[queryWords[i]] ?? [];
      results = results.intersection(Set<int>.from(wordMatches));
    }

    return results.toList()..sort();
  }
}
