import 'package:flutter/material.dart';

class SearchDialog extends StatefulWidget {
  final Function(String query, bool isCrossCollection) onSearch;
  final String? selectedCollection;

  const SearchDialog({
    super.key,
    required this.onSearch,
    required this.selectedCollection,
  });

  @override
  SearchDialogState createState() => SearchDialogState();
}

class SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isCrossCollection = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });

      widget.onSearch(query, _isCrossCollection);

      if (mounted) {
        Navigator.of(context).pop();
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
              _isCrossCollection
                  ? 'Search All Collections'
                  : 'Search in ${widget.selectedCollection?.split('_').join(' ')}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter search term...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                prefixIcon: Icon(Icons.search,
                    color: theme.iconTheme.color?.withValues(alpha: 0.6)),
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
              onSubmitted: (_) {
                if (!_isCrossCollection) {
                  _handleSearch();
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Search across all collections',
                style: theme.textTheme.bodyMedium,
              ),
              value: _isCrossCollection,
              activeColor: theme.colorScheme.secondary,
              onChanged: (bool value) {
                setState(() {
                  _isCrossCollection = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
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
                                theme.colorScheme.onPrimary),
                          ),
                        )
                      : Text(
                          _isCrossCollection ? 'Search All' : 'Search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
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
