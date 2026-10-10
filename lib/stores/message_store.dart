import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_db/api_service.dart';
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

  // Private method to fetch messages from API
  Future<void> _fetchMessages(String? collectionName,
      {bool forceRefresh = false, bool backgroundRefresh = false}) async {
    if (collectionName == null) return;

    if (!backgroundRefresh) {
      isLoading = true;
    }

    try {
      // The paged endpoint reads straight from Mongo (never the cold-cache
      // placeholder) and returns pages sorted by timestamp_ms ascending.
      // 10000 is the server's maximum page size.
      const pageSize = 10000;
      final count = await ApiService.fetchMessageCount(collectionName);
      final List<Map<String, dynamic>> processedMessages = [];
      for (var offset = 0; offset < count; offset += pageSize) {
        processedMessages.addAll(await ApiService.fetchMessages(collectionName,
            offset: offset, limit: pageSize, countHit: offset == 0));
      }

      if (processedMessages.isNotEmpty) {
        await _saveToCache(collectionName, processedMessages);
      }

      if (!backgroundRefresh) {
        // Update UI
        messages.clear();
        messages.addAll(processedMessages);


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

        // Fall back to the local cache
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
}
