import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'message_list.dart';
import '../../utils/api_db/api_service.dart';
// ignore: unused_import
import '../search/navigate_search.dart';
import '../app_drawer.dart';
import 'collection_selector.dart';
import '../navbar.dart';
import '../../utils/search/scroll_to_highlighted_message.dart';
import '../search/search_messages.dart';
import '../../utils/search/search_type.dart';
import '../ui_utils/visibility_state.dart';
import '../search/search_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../stores/store_provider.dart';
import '../../widgets/ui_utils/dark_geometric_background.dart';

final searchKeySet = LogicalKeySet(
  LogicalKeyboardKey.meta, // Use control on Windows
  LogicalKeyboardKey.keyF,
);

final previousResultKeySet = LogicalKeySet(
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.keyJ,
);

final nextResultKeySet = LogicalKeySet(
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.keyK,
);

final galleryKeySet = LogicalKeySet(
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.keyG,
);

final collectionSelectorKeySet = LogicalKeySet(
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.keyC,
);

class SearchIntent extends Intent {}

class PreviousResultIntent extends Intent {}

class NextResultIntent extends Intent {}

class GalleryIntent extends Intent {}

class CollectionSelectorIntent extends Intent {}

class MessageSelectorShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onSearchTriggered;
  final VoidCallback onPreviousResult;
  final VoidCallback onNextResult;
  final VoidCallback onGalleryOpen;
  final VoidCallback onCollectionSelectorToggle;

  const MessageSelectorShortcuts({
    super.key,
    required this.child,
    required this.onSearchTriggered,
    required this.onPreviousResult,
    required this.onNextResult,
    required this.onGalleryOpen,
    required this.onCollectionSelectorToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        searchKeySet: SearchIntent(),
        previousResultKeySet: PreviousResultIntent(),
        nextResultKeySet: NextResultIntent(),
        galleryKeySet: GalleryIntent(),
        collectionSelectorKeySet: CollectionSelectorIntent(),
      },
      actions: {
        SearchIntent: CallbackAction(
          onInvoke: (intent) {
            onSearchTriggered();
            return null;
          },
        ),
        PreviousResultIntent: CallbackAction(
          onInvoke: (intent) {
            onPreviousResult();
            return null;
          },
        ),
        NextResultIntent: CallbackAction(
          onInvoke: (intent) {
            onNextResult();
            return null;
          },
        ),
        GalleryIntent: CallbackAction(
          onInvoke: (intent) {
            onGalleryOpen();
            return null;
          },
        ),
        CollectionSelectorIntent: CallbackAction(
          onInvoke: (intent) {
            onCollectionSelectorToggle();
            return null;
          },
        ),
      },
      child: child,
    );
  }
}

class MessageSelector extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;

  const MessageSelector(
      {super.key, required this.setThemeMode, required this.themeMode});

  @override
  MessageSelectorState createState() => MessageSelectorState();
}

class MessageSelectorState extends State<MessageSelector> {
  String? selectedCollection;
  DateTime? fromDate;
  DateTime? toDate;
  List<Map<dynamic, dynamic>> messages = [];
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
  int get maxCollectionIndex {
    final store = StoreProvider.of(context).collectionStore;
    final filteredList = store.filteredCollections;
    return filteredList.isNotEmpty
        ? filteredList
            .map((c) => c['index'] as int? ?? 0)
            .reduce((a, b) => a > b ? a : b)
        : 0;
  }

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

  @override
  void initState() {
    super.initState();
    // Get collections from the CollectionStore instead of loading directly
    // The store will automatically load collections when it's initialized
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
    if (!mounted) return;
    // Use the CollectionStore to set message loading state
    final store = StoreProvider.of(context).collectionStore;
    store.setMessageLoading(value);
  }

  void setMessages(List<dynamic> rawMessages) {
    if (rawMessages.isEmpty) return;

    // Get the MessageStore instance
    final messageStore = StoreProvider.of(context).messageStore;

    // Process the loaded messages
    final processedMessages = rawMessages.map((message) {
      if (message is! Map) return <String, dynamic>{};
      return Map<String, dynamic>.from(message);
    }).toList();

    // Sort messages by timestamp in ascending order (oldest first)
    processedMessages.sort((a, b) => (a['timestamp_ms'] as int? ?? 0)
        .compareTo(b['timestamp_ms'] as int? ?? 0));

    // Clear existing messages and add all at once
    messageStore.messages.clear();
    messageStore.messages.addAll(processedMessages);
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

  void _navigateSearch(int direction) {
    // Create a wrapper that returns the expected type
    dynamic scrollWrapper(int index, List<int> indices,
        ItemScrollController controller, SearchType type) {
      scrollToHighlightedMessage(index, indices, controller, type);
      return true; // Return any non-null value
    }

    navigateSearch(
      direction,
      searchResults,
      currentSearchIndex,
      (index) {
        setState(() {
          currentSearchIndex = index;
        });
      },
      scrollWrapper,
      itemScrollController,
    );
  }

  Future<void> _changeCollection(String? newValue) async {
    // Use MessageStore for collection change and message loading
    final messageStore = StoreProvider.of(context).messageStore;
    final photoStore = StoreProvider.of(context).photoStore;

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
      // Set loading state
      setLoading(true);

      // Use MessageStore to load messages for the new collection
      await messageStore.setCollection(selectedCollection);

      if (!mounted) return;

      // Check photo availability after collection is set
      final isAvailable =
          await photoStore.checkPhotoAvailability(selectedCollection);
      setState(() {
        isPhotoAvailable = isAvailable;
      });

      if (!mounted) return;

      // Get profile photo URL
      profilePhotoUrl = await StoreProvider.of(context)
          .profilePhotoStore
          .getProfilePhotoUrl(selectedCollection!);

      // Update messages from store to local state for rendering
      setState(() {
        messages = messageStore.messages.toList();
      });

      // Turn off loading state
      setLoading(false);
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
    setState(() {
      // Reset search state when toggling search bar
      if (_currentVisibility == VisibilityState.search) {
        searchResults = [];
        currentSearchIndex = -1;
        isSearchActive = false;
        currentSearchQuery = null;
      }
      _currentVisibility = _currentVisibility == VisibilityState.search
          ? VisibilityState.none
          : VisibilityState.search;
    });
  }

  void toggleCollectionSelector() {
    _setVisibilityState(VisibilityState.collectionSelector);
  }

  void _handleSearch(String query, bool isCrossCollection) {
    // Reset search state before starting new search
    setState(() {
      searchResults = [];
      currentSearchIndex = -1;
      isSearchActive = false;
      currentSearchQuery = query;
    });

    // Proceed with search
    _processSearch(query, isCrossCollection);
  }

  void refreshCollections() {
    // Update to use the CollectionStore
    final store = StoreProvider.of(context).collectionStore;
    store.refreshCollections();
  }

  void _handleCrossCollectionSearch(List<dynamic> results) {
    setState(() {
      crossCollectionMessages = results.map((result) {
        if (result is! Map) return <String, dynamic>{};

        // Check if this is an Instagram message by the presence of is_geoblocked_for_viewer
        final isInstagramMessage =
            result.containsKey('is_geoblocked_for_viewer');

        return Map<dynamic, dynamic>.from({
          'content': _decodeIfNeeded(result['content']),
          'sender_name': _decodeIfNeeded(result['sender_name']),
          'collectionName': _decodeIfNeeded(result['collectionName']),
          'timestamp_ms': result['timestamp_ms'] ?? 0,
          'photos': result['photos'] ?? [],
          'is_geoblocked_for_viewer': result['is_geoblocked_for_viewer'],
          'is_online': result['is_online'] ?? false,
          'is_instagram': isInstagramMessage, // Add this flag for styling
        });
      }).toList();

      isCrossCollectionSearch = true;
      isSearchActive = true;
      messages = crossCollectionMessages;
    });
  }

  String _decodeIfNeeded(dynamic text) {
    if (text == null) return '';
    try {
      return utf8.decode(text.toString().codeUnits);
    } catch (e) {
      return text.toString();
    }
  }

  void handleMessageTap(String collectionName, int timestamp) async {
    if (collectionName != selectedCollection) {
      setState(() {
        messages = [];
        selectedCollection = collectionName;
        isCollectionSelectorVisible = false;
        isCrossCollectionSearch = false;
      });

      try {
        // Get stores from context
        final messageStore = StoreProvider.of(context).messageStore;
        final collectionStore = StoreProvider.of(context).collectionStore;

        // Set message loading to true
        collectionStore.setMessageLoading(true);

        // Fetch messages directly using MessageStore
        await messageStore.fetchMessagesForDateRange(
            collectionName, fromDate, toDate);

        if (!mounted) return;

        // Process messages
        final processedMessages = List<Map<dynamic, dynamic>>.from(messageStore
            .filteredMessages
            .map((m) => Map<dynamic, dynamic>.from(m)));

        setState(() {
          messages = processedMessages;
        });

        // Set message loading to false
        collectionStore.setMessageLoading(false);

        // Important: Wait for the next frame to ensure messages are rendered
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        // Now scroll to the target message
        final messageIndexStore = StoreProvider.of(context).messageIndexStore;
        messageIndexStore.updateMessagesFromRaw(messages);
        final index = messageIndexStore.getIndexForTimestampRaw(timestamp);

        if (index != null) {
          scrollToHighlightedMessage(
            index,
            [index],
            itemScrollController,
            SearchType.crossCollection,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error handling message tap: $e');
        }

        if (!mounted) return;

        // Set message loading to false using the store
        final store = StoreProvider.of(context).collectionStore;
        store.setMessageLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MessageSelectorShortcuts(
      onSearchTriggered: () {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return SearchDialog(
              onSearch: _handleSearchRequest,
              selectedCollection: selectedCollection,
            );
          },
        );
      },
      onPreviousResult: () {
        if (isSearchActive) {
          _navigateSearch(-1);
        }
      },
      onNextResult: () {
        if (isSearchActive) {
          _navigateSearch(1);
        }
      },
      onGalleryOpen: () {
        if (selectedCollection != null && messages.isNotEmpty) {
          final photoStore = StoreProvider.of(context).photoStore;
          photoStore.showAllPhotos(
            context,
            selectedCollection,
            messages: messages,
            itemScrollController: itemScrollController,
          );
        }
      },
      onCollectionSelectorToggle: toggleCollectionSelector,
      child: DarkGeometricBackground(
        child: Scaffold(
          drawer: AppDrawer(
            selectedCollection: selectedCollection,
            isPhotoAvailable: isPhotoAvailable,
            isProfilePhotoVisible: _isProfilePhotoVisible,
            fromDate: fromDate,
            toDate: toDate,
            profilePhotoUrl: profilePhotoUrl,
            messages:
                messages.map((m) => Map<String, dynamic>.from(m)).toList(),
            itemScrollController: itemScrollController,
            onDrawerClosed: () => _setVisibilityState(VisibilityState.none),
            onFontSizeChanged: () {
              setState(() {
                // This will trigger a rebuild with the new font size
              });
            },
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  final store = StoreProvider.of(context).collectionStore;
                  // Force a refresh here since this is an explicit user action
                  await store.refreshCollections();
                },
                child: Observer(
                  builder: (context) {
                    final collectionStore =
                        StoreProvider.of(context).collectionStore;
                    final isCollectionLoading = collectionStore.isLoading;
                    final isMessageLoading = collectionStore.isMessageLoading;
                    final collections = collectionStore.collections;

                    if (collections.isEmpty && isCollectionLoading) {
                      return ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Loading collections...',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono Nerd Font',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else if (collections.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pull down to refresh collections',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono Nerd Font',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Meta Elysia',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontFamily: 'JetBrains Mono Nerd Font',
                                  fontSize: 12,
                                ),
                          ),
                        ),
                        Expanded(
                          child: isMessageLoading || isCrossCollectionLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        selectedCollection != null
                                            ? 'Loading messages...'
                                            : 'Select a collection',
                                        style: const TextStyle(
                                          fontFamily:
                                              'JetBrains Mono Nerd Font',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : messages.isEmpty && selectedCollection != null
                                  ? const Center(
                                      child: Text(
                                        'No messages found',
                                        style: TextStyle(
                                          fontFamily:
                                              'JetBrains Mono Nerd Font',
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : MessageList(
                                      messages: isCrossCollectionSearch
                                          ? crossCollectionMessages
                                          : messages,
                                      searchResults: searchResults,
                                      currentSearchIndex: currentSearchIndex,
                                      itemScrollController:
                                          itemScrollController,
                                      itemPositionsListener:
                                          itemPositionsListener,
                                      isSearchActive: isSearchVisible,
                                      selectedCollectionName:
                                          selectedCollection ?? '',
                                      profilePhotoUrl: profilePhotoUrl,
                                      isCrossCollectionSearch:
                                          isCrossCollectionSearch,
                                      onMessageTap:
                                          _handleCrossCollectionMessageTap,
                                    ),
                        ),
                        if (isCollectionSelectorVisible ||
                            selectedCollection == null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CollectionSelector(
                              selectedCollection: selectedCollection,
                              initialCollections:
                                  collectionStore.filteredCollections.toList(),
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
                                return const Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono Nerd Font',
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (_currentVisibility == VisibilityState.collectionSelector)
                _buildCollectionSelectorOverlay(),
            ],
          ),
          bottomNavigationBar: isSearchActive
              ? _buildSearchResultsBar()
              : (_currentVisibility == VisibilityState.search
                  ? _buildSearchOverlay()
                  : Navbar(
                      title: selectedCollection ?? '',
                      onSearchPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return SearchDialog(
                              onSearch: _handleSearchRequest,
                              selectedCollection: selectedCollection,
                            );
                          },
                        );
                      },
                      onCollectionSelectorPressed: toggleCollectionSelector,
                      isCollectionSelectorVisible: isCollectionSelectorVisible,
                      selectedCollection: selectedCollection,
                      currentVisibility: _currentVisibility,
                      onCrossCollectionSearch: (results) {
                        setState(() {
                          crossCollectionMessages = results
                              .map((result) => {
                                    'content': result['content'],
                                    'sender_name': result['sender_name'],
                                    'collectionName': result['collectionName'],
                                    'timestamp_ms': result['timestamp_ms'] ?? 0,
                                    'photos': result['photos'] ?? [],
                                    'is_geoblocked_for_viewer':
                                        result['is_geoblocked_for_viewer'] ??
                                            false,
                                    'is_online': result['is_online'] ?? false,
                                  })
                              .toList();
                          isCrossCollectionSearch = true;
                          messages = crossCollectionMessages;
                          isSearchActive = true;
                        });
                      },
                    )),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    if (_currentVisibility != VisibilityState.search) {
      return _buildSearchResultsBar();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 156),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: kBottomNavigationBarHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 76),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 25),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 76),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.white24,
                        width: 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'JetBrains Mono Nerd Font',
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w300,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
                        hintStyle: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono Nerd Font',
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w300,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                          size: 16.0,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 12.0,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        _handleSearch(value, false);
                        _setVisibilityState(VisibilityState.none);
                      },
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20.0,
                ),
                padding: const EdgeInsets.all(12.0),
                onPressed: toggleSearchBar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsBar() {
    // Don't show search results bar for cross-collection searches or when search is not active
    if (!isSearchActive || isCrossCollectionSearch) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final String displayText = searchResults.isNotEmpty
        ? '"${currentSearchQuery ?? ""}" (${currentSearchIndex + 1}/${searchResults.length})'
        : 'No results for "${currentSearchQuery ?? ""}"';

    return Container(
      height: kBottomNavigationBarHeight,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Color(0xFF121214)
            : theme.colorScheme.primary.withValues(alpha: 26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                displayText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isDarkMode ? Colors.white70 : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (searchResults.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color:
                    isDarkMode ? Colors.white70 : theme.colorScheme.onSurface,
              ),
              onPressed: () => _navigateSearch(-1),
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_downward,
                color:
                    isDarkMode ? Colors.white70 : theme.colorScheme.onSurface,
              ),
              onPressed: () => _navigateSearch(1),
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDarkMode ? Colors.white70 : theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                searchController.clear();
                searchResults.clear();
                isSearchActive = false;
                currentSearchQuery = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionSelectorOverlay() {
    final store = StoreProvider.of(context).collectionStore;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Observer(builder: (_) {
          return CollectionSelector(
            selectedCollection: selectedCollection,
            initialCollections: store.filteredCollections.toList(),
            onCollectionChanged: _changeCollection,
          );
        }),
      ),
    );
  }

  void _handleSearchRequest(String query, bool isCrossCollection) {
    if (mounted) {
      setState(() {
        _currentVisibility = VisibilityState.search;
      });
      _processSearch(query, isCrossCollection);
    }
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

  void _handleCrossCollectionMessageTap(
      String collectionName, int timestamp) async {
    // Reset search states before switching collection
    setState(() {
      isSearchActive = false;
      isCrossCollectionSearch = false;
      searchResults = [];
      currentSearchQuery = null;
      currentSearchIndex = -1;
    });

    // Store selected timestamp before collection change
    final targetTimestamp = timestamp;

    // Switch collection and scroll to message
    await _changeCollection(collectionName);
    if (!mounted) return;

    // Wait for messages to be loaded and UI to update
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Find the message index and scroll to it without triggering search UI
    final messageIndexStore = StoreProvider.of(context).messageIndexStore;
    messageIndexStore.updateMessagesFromRaw(messages);
    final messageIndex =
        messageIndexStore.getIndexForTimestampRaw(targetTimestamp);
    if (messageIndex != null) {
      // Use searchResults with single item to allow proper highlighting
      setState(() {
        searchResults = [messageIndex];
        currentSearchIndex = 0;
      });

      scrollToHighlightedMessage(
        messageIndex,
        searchResults,
        itemScrollController,
        SearchType.crossCollection,
      );
    }
  }

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Scale factor based on screen width
    // Adjust these values based on your needs
    double scaleFactor = screenWidth < 600
        ? 0.9
        : screenWidth < 1200
            ? 1.0
            : 1.1;

    return baseSize * scaleFactor;
  }
}
