import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_data_store.g.dart';

class UserDataStore = UserDataStoreBase with _$UserDataStore;

/// Things the user marks locally: pinned conversations, where they stopped
/// reading, and bookmarked messages. Stored in SharedPreferences only.
abstract class UserDataStoreBase with Store {
  UserDataStoreBase() {
    _load();
  }

  static const _pinnedKey = 'pinnedConversations';
  static const _positionsKey = 'readingPositions';
  static const _bookmarksKey = 'bookmarks';

  final ObservableSet<String> pinned = ObservableSet<String>();

  /// Conversation -> timestamp of the message at the top of the screen.
  final ObservableMap<String, int> positions = ObservableMap<String, int>();

  /// Conversation -> bookmarked messages
  /// (`_id`, `timestamp_ms`, `sender_name`, `content`), oldest first.
  final ObservableMap<String, List<Map<String, dynamic>>> bookmarks =
      ObservableMap<String, List<Map<String, dynamic>>>();

  Timer? _savePositions;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    runInAction(() {
      pinned.addAll(prefs.getStringList(_pinnedKey) ?? const []);
      final p = prefs.getString(_positionsKey);
      if (p != null) {
        positions.addAll((jsonDecode(p) as Map).cast<String, int>());
      }
      final b = prefs.getString(_bookmarksKey);
      if (b != null) {
        (jsonDecode(b) as Map).forEach((k, v) =>
            bookmarks[k as String] = (v as List).cast<Map<String, dynamic>>());
      }
    });
  }

  @action
  Future<void> togglePin(String collection) async {
    if (!pinned.remove(collection)) pinned.add(collection);
    (await SharedPreferences.getInstance())
        .setStringList(_pinnedKey, pinned.toList());
  }

  /// Saved at most every two seconds while scrolling; null (back at the
  /// newest messages) forgets the position.
  @action
  void setPosition(String collection, int? timestamp) {
    if (positions[collection] == timestamp) return;
    if (timestamp == null) {
      positions.remove(collection);
    } else {
      positions[collection] = timestamp;
    }
    _savePositions?.cancel();
    _savePositions = Timer(const Duration(seconds: 2), () async {
      (await SharedPreferences.getInstance())
          .setString(_positionsKey, jsonEncode(positions));
    });
  }

  bool isBookmarked(String collection, String? id) =>
      id != null &&
      (bookmarks[collection]?.any((b) => b['_id'] == id) ?? false);

  @action
  Future<void> toggleBookmark(
      String collection, Map<String, dynamic> message) async {
    final id = message['_id'];
    final list = [...?bookmarks[collection]];
    if (list.any((b) => b['_id'] == id)) {
      list.removeWhere((b) => b['_id'] == id);
    } else {
      list
        ..add({
          '_id': id,
          'timestamp_ms': message['timestamp_ms'],
          'sender_name': message['sender_name'],
          if (message['content'] != null) 'content': message['content'],
        })
        ..sort((a, b) => (a['timestamp_ms'] as int? ?? 0)
            .compareTo(b['timestamp_ms'] as int? ?? 0));
    }
    if (list.isEmpty) {
      bookmarks.remove(collection);
    } else {
      bookmarks[collection] = list;
    }
    (await SharedPreferences.getInstance())
        .setString(_bookmarksKey, jsonEncode(bookmarks));
  }
}
