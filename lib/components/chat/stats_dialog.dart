import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../stores/message_store.dart';
import '../../theme.dart';
import '../../utils/text_match.dart';

/// Conversation statistics from `/stats`. Clicking a month in the chart pops
/// with that month's start (UTC ms) so the chat can jump there.
class StatsDialog extends StatelessWidget {
  final MessageStore store;
  final String title;

  const StatsDialog({super.key, required this.store, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: FutureBuilder<Map<String, dynamic>>(
          future: store.loadStats(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text('Could not load statistics: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()));
            }
            final stats = snapshot.data!;
            final months = (stats['perMonth'] as List)
                .cast<Map<String, dynamic>>()
                .map((m) => (m['month'] as String, m['count'] as int))
                .toList();
            final senders = (stats['senders'] as List)
                .cast<Map<String, dynamic>>()
                .map((s) => (s['name'] as String, s['count'] as int))
                .toList()
              ..sort((a, b) => b.$2.compareTo(a.$2));
            final media = (stats['media'] as Map?) ?? const {};
            final total = stats['totalMessages'] as int? ?? 0;
            final first = stats['firstMessageAt'] as int?;
            final last = stats['lastMessageAt'] as int?;
            final days = first != null && last != null
                ? (last - first) / Duration.millisecondsPerDay
                : 0;
            final busiest = months.isEmpty
                ? null
                : months.reduce((a, b) => a.$2 >= b.$2 ? a : b);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statistics · $title',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: Space.l),
                  Wrap(
                    spacing: Space.xl,
                    runSpacing: Space.m,
                    children: [
                      _Figure('Messages', formatCount(total)),
                      if (first != null && last != null)
                        _Figure('Period',
                            '${formatShortDate(first)} – ${formatShortDate(last)}'),
                      if (days > 0)
                        _Figure(
                            'Per day',
                            (total / days)
                                .toStringAsFixed(total / days < 10 ? 1 : 0)),
                      if (busiest != null)
                        _Figure('Busiest month',
                            '${_monthLabel(busiest.$1)} · ${formatCount(busiest.$2)}'),
                      _Figure(
                          'Photos', formatCount((media['photos'] ?? 0) as int)),
                      _Figure(
                          'Videos', formatCount((media['videos'] ?? 0) as int)),
                      _Figure('Voice messages',
                          formatCount((media['audio'] ?? 0) as int)),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  Text('Messages per month', style: theme.textTheme.titleSmall),
                  Text('Click a month to read it.',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: Space.s),
                  _MonthChart(
                    months: months,
                    onPick: (month) {
                      final parts = month.split('-');
                      Navigator.of(context).pop(
                          DateTime.utc(int.parse(parts[0]), int.parse(parts[1]))
                              .millisecondsSinceEpoch);
                    },
                  ),
                  const SizedBox(height: Space.xl),
                  Text('Who wrote', style: theme.textTheme.titleSmall),
                  const SizedBox(height: Space.s),
                  _Senders(senders: senders, total: total),
                  const SizedBox(height: Space.l),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _monthLabel(String month) {
  final parts = month.split('-');
  return DateFormat('MMM y')
      .format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;

  const _Figure(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value,
            style: monoStyle(context,
                size: 15, color: theme.colorScheme.onSurface)),
      ],
    );
  }
}

/// Bar per month on a continuous timeline (empty months stay empty), with
/// year labels; hover shows the month and count.
class _MonthChart extends StatefulWidget {
  final List<(String, int)> months;
  final ValueChanged<String> onPick;

  const _MonthChart({required this.months, required this.onPick});

  @override
  State<_MonthChart> createState() => _MonthChartState();
}

class _MonthChartState extends State<_MonthChart> {
  int? _hover;
  late final List<(String, int)> _series = _fill(widget.months);

  /// Every month from the first to the last, zero where nothing was written.
  static List<(String, int)> _fill(List<(String, int)> months) {
    if (months.isEmpty) return const [];
    final counts = {for (final m in months) m.$1: m.$2};
    int y(String m) => int.parse(m.substring(0, 4));
    int mo(String m) => int.parse(m.substring(5, 7));
    final out = <(String, int)>[];
    var year = y(months.first.$1), month = mo(months.first.$1);
    final endKey = months.last.$1;
    while (true) {
      final key = '$year-${month.toString().padLeft(2, '0')}';
      out.add((key, counts[key] ?? 0));
      if (key == endKey) break;
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return out;
  }

  int? _indexAt(Offset p, double width) {
    if (_series.isEmpty) return null;
    final i = (p.dx / width * _series.length).floor();
    return i.clamp(0, _series.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final peak = _series.fold(1, (a, b) => a > b.$2 ? a : b.$2);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final hovered = _hover == null ? null : _series[_hover!];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 18,
            child: hovered == null
                ? null
                : Text(
                    '${_monthLabel(hovered.$1)} · ${formatCount(hovered.$2)} messages',
                    style: monoStyle(context, size: 12)),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) =>
                setState(() => _hover = _indexAt(e.localPosition, width)),
            onExit: (_) => setState(() => _hover = null),
            child: GestureDetector(
              onTapUp: (d) {
                final i = _indexAt(d.localPosition, width);
                if (i != null && _series[i].$2 > 0) {
                  widget.onPick(_series[i].$1);
                }
              },
              child: CustomPaint(
                size: Size(width, 160),
                painter: _BarsPainter(
                  series: _series,
                  peak: peak,
                  hover: _hover,
                  bar: scheme.primary,
                  barHover: scheme.tertiary,
                  grid: scheme.outlineVariant,
                  label: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _BarsPainter extends CustomPainter {
  final List<(String, int)> series;
  final int peak;
  final int? hover;
  final Color bar, barHover, grid, label;

  _BarsPainter({
    required this.series,
    required this.peak,
    required this.hover,
    required this.bar,
    required this.barHover,
    required this.grid,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final step = size.width / series.length;
    final gap = step > 4 ? 1.0 : 0.0;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, chartHeight), Offset(size.width, chartHeight), gridPaint);
    for (var i = 0; i < series.length; i++) {
      final (month, count) = series[i];
      final x = i * step;
      if (month.endsWith('-01')) {
        canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
        final tp = TextPainter(
          text: TextSpan(
              text: month.substring(0, 4),
              style: TextStyle(
                  color: label, fontSize: 11, fontFamily: monoFamily)),
          textDirection: TextDirection.ltr,
        )..layout();
        if (x + tp.width <= size.width) {
          tp.paint(canvas, Offset(x + 2, chartHeight + 3));
        }
      }
      if (count == 0) continue;
      final h = (count / peak) * (chartHeight - 4);
      canvas.drawRect(
        Rect.fromLTWH(x, chartHeight - h, step - gap, h),
        Paint()..color = i == hover ? barHover : bar,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.hover != hover || old.series != series || old.bar != bar;
}

class _Senders extends StatelessWidget {
  final List<(String, int)> senders;
  final int total;

  const _Senders({required this.senders, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      scheme.outline
    ];
    final sum = senders.fold(0, (a, b) => a + b.$2);
    if (sum == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.s),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final (i, s) in senders.indexed)
                  Expanded(
                    flex: s.$2,
                    child: Container(color: colors[i % colors.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.s),
        for (final (i, s) in senders.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle)),
                const SizedBox(width: Space.s),
                Expanded(child: Text(s.$1)),
                Text(
                  '${formatCount(s.$2)} · ${(100 * s.$2 / sum).toStringAsFixed(1)} %',
                  style: monoStyle(context, size: 12, color: scheme.onSurface),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
