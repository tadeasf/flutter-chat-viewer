import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'fetch_messages.dart';
import '../gallery/photo_handler.dart';
import 'message_list.dart';
import '../../utils/api_db/api_service.dart';
import '../profile_photo/profile_photo_manager.dart';
import '../search/navigate_search.dart';
import '../app_drawer.dart';
import 'collection_selector.dart';
import '../navbar.dart';
import '../search/scroll_to_highlighted_message.dart';
import '../search/search_messages.dart';
import 'message_index_manager.dart';
import '../search/search_type.dart';
import '../ui_utils/visibility_state.dart';
import '../search/search_dialog.dart';
import '../search/cross_collection_filter.dart';

class MessageSelector extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;

  const MessageSelector(
      {super.key, required this.setThemeMode, required this.themeMode});

  @override
  MessageSelectorState createState() => MessageSelectorState();
}

class MessageSelectorState extends State<MessageSelector> {
  List<Map<String, dynamic>> collections = [];
  List<Map<String, dynamic>> filteredCollections = [];
  String? selectedCollection;
  DateTime? fromDate;
  DateTime? toDate;
  List<Map<dynamic, dynamic>> messages = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  final picker = ImagePicker();
  bool isPhotoAvailable = false;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  List<dynamic> galleryPhotos = [];
  bool isGalleryLoading = false;
  List<int> searchResults = [];
  int currentSearchIndex = -1;
  bool isSearchVisible = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool isSearchActive = false;
  String? searchQueryInWidget;
  String? profilePhotoUrl;
  final bool _isProfilePhotoVisible = true;
  int get maxCollectionIndex => filteredCollections.isNotEmpty
      ? filteredCollections
          .map((c) => c['index'] as int? ?? 0)
          .reduce((a, b) => a > b ? a : b)
      : 0;
  bool isCollectionSelectorVisible = false;
  List<Map<dynamic, dynamic>> crossCollectionMessages = [];
  bool isCrossCollectionSearch = false;
  bool isSearchBarVisible = false;
  bool isGlobalLoading = false;
  int currentFoundMatches = 0;
  VisibilityState _currentVisibility = VisibilityState.none;
  final FocusNode _searchFocusNode = FocusNode();
  bool isCrossCollectionLoading = false;
  String? currentSearchQuery;
  Set<String> selectedCollections = {};
  bool isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
        isCollectionSelectorVisible = selectedCollection == null;
      });
    });
  }

  void filterCollections(String query) {
    setState(() {
      filteredCollections = collections
          .where((collection) =>
              collection['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  void setMessages(List<dynamic> loadedMessages) {
    setState(() {
      messages = loadedMessages
          .expand((message) => message is List ? message : [message])
          .map((message) => message as Map<dynamic, dynamic>)
          .toList();
    });
  }

  void updateCurrentSearchIndex(int index) {
    if (index >= 0 && index < searchResults.length) {
      setState(() {
        currentSearchIndex = index;
        isSearchActive = true;
        isSearchVisible = true;
      });

      if (itemScrollController.isAttached) {
        scrollToHighlightedMessage(
          searchResults[index],
          searchResults,
          itemScrollController,
          SearchType.searchWidget,
        );
      }
    }
  }

  Future<void> _changeCollection(String? newValue) async {
    setState(() {
      selectedCollection = newValue;
      isCollectionSelectorVisible = false;
      isCrossCollectionSearch = false;
      crossCollectionMessages = [];
      searchResults = [];
      isSearchActive = false;
      currentSearchIndex = -1;
      searchController.clear();
    });

    if (selectedCollection != null) {
      await PhotoHandler.checkPhotoAvailability(selectedCollection, setState);
      await fetchMessages(selectedCollection, fromDate, toDate, setState,
          setLoading, setMessages);
      profilePhotoUrl =
          await ProfilePhotoManager.getProfilePhotoUrl(selectedCollection!);
    } else {
      setState(() {
        isCollectionSelectorVisible = true;
      });
    }
  }

  void _setVisibilityState(VisibilityState newState) {
    setState(() {
      _currentVisibility =
          (_currentVisibility == newState) ? VisibilityState.none : newState;

      // Reset other states based on visibility
      if (_currentVisibility != VisibilityState.search) {
        isSearchBarVisible = false;
        searchController.clear();
        searchResults.clear();
        currentSearchIndex = -1;
        isSearchActive = false;
      }

      if (_currentVisibility != VisibilityState.collectionSelector) {
        isCollectionSelectorVisible = false;
      }
    });
  }

  void toggleSearchBar() {
    if (selectedCollection == null) return;
    _showSearchDialog();
  }

  void toggleCollectionSelector() {
    _setVisibilityState(VisibilityState.collectionSelector);
  }

  void refreshCollections() {
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
      });
    });
  }

  void _handleCrossCollectionSearch(List<dynamic> results) {
    final counts = <String, int>{};
    for (final result in results) {
      final collectionName = result['collectionName'] as String;
      counts[collectionName] = (counts[collectionName] ?? 0) + 1;
    }

    // Initialize selected collections with all collections
    selectedCollections = Set.from(counts.keys);

    setState(() {
      crossCollectionMessages = List<Map<dynamic, dynamic>>.from(results);
      messages = List<Map<dynamic, dynamic>>.from(results);
      isCrossCollectionSearch = true;
      isSearchActive = true;
    });
  }

  void _filterCrossCollectionMessages(Set<String> selectedCollections) {
    setState(() {
      messages = crossCollectionMessages.where((message) {
        return selectedCollections.contains(message['collectionName']);
      }).toList();
    });
  }

  void _showCollectionFilter() {
    if (!isCrossCollectionSearch) return;

    final counts = <String, int>{};
    for (final message in crossCollectionMessages) {
      final collectionName = message['collectionName'] as String;
      counts[collectionName] = (counts[collectionName] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => CrossCollectionFilter(
        collectionCounts: counts,
        selectedCollections: selectedCollections,
        onCollectionsChanged: (collections) {
          selectedCollections = collections;
          _filterCrossCollectionMessages(collections);
        },
      ),
    );
  }

  void handleMessageTap(String collectionName, int timestamp) async {
    if (collectionName != selectedCollection) {
      setState(() {
        messages = [];
        isLoading = true;
        selectedCollection = collectionName;
        isCollectionSelectorVisible = false;
        isCrossCollectionSearch = false;
      });

      try {
        // Load messages for the new collection
        await fetchMessages(
          selectedCollection,
          fromDate,
          toDate,
          setState,
          (bool loading) => setState(() => isLoading = loading),
          (List<dynamic> newMessages) async {
            final processedMessages = List<Map<dynamic, dynamic>>.from(
                newMessages.map((m) => Map<dynamic, dynamic>.from(m)));

            setState(() {
              messages = processedMessages;
              isLoading = false;
            });

            // Important: Wait for the next frame to ensure messages are rendered
            await Future.delayed(const Duration(milliseconds: 100));

            // Now scroll to the target message
            final manager = MessageIndexManager();
            manager.updateMessages(messages);
            final index = manager.getIndexForTimestamp(timestamp);

            if (index != null) {
              scrollToHighlightedMessage(
                index,
                [index],
                itemScrollController,
                SearchType.crossCollection,
              );
            }
          },
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error handling message tap: $e');
        }
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildSearchWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (!isCrossCollectionSearch && searchResults.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: () => navigateSearch(
                -1,
                searchResults,
                currentSearchIndex,
                (index) {
                  setState(() {
                    currentSearchIndex = index;
                  });
                },
                scrollToHighlightedMessage,
                itemScrollController,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: () => navigateSearch(
                1,
                searchResults,
                currentSearchIndex,
                (index) {
                  setState(() {
                    currentSearchIndex = index;
                  });
                },
                scrollToHighlightedMessage,
                itemScrollController,
              ),
            ),
            Text('${currentSearchIndex + 1}/${searchResults.length}'),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: isCrossCollectionSearch
                ? Text('${messages.length} results across collections')
                : Text('Search: $currentSearchQuery'),
          ),
          if (isCrossCollectionSearch)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showCollectionFilter,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meta Elysia'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: toggleSearchBar,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: toggleCollectionSelector,
          ),
        ],
      ),
      drawer: AppDrawer(
        selectedCollection: selectedCollection,
        isPhotoAvailable: isPhotoAvailable,
        isProfilePhotoVisible: _isProfilePhotoVisible,
        fromDate: fromDate,
        toDate: toDate,
        profilePhotoUrl: profilePhotoUrl,
        refreshCollections: refreshCollections,
        setState: setState,
        fetchMessages: fetchMessages,
        setThemeMode: widget.setThemeMode,
        themeMode: widget.themeMode,
        picker: picker,
        onCrossCollectionSearch: _handleCrossCollectionSearch,
        onDrawerClosed: () => _setVisibilityState(VisibilityState.none),
        messages: messages.map((m) => Map<String, dynamic>.from(m)).toList(),
        itemScrollController: itemScrollController,
      ),
      body: Column(
        children: [
          if (isSearchActive) _buildSearchWidget(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading || isCrossCollectionLoading)
                  const Center(child: CircularProgressIndicator())
                else if (messages.isEmpty && !isCollectionSelectorVisible)
                  Center(
                    child: Text(
                      isCrossCollectionSearch
                          ? 'No results found in any collection'
                          : selectedCollection == null
                              ? 'Select a collection to view messages'
                              : 'No messages in this collection',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                else
                  MessageList(
                    messages: isCrossCollectionSearch ? messages : messages,
                    searchResults: searchResults,
                    currentSearchIndex: currentSearchIndex,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    isSearchActive: isSearchVisible,
                    selectedCollectionName: selectedCollection ?? '',
                    profilePhotoUrl: profilePhotoUrl,
                    isCrossCollectionSearch: isCrossCollectionSearch,
                    onMessageTap: handleMessageTap,
                  ),
                if (isCollectionSelectorVisible || selectedCollection == null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CollectionSelector(
                      selectedCollection: selectedCollection,
                      initialCollections: filteredCollections,
                      onCollectionChanged: _changeCollection,
                    ),
                  ),
                if (isPhotoAvailable && selectedCollection != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.network(
                      'https://backend.jevrej.cz/serve/photo/${Uri.encodeComponent(selectedCollection!)}',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Failed to load image');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        title: 'Meta Elysia',
        onSearchPressed: toggleSearchBar,
        onCollectionSelectorPressed: toggleCollectionSelector,
        isCollectionSelectorVisible:
            _currentVisibility == VisibilityState.collectionSelector,
        selectedCollection: selectedCollection ?? '',
        currentVisibility: _currentVisibility,
      ),
    );
  }

  Future<void> loadCollections(
      Function(List<Map<String, dynamic>>) callback) async {
    int maxRetries = 3;
    int currentTry = 0;

    while (currentTry < maxRetries) {
      try {
        final loadedCollections = await ApiService.fetchCollections();
        if (loadedCollections.isNotEmpty) {
          callback(loadedCollections);
          return;
        }

        currentTry++;
        if (currentTry < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * currentTry));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading collections (attempt $currentTry): $e');
        }

        currentTry++;
        if (currentTry < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * currentTry));
        }
      }
    }

    // If we get here, all retries failed
    callback([]); // Return empty list to trigger empty state UI
  }

  void _showSearchDialog() {
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) {
        return SearchDialog(
          onSearch: _handleSearchRequest,
          selectedCollection: selectedCollection,
        );
      },
    );
  }

  void _handleSearchRequest(String query, bool isCrossCollection) {
    Navigator.of(context).pop();
    _processSearch(query, isCrossCollection);
  }

  Future<void> _processSearch(String query, bool isCrossCollection) async {
    if (!mounted) return;

    if (isCrossCollection) {
      setState(() {
        isCrossCollectionLoading = true;
        messages = [];
        crossCollectionMessages = [];
      });

      try {
        final results = await ApiService.performCrossCollectionSearch(query);
        if (!mounted) return;

        _handleCrossCollectionSearch(results);
      } catch (e) {
        if (kDebugMode) {
          print('Error in cross-collection search: $e');
        }
        if (!mounted) return;

        // Show error using the current context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }

      if (!mounted) return;
      setState(() {
        isCrossCollectionLoading = false;
      });
    } else {
      if (!mounted) return;
      _handleRegularSearch(query);
      _setVisibilityState(VisibilityState.none);
    }
  }

  void _handleRegularSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      searchController.text = query;
      currentSearchQuery = query;
      isSearchActive = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchMessages(
        query,
        _debounce,
        setState,
        messages,
        (index) => scrollToHighlightedMessage(
          index,
          searchResults,
          itemScrollController,
          SearchType.searchWidget,
        ),
        (results) {
          setState(() {
            searchResults = results;
            isSearchActive = true;
          });
        },
        (index) {
          setState(() {
            currentSearchIndex = index;
          });
        },
        (active) {
          setState(() {
            isSearchActive = active;
          });
        },
        selectedCollection,
      );
    });
  }
}
