import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_db/api_service.dart';
import 'package:diacritic/diacritic.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Include the generated file
part 'message_store.g.dart';

// This is the class used by rest of the codebase
class MessageStore = MessageStoreBase with _$MessageStore;

// The store class
abstract class MessageStoreBase with Store {
  final Logger _logger = Logger('MessageStore');

  // Cache configuration
  static const int cacheExpirationDays = 180; // Cache valid for 6 months
  static const String cacheVersionKey = 'message_cache_version';
  static const int currentCacheVersion =
      1; // Increment when cache format changes

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

  // Cache stats
  @observable
  Map<String, DateTime> collectionCacheTimestamps = {};

  @observable
  Map<String, int> collectionCacheSizes = {};

  // Computed property for active date filtering
  @computed
  bool get hasDateFilter => fromDate != null || toDate != null;

  // Constructor to initialize cache metadata
  MessageStoreBase() {
    _initCacheMetadata();
  }

  // Initialize cache metadata
  Future<void> _initCacheMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheVersion = prefs.getInt(cacheVersionKey) ?? 0;

      // If cache version doesn't match, clear old cache
      if (cacheVersion < currentCacheVersion) {
        await _clearAllCache();
        await prefs.setInt(cacheVersionKey, currentCacheVersion);
      }

      // Load cache timestamps for all collections
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('messages_') && key.endsWith('_timestamp')) {
          final collectionKey =
              key.replaceAll('_timestamp', '').replaceAll('messages_', '');
          final timestamp = prefs.getInt(key) ?? 0;
          collectionCacheTimestamps[collectionKey] =
              DateTime.fromMillisecondsSinceEpoch(timestamp);

          // Get cache size if available
          final sizeKey = 'messages_${collectionKey}_size';
          final size = prefs.getInt(sizeKey) ?? 0;
          collectionCacheSizes[collectionKey] = size;
        }
      }
    } catch (e) {
      _logger.warning('Error initializing cache metadata: $e');
    }
  }

  // Action to change collection and load messages
  @action
  Future<void> setCollection(String? collectionName) async {
    if (collectionName == currentCollection && messages.isNotEmpty) {
      return; // No need to reload if collection hasn't changed and we have messages
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
        // Check if cache is fresh enough (within expiration period)
        final isCacheFresh = _isCacheFresh(collectionName);

        // Ensure messages are sorted by timestamp (ascending)
        cachedMessages.sort((a, b) =>
            (a['timestamp_ms'] as int).compareTo(b['timestamp_ms'] as int));

        messages.addAll(cachedMessages);
        filteredMessages.addAll(cachedMessages);

        // Build search index for faster searches
        _buildSearchIndex(collectionName);
        isLoading = false;

        // If cache is old, refresh in background
        if (!isCacheFresh) {
          _logger.info(
              'Cache for $collectionName is stale, refreshing in background');
          _fetchMessages(collectionName,
              forceRefresh: true, backgroundRefresh: true);
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

  // Check if cache is fresh based on expiration period
  bool _isCacheFresh(String collectionName) {
    final normalizedName = collectionName.replaceAll(' ', '_');
    final timestamp = collectionCacheTimestamps[normalizedName];

    if (timestamp == null) return false;

    final expirationDate =
        DateTime.now().subtract(Duration(days: cacheExpirationDays));
    return timestamp.isAfter(expirationDate);
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

  // Private method to fetch messages from API
  Future<void> _fetchMessages(String? collectionName,
      {bool forceRefresh = false, bool backgroundRefresh = false}) async {
    if (collectionName == null) return;

    if (!backgroundRefresh) {
      isLoading = true;
    }

    try {
      // Fetch all messages at once without pagination
      final loadedMessages = await ApiService.fetchMessages(collectionName);

      // Process and convert messages
      final processedMessages = loadedMessages.map((message) {
        if (message is! Map) return <String, dynamic>{};
        return Map<String, dynamic>.from(message);
      }).toList();

      // Sort messages by timestamp (ascending)
      processedMessages.sort((a, b) =>
          (a['timestamp_ms'] as int).compareTo(b['timestamp_ms'] as int));

      // Update cache
      await _saveToCache(collectionName, processedMessages);

      if (!backgroundRefresh) {
        // Update UI
        messages.clear();
        messages.addAll(processedMessages);

        // Build search index
        _buildSearchIndex(collectionName);

        // Apply date filters if active
        _applyDateFilter();
      }

      lastMessageFetch = DateTime.now();
      if (!backgroundRefresh) {
        isLoading = false;
      }

      _logger.info(
          'Loaded ${processedMessages.length} messages for $collectionName (background: $backgroundRefresh)');
    } catch (e) {
      _logger.warning('Error fetching messages: $e');
      if (!backgroundRefresh) {
        errorMessage = 'Failed to load messages: $e';
        isLoading = false;

        // Try loading from cache as fallback
        if (messages.isEmpty) {
          final cachedMessages = await _loadFromCache(collectionName);
          if (cachedMessages.isNotEmpty) {
            messages.addAll(cachedMessages);
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

  // Cache operations - save messages to cache using both SharedPreferences for metadata
  // and file storage for large message collections
  Future<void> _saveToCache(
      String collectionName, List<dynamic> messagesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedName = collectionName.replaceAll(' ', '_');

      // Create cache keys
      final metadataKey = 'messages_$normalizedName';
      final timestampKey = '${metadataKey}_timestamp';
      final sizeKey = '${metadataKey}_size';

      // Convert messages to JSON
      final messagesJson = json.encode(messagesList);
      final jsonBytes = utf8.encode(messagesJson).length;

      // Store messages in file for large collections
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/message_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final cacheFile = File('${cacheDir.path}/$normalizedName.json');
      await cacheFile.writeAsString(messagesJson);

      // Store metadata in SharedPreferences
      final now = DateTime.now();
      await prefs.setInt(timestampKey, now.millisecondsSinceEpoch);
      await prefs.setInt(sizeKey, jsonBytes);

      // Update observable cache metadata
      collectionCacheTimestamps[normalizedName] = now;
      collectionCacheSizes[normalizedName] = jsonBytes;

      _logger.info(
          'Saved ${messagesList.length} messages (${(jsonBytes / 1024).toStringAsFixed(2)} KB) to cache for $collectionName');
    } catch (e) {
      _logger.warning('Error saving messages to cache: $e');
    }
  }

  // Load messages from cache - tries file cache first, falls back to SharedPreferences
  Future<List<Map<String, dynamic>>> _loadFromCache(
      String collectionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedName = collectionName.replaceAll(' ', '_');

      // Create cache keys
      final metadataKey = 'messages_$normalizedName';
      final timestampKey = '${metadataKey}_timestamp';

      // Check if we have timestamp metadata
      final timestamp = prefs.getInt(timestampKey);
      if (timestamp == null) {
        return [];
      }

      // Try to load from file cache first
      final directory = await getApplicationDocumentsDirectory();
      final cacheFile =
          File('${directory.path}/message_cache/$normalizedName.json');

      String? cachedData;
      if (await cacheFile.exists()) {
        cachedData = await cacheFile.readAsString();
      } else {
        // Fall back to SharedPreferences
        cachedData = prefs.getString(metadataKey);
      }

      if (cachedData != null) {
        // Update last fetch time based on cache timestamp
        lastMessageFetch = DateTime.fromMillisecondsSinceEpoch(timestamp);

        _logger.info(
            'Loaded messages from cache for $collectionName (cached on ${DateTime.fromMillisecondsSinceEpoch(timestamp)})');

        // Decode and return messages
        return List<Map<String, dynamic>>.from(
            json.decode(cachedData).map((m) => Map<String, dynamic>.from(m)));
      }
    } catch (e) {
      _logger.warning('Error loading messages from cache: $e');
    }

    return [];
  }

  // Clear cache for a specific collection
  @action
  Future<void> clearCache(String collectionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedName = collectionName.replaceAll(' ', '_');

      // Remove from SharedPreferences
      await prefs.remove('messages_$normalizedName');
      await prefs.remove('messages_${normalizedName}_timestamp');
      await prefs.remove('messages_${normalizedName}_size');

      // Remove file cache
      final directory = await getApplicationDocumentsDirectory();
      final cacheFile =
          File('${directory.path}/message_cache/$normalizedName.json');
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }

      // Update observables
      collectionCacheTimestamps.remove(normalizedName);
      collectionCacheSizes.remove(normalizedName);

      _logger.info('Cleared cache for $collectionName');
    } catch (e) {
      _logger.warning('Error clearing cache: $e');
    }
  }

  // Clear all cache
  @action
  Future<void> _clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all cache keys
      final keys =
          prefs.getKeys().where((key) => key.startsWith('messages_')).toList();

      // Remove all cache keys from SharedPreferences
      for (final key in keys) {
        await prefs.remove(key);
      }

      // Remove all cache files
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/message_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      // Clear observables
      collectionCacheTimestamps.clear();
      collectionCacheSizes.clear();

      _logger.info('Cleared all message cache');
    } catch (e) {
      _logger.warning('Error clearing all cache: $e');
    }
  }

  // Get cache stats
  @computed
  Map<String, dynamic> get cacheStats {
    int totalSize = 0;
    int oldestTimestamp = DateTime.now().millisecondsSinceEpoch;
    int newestTimestamp = 0;
    int collectionCount = collectionCacheSizes.length;

    collectionCacheSizes.forEach((collection, size) {
      totalSize += size;

      final timestamp =
          collectionCacheTimestamps[collection]?.millisecondsSinceEpoch ?? 0;
      if (timestamp > 0) {
        if (timestamp < oldestTimestamp) oldestTimestamp = timestamp;
        if (timestamp > newestTimestamp) newestTimestamp = timestamp;
      }
    });

    return {
      'totalSizeKB': totalSize / 1024,
      'collectionCount': collectionCount,
      'oldestCache': oldestTimestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(oldestTimestamp)
          : null,
      'newestCache': newestTimestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(newestTimestamp)
          : null,
    };
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
