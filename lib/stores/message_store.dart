import 'dart:math';

import 'package:mobx/mobx.dart';

import '../utils/api_db/api_service.dart';

part 'message_store.g.dart';

typedef PageFetcher = Future<List<Map<String, dynamic>>> Function(
  String collection, {
  required int offset,
  required int limit,
  int? fromDate,
  int? toDate,
  bool countHit,
});

/// The backend calls the store needs; replaceable in tests.
class MessageSource {
  final Future<int> Function(String collection) count;
  final PageFetcher page;
  final Future<Map<String, dynamic>> Function(String collection) stats;

  const MessageSource({
    required this.count,
    required this.page,
    required this.stats,
  });

  static const api = MessageSource(
    count: ApiService.fetchMessageCount,
    page: ApiService.fetchMessages,
    stats: ApiService.fetchStats,
  );
}

class MessageStore = MessageStoreBase with _$MessageStore;

/// A window of one conversation, loaded page by page.
///
/// `messages[i]` is the message at absolute offset `start + i` (messages are
/// ordered by timestamp, oldest first). [anchor] is the index the chat list
/// keeps fixed on screen: pages loaded above it never move what is visible.
abstract class MessageStoreBase with Store {
  MessageStoreBase({this.source = MessageSource.api, this.pageSize = 200});

  final MessageSource source;
  final int pageSize;

  @observable
  String? collection;

  /// Number of messages in the conversation.
  @observable
  int total = 0;

  /// Absolute offset of `messages[0]`.
  @observable
  int start = 0;

  final ObservableList<Map<String, dynamic>> messages =
      ObservableList<Map<String, dynamic>>();

  @observable
  int anchor = 0;

  /// True when the window was opened at the newest messages (the list then
  /// sticks to the bottom); false after a jump (target shown near the top).
  @observable
  bool anchoredAtBottom = true;

  /// Incremented whenever the window is replaced, so the list can reset.
  @observable
  int generation = 0;

  /// `_id` of the message to highlight (jump target, search hit).
  @observable
  String? highlightId;

  @observable
  bool isLoading = false;

  @observable
  String? error;

  /// `/stats` of the open conversation (null until loaded): totals,
  /// first/last message time, media counts, senders and `perMonth`.
  @observable
  Map<String, dynamic>? stats;

  bool _loadingOlder = false;
  bool _loadingNewer = false;
  Future<Map<String, dynamic>>? _statsFuture;

  int get end => start + messages.length;

  @computed
  bool get hasOlder => start > 0;

  @computed
  bool get hasNewer => start + messages.length < total;

  /// Opens a conversation at its newest messages.
  @action
  Future<void> open(String name) async {
    collection = name;
    stats = null;
    _statsFuture = null;
    loadStats().ignore();
    await _replaceWindow(() async {
      total = await source.count(name);
      final first = max(0, total - pageSize);
      final page = await source.page(name,
          offset: first, limit: pageSize, countHit: true);
      return (first, page, page.length, null);
    });
  }

  @action
  Future<void> jumpToLatest() async {
    final name = collection;
    if (name == null) return;
    await _replaceWindow(() async {
      total = await source.count(name);
      final first = max(0, total - pageSize);
      final page = await source.page(name, offset: first, limit: pageSize);
      return (first, page, page.length, null);
    });
  }

  /// Shows the oldest messages.
  @action
  Future<void> jumpToStart() async {
    final name = collection;
    if (name == null) return;
    await _replaceWindow(() async {
      final page = await source.page(name, offset: 0, limit: pageSize);
      return (0, page, 0, null);
    });
  }

  /// Loads `/stats` once per opened conversation.
  Future<Map<String, dynamic>> loadStats() {
    final name = collection!;
    final pending = _statsFuture;
    if (pending != null) return pending;
    final future = source.stats(name).then((value) {
      if (name == collection) runInAction(() => stats = value);
      return value;
    });
    _statsFuture = future;
    // A failed request is not cached, so the next jump tries again.
    future.catchError((_) {
      if (identical(_statsFuture, future)) _statsFuture = null;
      return const <String, dynamic>{};
    });
    return future;
  }

  /// Shows the message with [timestamp] (and [id], if known) in its context.
  @action
  Future<void> jumpTo(int timestamp, {String? id}) async {
    final name = collection;
    if (name == null) return;
    await _replaceWindow(() async {
      final offset = await offsetOf(timestamp);
      final first = max(0, offset - pageSize ~/ 4);
      final page = await source.page(name, offset: first, limit: pageSize);
      var target = id == null ? -1 : page.indexWhere((m) => m['_id'] == id);
      if (target < 0) {
        target = page
            .indexWhere((m) => (m['timestamp_ms'] as int? ?? 0) >= timestamp);
      }
      if (target < 0) target = page.length;
      final highlight =
          target < page.length ? page[target]['_id'] as String? : null;
      return (first, page, target, highlight);
    });
  }

  /// Number of messages older than [timestamp].
  ///
  /// `/stats` gives per-month totals (UTC), so only the messages of the
  /// target month before [timestamp] need to be counted.
  Future<int> offsetOf(int timestamp) async {
    final name = collection!;
    final perMonth =
        ((await loadStats())['perMonth'] as List).cast<Map<String, dynamic>>();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    final month = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
    var before = 0;
    for (final m in perMonth) {
      if ((m['month'] as String).compareTo(month) >= 0) break;
      before += m['count'] as int;
    }
    final monthStart =
        DateTime.utc(date.year, date.month).millisecondsSinceEpoch;
    const maxPage = 10000;
    for (var skip = 0;; skip += maxPage) {
      final page = await source.page(name,
          offset: skip,
          limit: maxPage,
          fromDate: monthStart,
          toDate: timestamp - 1);
      before += page.length;
      if (page.length < maxPage) return before;
    }
  }

  @action
  Future<void> loadOlder() async {
    final name = collection;
    if (name == null || _loadingOlder || isLoading || !hasOlder) return;
    _loadingOlder = true;
    try {
      final count = min(pageSize, start);
      final page = await source.page(name, offset: start - count, limit: count);
      if (name == collection) _prepend(page, start - count);
    } catch (e) {
      error = '$e';
    } finally {
      _loadingOlder = false;
    }
  }

  @action
  Future<void> loadNewer() async {
    final name = collection;
    if (name == null || _loadingNewer || isLoading || !hasNewer) return;
    _loadingNewer = true;
    try {
      final page = await source.page(name, offset: end, limit: pageSize);
      if (name == collection) _append(page);
    } catch (e) {
      error = '$e';
    } finally {
      _loadingNewer = false;
    }
  }

  // Pages are joined by offset; messages already present (same `_id`) are
  // skipped in case the server's order of equal timestamps ever shifts.
  @action
  void _prepend(List<Map<String, dynamic>> page, int newStart) {
    final known = _ids(messages.take(page.length));
    final fresh = page.where((m) => !known.contains(m['_id'])).toList();
    messages.insertAll(0, fresh);
    anchor += fresh.length;
    start = newStart;
  }

  @action
  void _append(List<Map<String, dynamic>> page) {
    final known = _ids(messages.skip(max(0, messages.length - page.length)));
    messages.addAll(page.where((m) => !known.contains(m['_id'])));
  }

  static Set<Object?> _ids(Iterable<Map<String, dynamic>> ms) =>
      {for (final m in ms) m['_id']};

  @action
  Future<void> _replaceWindow(
      Future<(int, List<Map<String, dynamic>>, int, String?)> Function()
          load) async {
    final name = collection;
    isLoading = true;
    error = null;
    try {
      final (first, page, anchorIndex, highlight) = await load();
      if (name != collection) return;
      start = first;
      messages
        ..clear()
        ..addAll(page);
      anchor = anchorIndex;
      anchoredAtBottom = anchorIndex >= page.length;
      highlightId = highlight;
      generation++;
    } catch (e) {
      if (name == collection) error = '$e';
    } finally {
      if (name == collection) isLoading = false;
    }
  }
}
