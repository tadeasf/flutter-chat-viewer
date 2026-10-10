import 'package:flutter_test/flutter_test.dart';
import 'package:meta_chat_viewer/utils/export.dart';

void main() {
  final t = DateTime(2019, 4, 1, 9, 22).millisecondsSinceEpoch;
  final messages = [
    {'timestamp_ms': t, 'sender_name': 'Týna', 'content': 'ahoj\njak je?'},
    {
      'timestamp_ms': t + 60000,
      'sender_name': 'Tadeáš Fořt',
      'photos': [
        {'uri': 'messages/inbox/x/photos/a.jpg'}
      ],
    },
    {
      'timestamp_ms': t + 86400000,
      'sender_name': 'Týna',
      'content': '<b>&</b>',
    },
  ];

  test('markdown: a heading per day, one line per message, media by name', () {
    final md = toMarkdown('Týna', messages);
    expect(md, startsWith('# Týna\n'));
    expect('## '.allMatches(md), hasLength(2));
    expect(md, contains('**09:22 Týna** ahoj  \njak je?'));
    expect(md, contains('**09:23 Tadeáš Fořt** [photo: a.jpg]'));
  });

  test('html escapes message text', () {
    final html = toHtml('Týna', messages);
    expect(html, contains('&lt;b&gt;&amp;&lt;&#47;b&gt;'));
    expect(html, isNot(contains('<b>&</b>')));
  });
}
