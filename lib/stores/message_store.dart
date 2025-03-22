import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import '../utils/api_db/api_service.dart';
import 'package:intl/intl.dart';

// Include the generated file
part 'message_store.g.dart';

// This is the class used by rest of the codebase
class MessageStore = MessageStoreBase with _$MessageStore;

// The store class
abstract class MessageStoreBase with Store {
  final Logger _logger = Logger('MessageStore');

  // Observable collections
  @observable
  ObservableList<Map<dynamic, dynamic>> messages =
      ObservableList<Map<dynamic, dynamic>>();

  @observable
  ObservableList<Map<dynamic, dynamic>> crossCollectionMessages =
      ObservableList<Map<dynamic, dynamic>>();

  @observable
  ObservableList<Map<String, dynamic>> allPhotos =
      ObservableList<Map<String, dynamic>>();

  // Observable loading states
  @observable
  bool isLoading = false;

  @observable
  bool isCrossCollectionLoading = false;

  // Observable for the current collection
  @observable
  String? currentCollection;

  // Cache for messages by collection name
  final Map<String, List<Map<dynamic, dynamic>>> _messagesCache = {};

  // Observable for search functionality
  @observable
  ObservableList<int> searchResults = ObservableList<int>();

  @observable
  int currentSearchIndex = -1;

  @observable
  bool isSearchActive = false;

  @observable
  String? currentSearchQuery;

  // Observable for time filters
  @observable
  DateTime? fromDate;

  @observable
  DateTime? toDate;

  // Observable for cross-collection search mode
  @observable
  bool isCrossCollectionSearch = false;

  // Map of timestamp to message index for fast lookup
  Map<int, int>? _timestampToIndexMap;

  // Computed property to get sorted messages
  @computed
  List<Map<dynamic, dynamic>> get sortedMessages {
    if (isCrossCollectionSearch) {
      return crossCollectionMessages.toList();
    } else {
      return messages.toList();
    }
  }

  // Action to fetch messages for a collection
  @action
  Future<void> fetchMessages(
    String? collectionName, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (collectionName == null) return;

    this.currentCollection = collectionName;
    this.fromDate = fromDate;
    this.toDate = toDate;

    // Reset search state
    searchResults.clear();
    currentSearchIndex = -1;
    isSearchActive = false;
    currentSearchQuery = null;

    // Check if we have cached messages for this collection
    if (_messagesCache.containsKey(collectionName)) {
      messages.clear();
      messages.addAll(_messagesCache[collectionName]!);
      _updateTimestampMap();
      _updateAllPhotos();
      return;
    }

    isLoading = true;

    try {
      final loadedMessages = await ApiService.fetchMessages(
        collectionName,
        fromDate:
            fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null,
        toDate: toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null,
      );

      // Process messages
      final processedMessages = loadedMessages
          .expand((message) => message is List ? message : [message])
          .map((message) => message as Map<dynamic, dynamic>)
          .toList();

      // Update observables
      messages.clear();
      messages.addAll(processedMessages);

      // Cache the messages
      _messagesCache[collectionName] = List.from(processedMessages);

      // Update indexes and photos
      _updateTimestampMap();
      _updateAllPhotos();

      isLoading = false;
    } catch (e) {
      _logger.warning('Error fetching messages: $e');
      isLoading = false;
    }
  }

  // Action to perform cross-collection search
  @action
  Future<void> performCrossCollectionSearch(String query) async {
    if (query.isEmpty) return;

    currentSearchQuery = query;
    isCrossCollectionLoading = true;
    isCrossCollectionSearch = true;

    try {
      final results = await ApiService.performCrossCollectionSearch(query);

      // Process results
      final processedMessages = results.map((result) {
        if (result is! Map) return <String, dynamic>{};

        // Check if this is an Instagram message
        final isInstagramMessage =
            result.containsKey('is_geoblocked_for_viewer');

        return Map<dynamic, dynamic>.from({
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

      // Update observables
      crossCollectionMessages.clear();
      crossCollectionMessages.addAll(processedMessages);

      isCrossCollectionLoading = false;
    } catch (e) {
      _logger.warning('Error in cross-collection search: $e');
      isCrossCollectionLoading = false;
    }
  }

  // Action to search messages in current collection
  @action
  Future<void> searchMessages(String query) async {
    if (query.isEmpty || messages.isEmpty) return;

    currentSearchQuery = query;
    searchResults.clear();
    currentSearchIndex = -1;
    isSearchActive = true;

    try {
      // Convert to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      // Perform search
      final results = <int>[];
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        final content = message['content']?.toString().toLowerCase() ?? '';

        if (content.contains(lowerQuery)) {
          results.add(i);
        }
      }

      // Update results
      searchResults.addAll(results);

      // Select first result if available
      if (searchResults.isNotEmpty) {
        currentSearchIndex = 0;
      }
    } catch (e) {
      _logger.warning('Error searching messages: $e');
    }
  }

  // Action to navigate through search results
  @action
  void navigateSearch(int direction) {
    if (searchResults.isEmpty) return;

    final newIndex = currentSearchIndex + direction;

    if (newIndex >= 0 && newIndex < searchResults.length) {
      currentSearchIndex = newIndex;
    } else if (searchResults.isNotEmpty) {
      // Wrap around
      currentSearchIndex = (newIndex < 0) ? searchResults.length - 1 : 0;
    }
  }

  // Action to clear search
  @action
  void clearSearch() {
    searchResults.clear();
    currentSearchIndex = -1;
    isSearchActive = false;
    currentSearchQuery = null;
  }

  // Action to exit cross-collection mode
  @action
  void exitCrossCollectionMode() {
    isCrossCollectionSearch = false;
    crossCollectionMessages.clear();
  }

  // Action to clear message cache
  @action
  void clearCache([String? specificCollection]) {
    if (specificCollection != null) {
      _messagesCache.remove(specificCollection);
    } else {
      _messagesCache.clear();
    }
  }

  // Helper method to update timestamp map
  void _updateTimestampMap() {
    final messagesForMapping =
        isCrossCollectionSearch ? crossCollectionMessages : messages;

    final sortedMsgs = List<Map<dynamic, dynamic>>.from(messagesForMapping)
      ..sort((a, b) =>
          (a['timestamp_ms'] as int).compareTo(b['timestamp_ms'] as int));

    _timestampToIndexMap = Map.fromEntries(
      sortedMsgs.asMap().entries.map((entry) => MapEntry(
            entry.value['timestamp_ms'] as int,
            entry.key,
          )),
    );
  }

  // Helper method to update all photos
  void _updateAllPhotos() {
    final messagesForPhotos =
        isCrossCollectionSearch ? crossCollectionMessages : messages;

    allPhotos.clear();

    for (var message in messagesForPhotos) {
      if (message['photos'] != null && (message['photos'] as List).isNotEmpty) {
        for (var photo in message['photos']) {
          allPhotos.add({
            'uri': photo['uri'],
            'timestamp_ms': message['timestamp_ms'],
            'creation_timestamp': photo['creation_timestamp'] * 1000,
            'collectionName': message['collectionName'] ?? currentCollection,
          });
        }
      }
    }
  }

  // Helper method to get message index by timestamp
  int? getIndexForTimestamp(
    int timestamp, {
    bool isPhotoTimestamp = false,
    bool useCreationTimestamp = false,
  }) {
    if (messages.isEmpty && crossCollectionMessages.isEmpty) {
      return null;
    }

    if (isPhotoTimestamp) {
      // Convert photo timestamp to milliseconds for comparison
      final photoTimestampMs = timestamp * 1000;
      final messagesForLookup =
          isCrossCollectionSearch ? crossCollectionMessages : messages;

      for (var i = 0; i < messagesForLookup.length; i++) {
        final message = messagesForLookup[i];
        if (message['photos'] != null &&
            (message['photos'] as List).isNotEmpty) {
          for (var photo in message['photos']) {
            final photoCreationTime =
                (photo['creation_timestamp'] as int?) ?? 0;
            if (photoCreationTime * 1000 == photoTimestampMs) {
              return i;
            }
          }
        }
      }
    }

    return _timestampToIndexMap?[timestamp];
  }

  // Helper method to decode text properly
  String _decodeIfNeeded(dynamic text) {
    if (text == null) return '';
    try {
      return utf8.decode(text.toString().codeUnits);
    } catch (e) {
      return text.toString();
    }
  }
}
