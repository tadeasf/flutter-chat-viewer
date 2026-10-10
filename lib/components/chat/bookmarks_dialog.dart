import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../stores/store_provider.dart';
import '../../theme.dart';
import '../../utils/text_match.dart';

/// Bookmarked messages of one conversation. Pops with the chosen bookmark.
class BookmarksDialog extends StatelessWidget {
  final String collection;

  const BookmarksDialog({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = StoreProvider.of(context).userDataStore;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: Observer(builder: (_) {
          final list =
              (userData.bookmarks[collection] ?? const []).reversed.toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Space.xl, Space.xl, Space.xl, Space.s),
                child: Text('Bookmarks', style: theme.textTheme.titleLarge),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.xl, Space.s, Space.xl, Space.xl),
                  child: Text(
                    'No bookmarks yet. Right-click a message and choose Bookmark.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.m),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final b = list[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.m)),
                        title: Text(
                          (b['content'] as String?) ?? '(photo or media)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${b['sender_name'] ?? ''} · ${formatDateTime(b['timestamp_ms'] as int? ?? 0)}',
                          style: monoStyle(context),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove bookmark',
                          icon: const Icon(Icons.bookmark_remove_outlined),
                          onPressed: () =>
                              userData.toggleBookmark(collection, b),
                        ),
                        onTap: () => Navigator.of(context).pop(b),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, Space.m, Space.m),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
