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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1E2E),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isCrossCollection
                  ? 'Search All Collections'
                  : 'Search in ${widget.selectedCollection?.split('_').join(' ')}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter search term...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: const Color(0xFF313244),
              ),
              onSubmitted: (_) {
                if (!_isCrossCollection) {
                  _handleSearch();
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Search across all collections',
                  style: TextStyle(color: Colors.white)),
              value: _isCrossCollection,
              activeColor: const Color(0xFFCBA6F7),
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFFCBA6F7))),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: const Color(0xFFCBA6F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isCrossCollection ? 'Search All' : 'Search',
                          style: const TextStyle(color: Colors.black),
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
