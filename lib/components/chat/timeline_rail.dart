import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../stores/message_store.dart';
import '../../theme.dart';

/// A vertical timeline next to the chat: the whole conversation from top
/// (oldest) to bottom (newest), scaled by message count, with a mark per
/// year and the current reading position. Click to jump there.
class TimelineRail extends StatefulWidget {
  final MessageStore store;

  /// Timestamp of the message at the top of the screen.
  final ValueListenable<int?> position;

  const TimelineRail({super.key, required this.store, required this.position});

  @override
  State<TimelineRail> createState() => _TimelineRailState();
}

class _TimelineRailState extends State<TimelineRail> {
  double? _hoverY;

  /// (month, count, messages before the month) for every month with data.
  List<(String, int, int)> _months(Map<String, dynamic> stats) {
    var before = 0;
    return [
      for (final m in (stats['perMonth'] as List).cast<Map<String, dynamic>>())
        (
          m['month'] as String,
          m['count'] as int,
          (before += m['count'] as int) - (m['count'] as int)
        ),
    ];
  }

  /// Approximate offset of [ts]: messages before its month plus the share
  /// of the month that has passed.
  int _offsetOf(int ts, List<(String, int, int)> months) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    for (final (month, count, before) in months) {
      if (month == key) {
        final start = DateTime.utc(d.year, d.month);
        final end = DateTime.utc(d.year, d.month + 1);
        final f = d.difference(start).inMilliseconds /
            end.difference(start).inMilliseconds;
        return before + (count * f).round();
      }
      if (month.compareTo(key) > 0) return before;
    }
    return months.isEmpty ? 0 : months.last.$3 + months.last.$2;
  }

  String _monthAt(int offset, List<(String, int, int)> months) {
    for (final (month, count, before) in months) {
      if (offset < before + count) return month;
    }
    return months.isEmpty ? '' : months.last.$1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Observer(builder: (_) {
      final stats = widget.store.stats;
      final total = (stats?['totalMessages'] as int?) ?? 0;
      if (stats == null || total == 0) return const SizedBox(width: 44);
      final months = _months(stats);

      return SizedBox(
        width: 44,
        child: LayoutBuilder(builder: (context, constraints) {
          const pad = 12.0;
          final h = constraints.maxHeight - 2 * pad;
          double yOf(int offset) => pad + h * offset / total;
          int offsetAt(double y) =>
              ((y - pad) / h * total).round().clamp(0, total - 1);

          final years = <(String, double)>[];
          for (final (month, _, before) in months) {
            final year = month.substring(0, 4);
            if (years.isEmpty || years.last.$1 != year) {
              years.add((year, yOf(before)));
            }
          }
          // Skip labels that would overlap the previous one.
          final labels = <(String, double)>[];
          for (final y in years) {
            if (labels.isEmpty || y.$2 - labels.last.$2 >= 16) labels.add(y);
          }

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) => setState(() => _hoverY = e.localPosition.dy),
            onExit: (_) => setState(() => _hoverY = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) =>
                  widget.store.jumpToOffset(offsetAt(d.localPosition.dy)),
              child: Tooltip(
                message:
                    _hoverY == null ? '' : _monthAt(offsetAt(_hoverY!), months),
                child: Stack(
                  children: [
                    Positioned(
                      left: 21,
                      top: pad,
                      bottom: pad,
                      child: Container(width: 2, color: scheme.outlineVariant),
                    ),
                    for (final (year, y) in labels)
                      Positioned(
                        top: y - 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            color: scheme.surface,
                            child: Text(year.substring(2),
                                style: monoStyle(context, size: 10)),
                          ),
                        ),
                      ),
                    ValueListenableBuilder<int?>(
                      valueListenable: widget.position,
                      builder: (context, ts, _) {
                        final offset =
                            ts == null ? total - 1 : _offsetOf(ts, months);
                        return Positioned(
                          top: yOf(offset) - 3,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_hoverY != null)
                      Positioned(
                        top: _hoverY! - 0.5,
                        left: 6,
                        right: 6,
                        child: Container(height: 1, color: scheme.tertiary),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}
