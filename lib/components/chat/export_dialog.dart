import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../stores/message_store.dart';
import '../../theme.dart';
import '../../utils/export.dart';
import '../../utils/text_match.dart';

/// Export a conversation, or a range of its months, to ~/Downloads.
class ExportDialog extends StatefulWidget {
  final MessageStore store;
  final String collection;
  final String title;

  const ExportDialog({
    super.key,
    required this.store,
    required this.collection,
    required this.title,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late final Future<Map<String, dynamic>> _stats = widget.store.loadStats();
  String? _from;
  String? _to;
  ExportFormat _format = ExportFormat.markdown;
  int? _written;
  String? _error;
  File? _file;

  static String _label(String month) => DateFormat('MMM y').format(DateTime(
      int.parse(month.substring(0, 4)), int.parse(month.substring(5))));

  static int _start(String month) => DateTime.utc(
          int.parse(month.substring(0, 4)), int.parse(month.substring(5)))
      .millisecondsSinceEpoch;

  static int _end(String month) =>
      DateTime.utc(int.parse(month.substring(0, 4)),
              int.parse(month.substring(5)) + 1)
          .millisecondsSinceEpoch -
      1;

  Future<void> _export(List<(String, int)> months) async {
    final from = _from ?? months.first.$1;
    final to = _to ?? months.last.$1;
    final whole = from == months.first.$1 && to == months.last.$1;
    setState(() {
      _written = 0;
      _error = null;
      _file = null;
    });
    try {
      final file = await exportConversation(
        collection: widget.collection,
        title: widget.title,
        format: _format,
        fromMs: whole ? null : _start(from),
        toMs: whole ? null : _end(to),
        onProgress: (n) {
          if (mounted) setState(() => _written = n);
        },
      );
      if (mounted) setState(() => _file = file);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _written = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Export · ${widget.title}'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _stats,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Could not load the months: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()));
            }
            final months = (snapshot.data!['perMonth'] as List)
                .cast<Map<String, dynamic>>()
                .map((m) => (m['month'] as String, m['count'] as int))
                .toList();
            if (months.isEmpty) return const Text('Nothing to export.');
            final from = _from ?? months.first.$1;
            final to = _to ?? months.last.$1;
            final count = months
                .where(
                    (m) => m.$1.compareTo(from) >= 0 && m.$1.compareTo(to) <= 0)
                .fold(0, (a, m) => a + m.$2);
            final busy = _written != null && _file == null && _error == null;

            DropdownButton<String> picker(
                    String value, ValueChanged<String> onChanged) =>
                DropdownButton<String>(
                  value: value,
                  menuMaxHeight: 360,
                  items: [
                    for (final m in months)
                      DropdownMenuItem(value: m.$1, child: Text(_label(m.$1))),
                  ],
                  onChanged: busy ? null : (v) => onChanged(v!),
                );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('From ', style: theme.textTheme.bodyMedium),
                    picker(
                        from,
                        (v) => setState(() {
                              _from = v;
                              if (v.compareTo(to) > 0) _to = v;
                            })),
                    Text('  to  ', style: theme.textTheme.bodyMedium),
                    picker(
                        to,
                        (v) => setState(() {
                              _to = v;
                              if (v.compareTo(from) < 0) _from = v;
                            })),
                  ],
                ),
                const SizedBox(height: Space.m),
                SegmentedButton<ExportFormat>(
                  segments: const [
                    ButtonSegment(
                        value: ExportFormat.markdown, label: Text('Markdown')),
                    ButtonSegment(
                        value: ExportFormat.html, label: Text('HTML')),
                  ],
                  selected: {_format},
                  onSelectionChanged:
                      busy ? null : (s) => setState(() => _format = s.first),
                ),
                const SizedBox(height: Space.m),
                Text(
                    '${formatCount(count)} messages. Media are listed by file name.',
                    style: theme.textTheme.bodySmall),
                if (_written != null && _file == null && _error == null) ...[
                  const SizedBox(height: Space.m),
                  LinearProgressIndicator(
                      value:
                          count == 0 ? null : (_written! / count).clamp(0, 1)),
                  const SizedBox(height: Space.xs),
                  Text('${formatCount(_written!)} of ${formatCount(count)}',
                      style: monoStyle(context, size: 12)),
                ],
                if (_file != null) ...[
                  const SizedBox(height: Space.m),
                  SelectableText('Saved to ${_file!.path}',
                      style: theme.textTheme.bodyMedium),
                ],
                if (_error != null) ...[
                  const SizedBox(height: Space.m),
                  Text('Export failed: $_error',
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
                if (!busy && _file == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Space.l),
                      child: FilledButton.icon(
                        onPressed: () => _export(months),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        if (_file != null && Platform.isLinux)
          TextButton(
            onPressed: () => Process.run('xdg-open', [_file!.parent.path]),
            child: const Text('Open folder'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_file != null ? 'Done' : 'Close'),
        ),
      ],
    );
  }
}
