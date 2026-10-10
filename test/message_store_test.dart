import 'package:flutter_test/flutter_test.dart';
import 'package:meta_chat_viewer/stores/message_store.dart';

/// An in-memory conversation that behaves like the paged backend:
/// sorted by timestamp, `fromDate`/`toDate` inclusive, then offset/limit.
class FakeConversation {
  final List<Map<String, dynamic>> all;
  final calls = <Map<String, Object?>>[];

  FakeConversation(this.all);

  /// [n] messages, two per hour, with a tie every 7th message and a gap of
  /// a few weeks every 500 messages so pages cross month boundaries.
  factory FakeConversation.generate(int n) {
    var t = DateTime.utc(2019, 12, 30).millisecondsSinceEpoch;
    final list = <Map<String, dynamic>>[];
    for (var i = 0; i < n; i++) {
      if (i % 7 != 0) t += 30 * 60 * 1000;
      if (i % 500 == 0) t += 20 * 24 * 3600 * 1000;
      list.add({'_id': 'm$i', 'timestamp_ms': t, 'content': '$i'});
    }
    return FakeConversation(list);
  }

  MessageSource get source => MessageSource(
        count: (_) async => all.length,
        page: page,
        stats: (_) async {
          final perMonth = <String, int>{};
          for (final m in all) {
            final d = DateTime.fromMillisecondsSinceEpoch(
                m['timestamp_ms'] as int,
                isUtc: true);
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
            perMonth[key] = (perMonth[key] ?? 0) + 1;
          }
          return {
            'perMonth': [
              for (final e in perMonth.entries)
                {'month': e.key, 'count': e.value}
            ]
          };
        },
      );

  Future<List<Map<String, dynamic>>> page(String c,
      {required int offset,
      required int limit,
      int? fromDate,
      int? toDate,
      bool countHit = false}) async {
    calls.add({
      'offset': offset,
      'limit': limit,
      'fromDate': fromDate,
      'toDate': toDate,
      'countHit': countHit,
    });
    final filtered = all.where((m) {
      final t = m['timestamp_ms'] as int;
      return (fromDate == null || t >= fromDate) &&
          (toDate == null || t <= toDate);
    }).toList();
    return filtered.skip(offset).take(limit).toList();
  }
}

List<String> ids(MessageStore s) =>
    s.messages.map((m) => m['_id'] as String).toList();

List<String> range(int from, int to) => [for (var i = from; i < to; i++) 'm$i'];

void main() {
  late FakeConversation conv;
  late MessageStore store;

  setUp(() {
    conv = FakeConversation.generate(1234);
    store = MessageStore(source: conv.source, pageSize: 100);
  });

  test('open shows the newest page, anchored at the bottom', () async {
    await store.open('c');
    expect(store.total, 1234);
    expect(store.start, 1134);
    expect(ids(store), range(1134, 1234));
    expect(store.anchor, 100);
    expect(store.anchoredAtBottom, isTrue);
    expect(store.hasNewer, isFalse);
    expect(store.hasOlder, isTrue);
  });

  test('only the first request of an open counts a hit', () async {
    await store.open('c');
    await store.loadOlder();
    await store.jumpTo(conv.all[10]['timestamp_ms'] as int);
    expect(conv.calls.where((c) => c['countHit'] == true), hasLength(1));
  });

  test('loadOlder prepends contiguous pages and keeps the anchor item',
      () async {
    await store.open('c');
    final anchored = store.messages[store.anchor - 1];
    await store.loadOlder();
    expect(store.start, 1034);
    expect(ids(store), range(1034, 1234));
    expect(store.messages[store.anchor - 1], anchored);
  });

  test('loading older pages ends at the first message', () async {
    await store.open('c');
    while (store.hasOlder) {
      await store.loadOlder();
    }
    expect(ids(store), range(0, 1234));
    final requests = conv.calls.length;
    await store.loadOlder();
    expect(conv.calls.length, requests, reason: 'no request past the start');
  });

  test('offsetOf counts the messages before a timestamp, ties included',
      () async {
    await store.open('c');
    for (final i in [0, 1, 6, 7, 8, 499, 500, 501, 700, 1233]) {
      final t = conv.all[i]['timestamp_ms'] as int;
      final expected = conv.all.where((m) => (m['timestamp_ms'] as int) < t);
      expect(await store.offsetOf(t), expected.length, reason: 'message $i');
    }
  });

  test('jumpTo shows the target with context and highlights it', () async {
    await store.open('c');
    final target = conv.all[600];
    await store.jumpTo(target['timestamp_ms'] as int, id: 'm600');
    expect(store.messages[store.anchor]['_id'], 'm600');
    expect(store.highlightId, 'm600');
    expect(store.start, 600 - 25);
    expect(store.anchoredAtBottom, isFalse);
    expect(ids(store), range(575, 675));
  });

  test('jumpTo a tied timestamp picks the message by id', () async {
    await store.open('c');
    // m7 shares its timestamp with m6.
    expect(conv.all[7]['timestamp_ms'], conv.all[6]['timestamp_ms']);
    await store.jumpTo(conv.all[7]['timestamp_ms'] as int, id: 'm7');
    expect(store.messages[store.anchor]['_id'], 'm7');
  });

  test('after a jump, loadNewer appends up to the end', () async {
    await store.open('c');
    await store.jumpTo(conv.all[1100]['timestamp_ms'] as int);
    while (store.hasNewer) {
      await store.loadNewer();
    }
    expect(ids(store), range(1075, 1234));
  });

  test('overlapping pages do not duplicate messages', () async {
    await store.open('c');
    // Simulate a shifted order: the next older page repeats a message
    // that is already shown.
    final shifted = MessageStore(
      source: MessageSource(
        count: conv.source.count,
        stats: conv.source.stats,
        page: (c,
            {required offset,
            required limit,
            fromDate,
            toDate,
            countHit = false}) async {
          final page = await conv.page(c, offset: offset, limit: limit);
          return offset == 1034 ? [...page.skip(1), conv.all[1134]] : page;
        },
      ),
      pageSize: 100,
    );
    await shifted.open('c');
    await shifted.loadOlder();
    expect(ids(shifted).toSet().length, shifted.messages.length);
  });

  test('a conversation smaller than a page loads completely', () async {
    final small = FakeConversation.generate(42);
    final s = MessageStore(source: small.source, pageSize: 100);
    await s.open('c');
    expect(ids(s), range(0, 42));
    expect(s.hasOlder || s.hasNewer, isFalse);
  });

  test('a failed load is reported, not thrown', () async {
    final failing = MessageStore(
      source: MessageSource(
        count: (_) async => throw Exception('offline'),
        page: conv.source.page,
        stats: conv.source.stats,
      ),
    );
    await failing.open('c');
    expect(failing.error, contains('offline'));
    expect(failing.isLoading, isFalse);
  });
}
