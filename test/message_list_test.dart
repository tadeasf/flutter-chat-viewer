import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta_chat_viewer/components/chat/message_list.dart';
import 'package:meta_chat_viewer/stores/message_store.dart';
import 'package:meta_chat_viewer/stores/store_provider.dart';
import 'package:meta_chat_viewer/theme.dart';

import 'message_store_test.dart' show FakeConversation;

Widget app(MessageStore store) => StoreProvider(
      profilePhotoStore: Stores.profilePhotoStore,
      collectionStore: Stores.collectionStore,
      messageStore: store,
      themeStore: Stores.themeStore,
      galleryStore: Stores.galleryStore,
      userDataStore: Stores.userDataStore,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: MessageList(store: store, userData: Stores.userDataStore),
        ),
      ),
    );

void main() {
  testWidgets('loading older messages does not move what is on screen',
      (tester) async {
    final conv = FakeConversation.generate(1000);
    // Older pages are held back until released, so the layout can be
    // measured right before and right after one arrives.
    Completer<void>? gate;
    var held = 0;
    final store = MessageStore(
      pageSize: 100,
      source: MessageSource(
        count: conv.source.count,
        stats: conv.source.stats,
        page: (c,
            {required offset,
            required limit,
            fromDate,
            toDate,
            countHit = false}) async {
          if (gate != null) {
            held++;
            await gate.future;
          }
          return conv.page(c, offset: offset, limit: limit);
        },
      ),
    );
    await store.open('c');
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.text('999'), findsOneWidget);

    gate = Completer<void>();
    while (held == 0) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();
    }
    final visible = tester
        .widget<Text>(find.textContaining(RegExp(r'^\d+$')).first)
        .textSpan!
        .toPlainText();
    final before = tester.getTopLeft(find.text(visible));

    gate.complete();
    await tester.pumpAndSettle();
    expect(store.messages.length, greaterThan(100));
    expect(tester.getTopLeft(find.text(visible)), before);
  });

  testWidgets('after a jump the target is on screen and highlighted',
      (tester) async {
    final conv = FakeConversation.generate(1000);
    final store = MessageStore(source: conv.source, pageSize: 100);
    await store.open('c');
    await tester.pumpWidget(app(store));
    await store.jumpTo(conv.all[300]['timestamp_ms'] as int, id: 'm300');
    await tester.pumpAndSettle();

    expect(find.text('300'), findsOneWidget);
    expect(store.highlightId, 'm300');
  });

  testWidgets('reopening at a saved position shows that message near the top',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final conv = FakeConversation.generate(1000);
    final store = MessageStore(source: conv.source, pageSize: 100);
    await store.open('c');
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    // Scroll first: a stale saved offset must not be restored.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
    await tester.pumpAndSettle();
    await store.open('c', at: conv.all[500]['timestamp_ms'] as int);
    await tester.pumpAndSettle();
    final y = tester.getTopLeft(find.text('500')).dy;
    expect(y, inInclusiveRange(0, 800 * 0.4));
  });
}
