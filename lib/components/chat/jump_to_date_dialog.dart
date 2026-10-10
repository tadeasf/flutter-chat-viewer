import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../stores/message_store.dart';
import '../../theme.dart';
import '../../utils/text_match.dart';

/// Month picker built from the conversation's own months (`/stats`).
/// Pops with the timestamp to jump to.
class JumpToDateDialog extends StatelessWidget {
  final MessageStore store;

  const JumpToDateDialog({super.key, required this.store});

  static final _monthNames =
      List.generate(12, (i) => DateFormat('MMM').format(DateTime(2000, i + 1)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 620),
        child: FutureBuilder<Map<String, dynamic>>(
          future: store.loadStats(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text('Could not load the months: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }
            final stats = snapshot.data!;
            final counts = <(int, int), int>{};
            for (final m in (stats['perMonth'] as List)) {
              final parts = (m['month'] as String).split('-');
              counts[(int.parse(parts[0]), int.parse(parts[1]))] =
                  m['count'] as int;
            }
            final years = counts.keys.map((k) => k.$1).toSet().toList()..sort();
            final peak = counts.values.fold(1, (a, b) => a > b ? a : b);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.xl, Space.xl, Space.xl, Space.s),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Jump to date',
                              style: theme.textTheme.titleLarge)),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pop(stats['firstMessageAt'] as int?),
                        child: const Text('Oldest'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pop(stats['lastMessageAt'] as int?),
                        child: const Text('Newest'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                  child: Text(
                    'Stronger colour means more messages. Months are in UTC.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: Space.m),
                Flexible(
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                          Space.xl, 0, Space.xl, Space.xl),
                      children: [
                        for (final year in years.reversed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.s),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 48,
                                    child: Text('$year',
                                        style: monoStyle(context, size: 13))),
                                for (var month = 1; month <= 12; month++)
                                  Expanded(
                                    child: _MonthCell(
                                      label: _monthNames[month - 1],
                                      count: counts[(year, month)] ?? 0,
                                      peak: peak,
                                      onTap: () => Navigator.of(context).pop(
                                          DateTime.utc(year, month)
                                              .millisecondsSinceEpoch),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final int count;
  final int peak;
  final VoidCallback onTap;

  const _MonthCell(
      {required this.label,
      required this.count,
      required this.peak,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = count == 0;
    final strength = empty ? 0.0 : 0.15 + 0.85 * (count / peak);
    final fill =
        Color.lerp(scheme.surfaceContainerHigh, scheme.primary, strength)!;
    final onFill = strength > 0.55 ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Tooltip(
        message: empty ? 'No messages' : '${formatCount(count)} messages',
        child: Material(
          color: empty ? Colors.transparent : fill,
          borderRadius: BorderRadius.circular(Radii.s),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.s),
            onTap: empty ? null : onTap,
            child: SizedBox(
              height: 34,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: empty ? scheme.outline : onFill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
