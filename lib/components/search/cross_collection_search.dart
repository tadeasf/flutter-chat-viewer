import 'package:flutter/material.dart';
import '../../utils/api_db/api_service.dart';

class CrossCollectionSearchDialog extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSearchResults;

  const CrossCollectionSearchDialog({
    super.key,
    required this.onSearchResults,
  });

  @override
  CrossCollectionSearchDialogState createState() =>
      CrossCollectionSearchDialogState();
}

class CrossCollectionSearchDialogState
    extends State<CrossCollectionSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  Future<void> _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final List<dynamic> rawResults =
          await ApiService.performCrossCollectionSearch(_searchController.text);

      final List<Map<String, dynamic>> processedResults =
          rawResults.map((result) {
        if (result is! Map) return <String, dynamic>{};

        return {
          'content': result['content'] ?? '',
          'sender_name': result['sender_name'] ?? 'Unknown',
          'collectionName': result['collectionName'] ?? 'Unknown Collection',
          'timestamp_ms': result['timestamp_ms'] ?? 0,
          'photos': result['photos'] ?? [],
          'is_geoblocked_for_viewer': result['is_geoblocked_for_viewer'],
          'is_online': result['is_online'] ?? false,
        };
      }).toList();

      if (!mounted) return;
      widget.onSearchResults(processedResults);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cross-Collection Search',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search across all collections...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface.withValues(alpha: 0.7),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSearching
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
