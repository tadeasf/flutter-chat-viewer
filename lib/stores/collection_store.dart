import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_db/api_service.dart';

part 'collection_store.g.dart';

class CollectionStore = CollectionStoreBase with _$CollectionStore;

enum CollectionSort { mostOpened, largest, name }

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

  @observable
  CollectionSort sort = CollectionSort.mostOpened;

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

  @action
  void setSort(CollectionSort value) {
    sort = value;
    _applyFilter();
  }

  /// `unified_collection` (all chats merged, stale) is not a conversation.
  @action
  void _setCollections(List<Map<String, dynamic>> list) {
    collections
      ..clear()
      ..addAll(list.where((c) => c['name'] != 'unified_collection'));
    _applyFilter();
  }

  static int _int(Map<String, dynamic> c, String key) => (c[key] ?? 0) as int;

  /// The server's by-count route never works, so sorting happens here.
  int _compare(Map<String, dynamic> a, Map<String, dynamic> b) {
    int byName() => (a['name'] as String)
        .toLowerCase()
        .compareTo((b['name'] as String).toLowerCase());
    int byCount() => _int(b, 'messageCount').compareTo(_int(a, 'messageCount'));
    switch (sort) {
      case CollectionSort.mostOpened:
        final byHits = _int(b, 'hits').compareTo(_int(a, 'hits'));
        return byHits != 0 ? byHits : byCount();
      case CollectionSort.largest:
        return byCount();
      case CollectionSort.name:
        return byName();
    }
  }

  void _applyFilter() {
    final query = filterQuery.toLowerCase();
    final list = (query.isEmpty
        ? collections.toList()
        : collections
            .where((c) => (c['name'] as String).toLowerCase().contains(query))
            .toList())
      ..sort(_compare);
    filteredCollections
      ..clear()
      ..addAll(list);
  }
}
