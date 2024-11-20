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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cross-Collection Search',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search across all collections...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
