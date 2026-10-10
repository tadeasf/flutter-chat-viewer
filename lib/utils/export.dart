import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'api_db/api_service.dart';
import 'text_match.dart';

enum ExportFormat { markdown, html }

/// Writes the messages of [collection] between [fromMs] and [toMs]
/// (inclusive, null = open end) to ~/Downloads. Reports progress as the
/// number of messages written so far.
Future<File> exportConversation({
  required String collection,
  required String title,
  required ExportFormat format,
  int? fromMs,
  int? toMs,
  void Function(int written)? onProgress,
}) async {
  const page = 10000;
  final messages = <Map<String, dynamic>>[];
  for (var offset = 0;; offset += page) {
    final batch = await ApiService.fetchMessages(collection,
        offset: offset, limit: page, fromDate: fromMs, toDate: toMs);
    messages.addAll(batch);
    onProgress?.call(messages.length);
    if (batch.length < page) break;
  }

  final text = format == ExportFormat.markdown
      ? toMarkdown(title, messages)
      : toHtml(title, messages);

  final dir = await getDownloadsDirectory() ?? Directory.systemTemp;
  String day(int? ms) => ms == null
      ? ''
      : DateTime.fromMillisecondsSinceEpoch(ms)
          .toIso8601String()
          .substring(0, 10);
  final range = messages.isEmpty
      ? 'empty'
      : '${day(messages.first['timestamp_ms'] as int?)}_${day(messages.last['timestamp_ms'] as int?)}';
  final ext = format == ExportFormat.markdown ? 'md' : 'html';
  final file = File('${dir.path}/$collection-$range.$ext');
  await file.writeAsString(text);
  return file;
}

String _attachments(Map<String, dynamic> m) {
  final parts = <String>[];
  for (final (key, label) in const [
    ('photos', 'photo'),
    ('videos', 'video'),
    ('audio_files', 'voice message'),
  ]) {
    for (final a in (m[key] as List?) ?? const []) {
      parts.add('[$label: ${(a['uri'] as String).split('/').last}]');
    }
  }
  return parts.join(' ');
}

/// One heading per day, one line per message: `**HH:mm Name** text`.
String toMarkdown(String title, List<Map<String, dynamic>> messages) {
  final out = StringBuffer('# $title\n');
  int? lastDay;
  for (final m in messages) {
    final ts = m['timestamp_ms'] as int? ?? 0;
    if (lastDay == null || !sameDay(lastDay, ts)) {
      out.write('\n## ${formatDay(ts)}\n\n');
      lastDay = ts;
    }
    final body = [
      if ((m['content'] as String?)?.isNotEmpty ?? false)
        (m['content'] as String).replaceAll('\n', '  \n'),
      _attachments(m),
    ].where((s) => s.isNotEmpty).join(' ');
    out.write('**${formatTime(ts)} ${m['sender_name'] ?? ''}** $body  \n');
  }
  return out.toString();
}

String toHtml(String title, List<Map<String, dynamic>> messages) {
  const esc = HtmlEscape();
  final out = StringBuffer('''<!doctype html>
<meta charset="utf-8">
<title>${esc.convert(title)}</title>
<style>
body{font-family:system-ui,sans-serif;max-width:760px;margin:2rem auto;padding:0 1rem;line-height:1.5;color:#1b2324;background:#f5fafa}
h2{font-size:1rem;color:#5b6a6c;margin:2rem 0 .5rem;border-bottom:1px solid #d9e0e0}
p{margin:.25rem 0}time{font-family:ui-monospace,monospace;color:#5b6a6c;font-size:.85em;margin-right:.5em}
b{font-weight:600}.a{color:#2e6f76}
@media (prefers-color-scheme:dark){body{background:#0e1415;color:#dde4e4}h2,time{color:#8fa0a1}h2{border-color:#263032}.a{color:#85d2db}}
</style>
<h1>${esc.convert(title)}</h1>
''');
  int? lastDay;
  for (final m in messages) {
    final ts = m['timestamp_ms'] as int? ?? 0;
    if (lastDay == null || !sameDay(lastDay, ts)) {
      out.write('<h2>${esc.convert(formatDay(ts))}</h2>\n');
      lastDay = ts;
    }
    final content = (m['content'] as String?) ?? '';
    final attachments = _attachments(m);
    out.write(
        '<p><time>${formatTime(ts)}</time><b>${esc.convert(m['sender_name'] as String? ?? '')}</b> '
        '${esc.convert(content).replaceAll('\n', '<br>')}'
        '${attachments.isEmpty ? '' : ' <span class="a">${esc.convert(attachments)}</span>'}</p>\n');
  }
  return out.toString();
}
