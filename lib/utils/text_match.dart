import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

const _plain = {
  'á': 'a',
  'ä': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'å': 'a',
  'č': 'c',
  'ć': 'c',
  'ç': 'c',
  'ď': 'd',
  'é': 'e',
  'ě': 'e',
  'ë': 'e',
  'è': 'e',
  'ê': 'e',
  'í': 'i',
  'ï': 'i',
  'ì': 'i',
  'î': 'i',
  'ľ': 'l',
  'ĺ': 'l',
  'ł': 'l',
  'ň': 'n',
  'ń': 'n',
  'ñ': 'n',
  'ó': 'o',
  'ö': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ő': 'o',
  'ř': 'r',
  'ŕ': 'r',
  'š': 's',
  'ś': 's',
  'ť': 't',
  'ú': 'u',
  'ů': 'u',
  'ü': 'u',
  'ù': 'u',
  'û': 'u',
  'ű': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ž': 'z',
  'ź': 'z',
  'ż': 'z',
  'đ': 'd',
  'Á': 'A',
  'Ä': 'A',
  'À': 'A',
  'Â': 'A',
  'Ã': 'A',
  'Å': 'A',
  'Č': 'C',
  'Ć': 'C',
  'Ç': 'C',
  'Ď': 'D',
  'É': 'E',
  'Ě': 'E',
  'Ë': 'E',
  'È': 'E',
  'Ê': 'E',
  'Í': 'I',
  'Ï': 'I',
  'Ì': 'I',
  'Î': 'I',
  'Ľ': 'L',
  'Ĺ': 'L',
  'Ł': 'L',
  'Ň': 'N',
  'Ń': 'N',
  'Ñ': 'N',
  'Ó': 'O',
  'Ö': 'O',
  'Ò': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ő': 'O',
  'Ř': 'R',
  'Ŕ': 'R',
  'Š': 'S',
  'Ś': 'S',
  'Ť': 'T',
  'Ú': 'U',
  'Ů': 'U',
  'Ü': 'U',
  'Ù': 'U',
  'Û': 'U',
  'Ű': 'U',
  'Ý': 'Y',
  'Ÿ': 'Y',
  'Ž': 'Z',
  'Ź': 'Z',
  'Ż': 'Z',
  'Đ': 'D'
};

/// Lower-case and strip diacritics, keeping the string length, so indices in
/// the folded text are indices in the original. Matches how the server
/// searches (diacritics stripped, case-insensitive).
String fold(String s) {
  final out = StringBuffer();
  for (final unit in s.codeUnits) {
    final c = String.fromCharCode(unit);
    out.write(_plain[c] ?? c);
  }
  return out.toString().toLowerCase();
}

/// [text] split into spans with every occurrence of [query] highlighted.
List<TextSpan> highlightSpans(String text, String? query, TextStyle highlight) {
  final q = query == null ? '' : fold(query.trim());
  if (q.isEmpty) return [TextSpan(text: text)];
  final folded = fold(text);
  // Lower-casing a few characters changes the length; then skip highlighting.
  if (folded.length != text.length) return [TextSpan(text: text)];
  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final i = folded.indexOf(q, start);
    if (i < 0) break;
    if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
    spans
        .add(TextSpan(text: text.substring(i, i + q.length), style: highlight));
    start = i + q.length;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return spans;
}

final _day = DateFormat('EEEE d MMMM y');
final _time = DateFormat('HH:mm');
final _short = DateFormat('d MMM y');
final _full = DateFormat('d MMM y, HH:mm');

DateTime _local(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

String formatDay(int ms) => _day.format(_local(ms));
String formatTime(int ms) => _time.format(_local(ms));
String formatShortDate(int ms) => _short.format(_local(ms));
String formatDateTime(int ms) => _full.format(_local(ms));

bool sameDay(int a, int b) {
  final x = _local(a), y = _local(b);
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

String formatCount(int n) => NumberFormat.decimalPattern('en').format(n);
