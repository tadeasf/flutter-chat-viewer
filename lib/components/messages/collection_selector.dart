import 'package:flutter/material.dart';
import 'dart:math' show max;
import '../../utils/api_db/load_collections.dart';

class CollectionSelector extends StatefulWidget {
  final String? selectedCollection;
  final Function(String?) onCollectionChanged;
  final List<Map<String, dynamic>> initialCollections;

  const CollectionSelector({
    super.key,
    required this.selectedCollection,
    required this.onCollectionChanged,
    required this.initialCollections,
  });

  @override
  CollectionSelectorState createState() => CollectionSelectorState();
}

class CollectionSelectorState extends State<CollectionSelector> {
  bool isOpen = false;
  late List<Map<String, dynamic>> collections;
  late List<Map<String, dynamic>> filteredCollections;
  final TextEditingController searchController = TextEditingController();
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    collections = [];
    filteredCollections = [];
    _scrollController.addListener(_scrollListener);
    _loadInitialCollections();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreCollections();
    }
  }

  Future<void> _loadMoreCollections() async {
    if (!isLoadingMore) {
      setState(() {
        isLoadingMore = true;
      });

      final newCollections = await loadMoreCollections();

      setState(() {
        collections.addAll(newCollections);
        filteredCollections = collections;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadInitialCollections() async {
    setState(() {
      isLoading = true;
    });
    await loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections
            .where((collection) => collection['name'] != 'unified_collection')
            .toList();
        filteredCollections = collections;
        isLoading = false;
      });
    });
  }

  Future<void> refreshCollections() async {
    setState(() {
      isLoading = true;
    });

    await loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
        isLoading = false;
      });
    });
  }

  void filterCollections(String query) {
    setState(() {
      filteredCollections = collections
          .where((collection) =>
              collection['name'].toLowerCase().contains(query.toLowerCase()) &&
              collection['name'] != 'unified_collection')
          .toList();
    });
  }

  String formatMessageCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    int maxMessageCount = filteredCollections.isNotEmpty
        ? filteredCollections
            .map((c) => c['messageCount'] as int)
            .reduce((a, b) => max(a, b))
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Collection:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() {
              isOpen = !isOpen;
            });
            if (isOpen) {
              refreshCollections();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedCollection ?? 'Select a collection',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Icon(
                  isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            height: 300,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: searchController,
                          onChanged: filterCollections,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search collections...',
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: filteredCollections.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filteredCollections.length) {
                              return isLoadingMore
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : const SizedBox.shrink();
                            }
                            final item = filteredCollections[index];
                            final int messageCount =
                                item['messageCount'] as int;
                            final double percentage = maxMessageCount > 0
                                ? messageCount / maxMessageCount
                                : 0;
                            return ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['name']}: ',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                  const Icon(Icons.message,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatMessageCount(messageCount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: Colors.grey[800],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFCBA6F7)),
                                  minHeight: 8,
                                ),
                              ),
                              onTap: () {
                                widget.onCollectionChanged(item['name']);
                                setState(() {
                                  isOpen = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}
