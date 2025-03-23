import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' show max;
import '../../stores/store_provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

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
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();
  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Setup MobX reactions after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupReactions();
      _refreshCollections();
    });
  }

  void _setupReactions() {
    final store = StoreProvider.of(context).collectionStore;

    // React to changes in the collection refresh state
    _disposers
        .add(reaction((_) => store.needsCollectionRefresh, (needsRefresh) {
      if (needsRefresh) {
        _refreshCollections();
      }
    }));

    // React to loading state changes
    _disposers.add(reaction((_) => store.isLoading, (isLoading) {
      // We could update UI based on loading state if needed
    }));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    // Dispose of all reactions
    for (final disposer in _disposers) {
      disposer();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreCollections();
    }
  }

  Future<void> _loadMoreCollections() async {
    final store = StoreProvider.of(context).collectionStore;
    await store.loadMoreCollections();
  }

  Future<void> _refreshCollections() async {
    final store = StoreProvider.of(context).collectionStore;
    await store.refreshCollectionsIfNeeded();
  }

  void _applyFilter(String query) {
    final store = StoreProvider.of(context).collectionStore;
    store.setFilterQuery(query);
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

    final store = StoreProvider.of(context).collectionStore;
    final navigationStore = StoreProvider.of(context).navigationStore;

    // Show loading state
    setState(() {
      isOpen = false; // Close the selector
    });

    // Use the navigation store to handle collection switching
    await navigationStore.navigateToCollection(context, collectionName);

    // Navigation is handled by the store now
    widget.onCollectionChanged(collectionName);

    // Only refresh collections if necessary - collection hit count may have changed
    if (store.needsCollectionRefresh) {
      await store.refreshCollections();
    }
  }

  void _toggleCollectionSelector() {
    setState(() {
      isOpen = !isOpen;
    });
    if (isOpen) {
      _refreshCollections();
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              // Using Observer to listen to filteredCollections
              final store = StoreProvider.of(context).collectionStore;
              final filteredCollections = store.filteredCollections;
              if (filteredCollections.isNotEmpty) {
                switchToCollection(filteredCollections.first['name']);
              }
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
                    borderRadius: BorderRadius.circular(20),
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
                  child: Observer(
                    builder: (_) {
                      final store = StoreProvider.of(context).collectionStore;
                      final isLoading = store.isLoading;
                      final filteredCollections = store.filteredCollections;

                      // Calculate max message count for progress bar
                      int maxMessageCount = filteredCollections.isNotEmpty
                          ? filteredCollections
                              .map((c) => c['messageCount'] as int)
                              .reduce((a, b) => max(a, b))
                          : 1;

                      return isLoading && filteredCollections.isEmpty
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
                                    onChanged: _applyFilter,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search collections...',
                                      hintStyle: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: theme.dividerColor),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(16)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: theme.dividerColor),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(16)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: theme.colorScheme.primary),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(16)),
                                      ),
                                      fillColor:
                                          theme.inputDecorationTheme.fillColor,
                                      filled: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: filteredCollections.length +
                                          (store.isLoading ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                            filteredCollections.length) {
                                          return Center(
                                              child: CircularProgressIndicator(
                                                  color: theme
                                                      .colorScheme.primary));
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
                                              ? theme.inputDecorationTheme
                                                  .fillColor
                                              : theme.cardColor,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: ListTile(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${item['name']}: ',
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      fontFamily:
                                                          'JetBrains Mono',
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(Icons.message,
                                                    color:
                                                        theme.iconTheme.color,
                                                    size: 18),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formatMessageCount(
                                                      messageCount),
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontFamily:
                                                        'JetBrains Mono',
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
                                                    BorderRadius.circular(16),
                                                child: LinearProgressIndicator(
                                                  value: percentage,
                                                  backgroundColor: isDarkMode
                                                      ? theme
                                                          .colorScheme.surface
                                                          .withValues(
                                                              alpha: 0.3)
                                                      : theme
                                                          .colorScheme.surface
                                                          .withValues(
                                                              alpha: 0.3),
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          theme.colorScheme
                                                              .primary),
                                                  minHeight: 8,
                                                ),
                                              ),
                                            ),
                                            onTap: () => switchToCollection(
                                                item['name']),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                ),
              // Use a container with explicit background color for the "Select Collection:" text
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                width: selectorWidth,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: _toggleCollectionSelector,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Observer(builder: (_) {
                          final store =
                              StoreProvider.of(context).collectionStore;
                          return Row(
                            children: [
                              if (store.isMessageLoading)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              if (store.isMessageLoading)
                                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.selectedCollection ??
                                      'Select Collection',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'JetBrains Mono',
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
