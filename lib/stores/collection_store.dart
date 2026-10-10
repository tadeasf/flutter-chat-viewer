import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_db/api_service.dart';

part 'collection_store.g.dart';

class CollectionStore = CollectionStoreBase with _$CollectionStore;

/// The list of conversations. The last list is kept in SharedPreferences so
/// the app shows it immediately on start; it is then refreshed from the server.
abstract class CollectionStoreBase with Store {
  CollectionStoreBase() {
    loadCollections();
  }

  static const _cacheKey = 'cachedCollections';
  static const _refreshAfter = Duration(minutes: 5);

  @observable
  ObservableList<Map<String, dynamic>> collections =
      ObservableList<Map<String, dynamic>>();

  @observable
  ObservableList<Map<String, dynamic>> filteredCollections =
      ObservableList<Map<String, dynamic>>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  bool isMessageLoading = false;

  @observable
  String filterQuery = '';

  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  /// Shows the cached list (if any), then fetches a fresh one.
  @action
  Future<void> loadCollections() async {
    if (collections.isEmpty) {
      final cached =
          (await SharedPreferences.getInstance()).getString(_cacheKey);
      if (cached != null) {
        _setCollections(
            (jsonDecode(cached) as List).cast<Map<String, dynamic>>());
      }
    }
    await refreshCollections();
  }

  @action
  Future<void> refreshCollections() async {
    isLoading = true;
    error = null;
    try {
      final fresh = await ApiService.fetchCollections();
      _setCollections(fresh);
      _lastFetch = DateTime.now();
      (await SharedPreferences.getInstance())
          .setString(_cacheKey, jsonEncode(fresh));
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> refreshCollectionsIfNeeded() async {
    if (isLoading) return;
    if (collections.isEmpty ||
        DateTime.now().difference(_lastFetch) > _refreshAfter) {
      await refreshCollections();
    }
  }

  @action
  void setMessageLoading(bool loading) {
    isMessageLoading = loading;
  }

  @action
  void setFilterQuery(String query) {
    filterQuery = query;
    _applyFilter();
  }

  @action
  void clearFilter() => setFilterQuery('');

  /// Most opened first, then largest. `unified_collection` (all chats merged,
  /// stale) is not a conversation. The server's by-count route never works,
  /// so sorting happens here.
  @action
  void _setCollections(List<Map<String, dynamic>> list) {
    final sorted = list.where((c) => c['name'] != 'unified_collection').toList()
      ..sort((a, b) {
        final byHits =
            ((b['hits'] ?? 0) as int).compareTo((a['hits'] ?? 0) as int);
        return byHits != 0
            ? byHits
            : ((b['messageCount'] ?? 0) as int)
                .compareTo((a['messageCount'] ?? 0) as int);
      });
    collections
      ..clear()
      ..addAll(sorted);
    _applyFilter();
  }

  void _applyFilter() {
    final query = filterQuery.toLowerCase();
    filteredCollections
      ..clear()
      ..addAll(query.isEmpty
          ? collections
          : collections.where(
              (c) => (c['name'] as String).toLowerCase().contains(query)));
  }
}
