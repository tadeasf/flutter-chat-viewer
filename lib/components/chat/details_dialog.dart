import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../stores/store_provider.dart';
import '../../theme.dart';
import '../../utils/text_match.dart';
import '../avatar.dart';

/// Conversation details and the profile photo (upload / delete).
/// Pops with true when the photo changed.
class DetailsDialog extends StatefulWidget {
  final String collection;
  final String title;
  final String? avatarUrl;

  const DetailsDialog({
    super.key,
    required this.collection,
    required this.title,
    required this.avatarUrl,
  });

  @override
  State<DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<DetailsDialog> {
  bool _busy = false;

  Future<void> _change({required bool upload}) async {
    final stores = StoreProvider.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!upload) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete profile photo?'),
          content: Text(
              'The photo of ${widget.title} is deleted on the server. This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    try {
      if (upload) {
        final picked = await stores.galleryStore.uploadPhoto(widget.collection);
        if (!picked) return;
        messenger.showSnackBar(const SnackBar(content: Text('Photo uploaded')));
      } else {
        final result = await stores.galleryStore.deletePhoto(widget.collection);
        if (result['success'] != true) throw Exception(result['message']);
        messenger.showSnackBar(SnackBar(content: Text(result['message'])));
      }
      stores.profilePhotoStore.photoChanged(widget.collection);
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content:
              Text('Could not ${upload ? 'upload' : 'delete'} the photo: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = StoreProvider.of(context).messageStore;
    final hasPhoto = widget.avatarUrl != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Observer(builder: (_) {
            final stats = store.stats;
            final media = (stats?['media'] as Map?) ?? const {};
            final first = stats?['firstMessageAt'] as int?;
            final last = stats?['lastMessageAt'] as int?;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Avatar(
                    name: widget.title, photoUrl: widget.avatarUrl, size: 112),
                const SizedBox(height: Space.m),
                Text(widget.title, style: theme.textTheme.titleLarge),
                Text(widget.collection, style: monoStyle(context, size: 12)),
                const SizedBox(height: Space.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _change(upload: true),
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: Text(hasPhoto ? 'Replace photo' : 'Upload photo'),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(width: Space.s),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error),
                        onPressed: _busy ? null : () => _change(upload: false),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete photo'),
                      ),
                    ],
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: Space.m),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: Space.l),
                const Divider(),
                const SizedBox(height: Space.s),
                if (stats == null)
                  const Padding(
                    padding: EdgeInsets.all(Space.m),
                    child: CircularProgressIndicator(),
                  )
                else
                  _Facts(facts: [
                    ('Messages', formatCount(store.total)),
                    if (first != null)
                      ('First message', formatShortDate(first)),
                    if (last != null) ('Last message', formatShortDate(last)),
                    ('Photos', formatCount((media['photos'] ?? 0) as int)),
                    ('Videos', formatCount((media['videos'] ?? 0) as int)),
                    (
                      'Voice messages',
                      formatCount((media['audio'] ?? 0) as int)
                    ),
                  ]),
                const SizedBox(height: Space.m),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final List<(String, String)> facts;

  const _Facts({required this.facts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in facts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                Text(value,
                    style: monoStyle(context,
                        size: 13, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
      ],
    );
  }
}
