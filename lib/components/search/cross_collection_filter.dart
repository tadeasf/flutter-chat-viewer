import 'package:flutter/material.dart';

class CrossCollectionFilter extends StatefulWidget {
  final Map<String, int> collectionCounts;
  final Set<String> selectedCollections;
  final Function(Set<String>) onCollectionsChanged;

  const CrossCollectionFilter({
    super.key,
    required this.collectionCounts,
    required this.selectedCollections,
    required this.onCollectionsChanged,
  });

  @override
  State<CrossCollectionFilter> createState() => _CrossCollectionFilterState();
}

class _CrossCollectionFilterState extends State<CrossCollectionFilter> {
  late Set<String> _selectedCollections;

  @override
  void initState() {
    super.initState();
    _selectedCollections = widget.selectedCollections;
  }

  @override
  Widget build(BuildContext context) {
    final sortedCollections = widget.collectionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Collections',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCollections =
                              Set.from(widget.collectionCounts.keys);
                        });
                        widget.onCollectionsChanged(_selectedCollections);
                      },
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCollections = {};
                        });
                        widget.onCollectionsChanged(_selectedCollections);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sortedCollections.length,
              itemBuilder: (context, index) {
                final entry = sortedCollections[index];
                return CheckboxListTile(
                  title: Text(entry.key.split('_').join(' ')),
                  subtitle: Text('${entry.value} matches'),
                  value: _selectedCollections.contains(entry.key),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedCollections.add(entry.key);
                      } else {
                        _selectedCollections.remove(entry.key);
                      }
                    });
                    widget.onCollectionsChanged(_selectedCollections);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
