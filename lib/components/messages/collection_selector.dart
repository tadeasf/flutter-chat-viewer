import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' show max;
import '../../utils/api_db/load_collections.dart';
import '../../utils/api_db/api_service.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  final FocusNode _keyboardFocusNode = FocusNode();

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
    searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
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
        collections = loadedCollections
            .where((collection) => collection['name'] != 'unified_collection')
            .toList()
          ..sort((a, b) => (b['hits'] ?? 0)
              .compareTo(a['hits'] ?? 0)); // Sort by hits descending
        filteredCollections = collections;
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

  Future<void> switchToCollection(String collectionName) async {
    if (!mounted) return;

    // Show loading state
    setState(() {
      isLoading = true;
    });

    bool collectionReady = false;
    int maxAttempts = 3;
    int currentAttempt = 0;

    while (!collectionReady && currentAttempt < maxAttempts) {
      try {
        // Try to load messages
        final messages = await ApiService.fetchMessages(collectionName);

        if (!mounted) return;

        // Check if we got the "please wait" response
        final messageContent =
            messages[0]['content']?.toString().toLowerCase() ?? '';
        if (messages.length == 1 &&
            messageContent.contains('please try loading collection again')) {
          await Future.delayed(const Duration(seconds: 5));
          currentAttempt++;
          continue;
        }

        // If we get here, the collection is ready
        collectionReady = true;
        widget.onCollectionChanged(collectionName);
        await refreshCollections();

        if (!mounted) return;

        setState(() {
          isLoading = false;
          isOpen = false;
        });
        return;
      } catch (e) {
        currentAttempt++;
      }
    }

    if (!mounted) return;

    // If we get here, all attempts failed
    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Collection is still being prepared. Please try again in a moment.',
          style: TextStyle(color: theme.colorScheme.onError),
        ),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  void _toggleCollectionSelector() {
    setState(() {
      isOpen = !isOpen;
    });
    if (isOpen) {
      refreshCollections();
      Future.delayed(const Duration(milliseconds: 100), () {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get screen width to make selector wider
    final screenWidth = MediaQuery.of(context).size.width;
    // Use 90% of screen width for the selector
    final selectorWidth = screenWidth * 0.9;

    int maxMessageCount = filteredCollections.isNotEmpty
        ? filteredCollections
            .map((c) => c['messageCount'] as int)
            .reduce((a, b) => max(a, b))
        : 1;

    // Get the scaffold background color directly from theme to ensure consistency
    final scaffoldColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    // We need a full-width, full-height colored container with no margins to ensure
    // all content has the correct background color
    return Container(
      color:
          scaffoldColor, // Explicitly set background color for the whole widget
      width: double.infinity, // Take full width
      alignment: Alignment.center, // Center content
      child: Container(
        width: selectorWidth,
        // Don't use padding on outer container to avoid white gaps
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero, // Explicitly set margin to zero
        decoration: BoxDecoration(
          color: scaffoldColor, // Match scaffold background color
          borderRadius: BorderRadius.circular(12),
        ),
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                filteredCollections.isNotEmpty) {
              widget.onCollectionChanged(filteredCollections.first['name']);
              return;
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOpen)
                Container(
                  height: 350,
                  width: selectorWidth,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: theme.colorScheme.primary))
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: searchController,
                                focusNode: _searchFocusNode,
                                onChanged: filterCollections,
                                style: theme.textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  hintText: 'Search collections...',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: theme.dividerColor),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: theme.dividerColor),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: theme.colorScheme.primary),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                  ),
                                  fillColor:
                                      theme.inputDecorationTheme.fillColor,
                                  filled: true,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: filteredCollections.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == filteredCollections.length) {
                                      return isLoadingMore
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                  color: theme
                                                      .colorScheme.primary))
                                          : const SizedBox.shrink();
                                    }
                                    final item = filteredCollections[index];
                                    final int messageCount =
                                        item['messageCount'] as int;
                                    final double percentage =
                                        maxMessageCount > 0
                                            ? messageCount / maxMessageCount
                                            : 0;
                                    return Card(
                                      elevation: 0,
                                      color: isDarkMode
                                          ? theme.inputDecorationTheme.fillColor
                                          : theme.cardColor,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item['name']}: ',
                                                style:
                                                    theme.textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(Icons.message,
                                                color: theme.iconTheme.color,
                                                size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatMessageCount(messageCount),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4.0, bottom: 8.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: percentage,
                                              backgroundColor: isDarkMode
                                                  ? theme.colorScheme.surface
                                                      .withValues(alpha: 0.3)
                                                  : theme.colorScheme.surface
                                                      .withValues(alpha: 0.3),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      theme
                                                          .colorScheme.primary),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                        onTap: () =>
                                            switchToCollection(item['name']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              // Use a container with explicit background color for the "Select Collection:" text
              Container(
                width: selectorWidth,
                padding: const EdgeInsets.all(8),
                // Explicitly match the background color of parent
                color: scaffoldColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apply background color directly to the text widget too
                    Container(
                      color: scaffoldColor,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      width: double.infinity,
                      child: Text(
                        'Select Collection:',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _toggleCollectionSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.selectedCollection ??
                                    'Select a collection',
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              isOpen
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: theme.iconTheme.color,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
