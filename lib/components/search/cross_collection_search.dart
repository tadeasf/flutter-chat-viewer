import 'package:flutter/material.dart';
import '../../utils/api_db/api_service.dart';
import './cross_collection_filter.dart';

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
  List<dynamic>? _searchResults;
  Set<String> _selectedCollections = {};
  Map<String, int> _collectionCounts = {};

  Future<void> _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results =
          await ApiService.performCrossCollectionSearch(_searchController.text);

      if (!mounted) return;

      // Calculate collection counts
      final counts = <String, int>{};
      for (final result in results) {
        final collectionName = result['collectionName'] as String;
        counts[collectionName] = (counts[collectionName] ?? 0) + 1;
      }

      setState(() {
        _searchResults = results;
        _collectionCounts = counts;
        _selectedCollections = Set.from(counts.keys); // Initially select all
        _isSearching = false;
      });

      _filterAndReturnResults();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isSearching = false);
    }
  }

  void _filterAndReturnResults() {
    if (_searchResults == null) return;

    final filteredResults = _searchResults!.where((result) {
      return _selectedCollections.contains(result['collectionName']);
    }).toList();

    widget.onSearchResults(List<Map<String, dynamic>>.from(filteredResults));
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            if (_collectionCounts.isNotEmpty)
              Flexible(
                child: CrossCollectionFilter(
                  collectionCounts: _collectionCounts,
                  selectedCollections: _selectedCollections,
                  onCollectionsChanged: (collections) {
                    setState(() => _selectedCollections = collections);
                    _filterAndReturnResults();
                  },
                ),
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
