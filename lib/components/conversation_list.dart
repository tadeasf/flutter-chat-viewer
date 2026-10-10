import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../screens/gallery/photo_gallery.dart';
import '../stores/collection_store.dart';
import '../stores/store_provider.dart';
import '../theme.dart';
import '../utils/text_match.dart';
import 'avatar.dart';

/// Sidebar: filter, sort and the list of conversations.
class ConversationList extends StatelessWidget {
  final String? selected;
  final void Function(String name, {int? timestamp, String? id}) onSelect;
  final VoidCallback onSearchAll;
  final VoidCallback onSettings;
  final FocusNode filterFocus;
  final TextEditingController filterController;

  const ConversationList({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onSearchAll,
    required this.onSettings,
    required this.filterFocus,
    required this.filterController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = StoreProvider.of(context).collectionStore;
    final userData = StoreProvider.of(context).userDataStore;

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, 0),
            child: Row(
              children: [
                Expanded(
                    child: Text('Meta Elysia',
                        style: theme.textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Search all conversations (Ctrl+K)',
                  onPressed: onSearchAll,
                  icon: const Icon(Icons.manage_search),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, 0),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () {
                  filterController.clear();
                  store.clearFilter();
                  filterFocus.unfocus();
                },
              },
              child: TextField(
                controller: filterController,
                focusNode: filterFocus,
                onChanged: store.setFilterQuery,
                decoration: const InputDecoration(
                  hintText: 'Filter conversations',
                  prefixIcon: Icon(Icons.filter_list, size: 18),
                  suffixText: '/',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, 4),
            child: Observer(
              builder: (_) => Wrap(
                spacing: 6,
                children: [
                  for (final (sort, label) in const [
                    (CollectionSort.mostOpened, 'Most opened'),
                    (CollectionSort.largest, 'Largest'),
                    (CollectionSort.name, 'A–Z'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: store.sort == sort,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => store.setSort(sort),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Observer(builder: (_) {
              final items = store.filteredCollections;
              if (items.isEmpty && store.isLoading) {
                return const _SkeletonRows();
              }
              if (items.isEmpty && store.error != null) {
                return _Message(
                  text: 'Could not load conversations\n${store.error}',
                  action: TextButton(
                      onPressed: store.refreshCollections,
                      child: const Text('Retry')),
                );
              }
              if (items.isEmpty) {
                return _Message(
                    text: store.filterQuery.isEmpty
                        ? 'No conversations'
                        : 'No conversation matches “${store.filterQuery}”');
              }
              // Pinned conversations first, in the chosen order.
              final pinned = userData.pinned;
              final rows = <Object>[
                if (items.any((c) => pinned.contains(c['name']))) 'Pinned',
                ...items.where((c) => pinned.contains(c['name'])),
                if (pinned.isNotEmpty &&
                    items.any((c) => !pinned.contains(c['name'])))
                  'All conversations',
                ...items.where((c) => !pinned.contains(c['name'])),
              ];
              return Scrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, Space.m),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row is String) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Space.s, Space.m, Space.s, Space.xs),
                        child:
                            Text(row.toUpperCase(), style: monoStyle(context)),
                      );
                    }
                    final c = row as Map<String, dynamic>;
                    final name = c['name'] as String;
                    return SizedBox(
                      height: 60,
                      child: _Row(
                        name: name,
                        count: (c['messageCount'] ?? 0) as int,
                        hits: (c['hits'] ?? 0) as int,
                        selected: name == selected,
                        pinned: pinned.contains(name),
                        onTap: () => onSelect(name),
                        onTogglePin: () => userData.togglePin(name),
                        onShowInChat: (ts, id) =>
                            onSelect(name, timestamp: ts, id: id),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String name;
  final int count;
  final int hits;
  final bool selected;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final void Function(int timestamp, String? id) onShowInChat;

  const _Row({
    required this.name,
    required this.count,
    required this.hits,
    required this.selected,
    required this.pinned,
    required this.onTap,
    required this.onTogglePin,
    required this.onShowInChat,
  });

  Future<void> _menu(BuildContext context, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
          position & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        const PopupMenuItem(value: 'open', child: Text('Open')),
        PopupMenuItem(
            value: 'pin', child: Text(pinned ? 'Unpin' : 'Pin to top')),
        const PopupMenuItem(value: 'photos', child: Text('Open media')),
        const PopupMenuItem(value: 'copy', child: Text('Copy name')),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'open':
        onTap();
      case 'pin':
        onTogglePin();
      case 'photos':
        PhotoGallery.open(context, name, onShowInChat: onShowInChat);
      case 'copy':
        Clipboard.setData(ClipboardData(text: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final sub = selected
        ? scheme.onPrimaryContainer.withAlpha(200)
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.m),
          hoverColor: scheme.surfaceContainerHighest,
          onTap: onTap,
          onSecondaryTapDown: (d) => _menu(context, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s),
            child: Row(
              children: [
                Avatar(name: name, size: 40),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.titleSmall?.copyWith(color: fg)),
                      if (hits > 0)
                        Text(
                          'opened $hits× this week',
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: sub),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s),
                if (pinned) ...[
                  Icon(Icons.push_pin, size: 14, color: sub),
                  const SizedBox(width: Space.xs),
                ],
                Text(formatCount(count),
                    style: monoStyle(context, size: 12, color: sub)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              if (action != null) action!,
            ],
          ),
        ),
      );
}

class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return ListView.builder(
      padding: const EdgeInsets.all(Space.m),
      itemCount: 10,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: color),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 140.0 + (i % 3) * 30, height: 12, color: color),
                  const SizedBox(height: 6),
                  Container(width: 90, height: 10, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
