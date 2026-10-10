import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta_chat_viewer/components/avatar.dart';
import 'package:meta_chat_viewer/utils/text_match.dart';

void main() {
  test('initials from names and conversation ids', () {
    expect(Avatar.initials('Roman Jordán'), 'RJ');
    expect(Avatar.initials('KlaraSmitkova'), 'KS');
    expect(Avatar.initials('NikolGrover_sms'), 'NG');
    expect(Avatar.initials('Kocicka'), 'K');
    expect(Avatar.initials('ŠárkaŘíhová'), 'ŠŘ');
  });

  test('highlighting ignores case and diacritics, like the server', () {
    const hl = TextStyle(fontWeight: FontWeight.bold);
    final spans =
        highlightSpans('Ale pro 4 bude GOLF a oktávka', 'oktavka', hl);
    expect(spans.map((s) => s.text), ['Ale pro 4 bude GOLF a ', 'oktávka']);
    expect(spans.last.style, hl);
    expect(
        highlightSpans('golf a golfu', 'Golf', hl).where((s) => s.style == hl),
        hasLength(2));
    expect(highlightSpans('nic', '', hl).single.text, 'nic');
  });
}
