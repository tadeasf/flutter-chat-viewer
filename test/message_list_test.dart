import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta_chat_viewer/components/messages/message_list.dart';
import 'package:meta_chat_viewer/stores/message_store.dart';
import 'package:meta_chat_viewer/stores/store_provider.dart';

import 'message_store_test.dart' show FakeConversation;

Widget app(MessageStore store) => StoreProvider(
      profilePhotoStore: Stores.profilePhotoStore,
      collectionStore: Stores.collectionStore,
      messageStore: store,
      themeStore: Stores.themeStore,
      galleryStore: Stores.galleryStore,
      child: MaterialApp(
        home: Scaffold(
          body: MessageList(store: store, profilePhotoUrl: null),
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
    final visible =
        tester.widget<Text>(find.textContaining(RegExp(r'^\d+$')).first).data!;
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
}
