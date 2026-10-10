import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'message_list.dart';
import 'message_item.dart';
import '../../utils/api_db/api_service.dart';
import '../app_drawer.dart';
import 'collection_selector.dart';
import '../navbar.dart';
import '../ui_utils/visibility_state.dart';
import '../search/search_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../stores/store_provider.dart';
import '../../stores/message_store.dart';
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
  TextEditingController searchController = TextEditingController();
  bool isPhotoAvailable = false;

  /// Hits of the search inside the open conversation, oldest first.
  List<Map<String, dynamic>> searchResults = [];
  int currentSearchIndex = -1;
  Timer? _debounce;
  bool isSearchActive = false;
  String? profilePhotoUrl;
  final bool _isProfilePhotoVisible = true;

  bool isCollectionSelectorVisible = false;
  List<Map<dynamic, dynamic>> crossCollectionMessages = [];
  bool isCrossCollectionSearch = false;
  VisibilityState _currentVisibility = VisibilityState.none;
  final FocusNode _searchFocusNode = FocusNode();
  bool isCrossCollectionLoading = false;
  String? currentSearchQuery;

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void setLoading(bool value) {
    if (!mounted) return;
    // Use the CollectionStore to set message loading state
    final store = StoreProvider.of(context).collectionStore;
    store.setMessageLoading(value);
  }

  void _showSearchResult(int index) {
    if (index < 0 || index >= searchResults.length) return;
    final hit = searchResults[index];
    setState(() => currentSearchIndex = index);
    StoreProvider.of(context)
        .messageStore
        .jumpTo(hit['timestamp_ms'] as int, id: hit['_id'] as String?);
  }

  void _navigateSearch(int direction) {
    if (searchResults.isEmpty) return;
    _showSearchResult((currentSearchIndex + direction) % searchResults.length);
  }

  Future<void> _changeCollection(String? newValue) async {
    final messageStore = StoreProvider.of(context).messageStore;
    final photoStore = StoreProvider.of(context).photoStore;
    final profilePhotoStore = StoreProvider.of(context).profilePhotoStore;

    setState(() {
      selectedCollection = newValue;
      isCollectionSelectorVisible = newValue == null;
      isCrossCollectionSearch = false;
      crossCollectionMessages = [];
      searchResults = [];
      isSearchActive = false;
      currentSearchIndex = -1;
      searchController.clear();
    });
    if (newValue == null) return;

    setLoading(true);
    final photoAvailable = photoStore.checkPhotoAvailability(newValue);
    final photoUrl = profilePhotoStore.getProfilePhotoUrl(newValue);
    await messageStore.open(newValue);
    final available = await photoAvailable;
    final url = await photoUrl;
    if (!mounted) return;
    setState(() {
      isPhotoAvailable = available;
      profilePhotoUrl = url;
    });
    setLoading(false);
  }

  void _setVisibilityState(VisibilityState newState) {
    setState(() {
      _currentVisibility =
          (_currentVisibility == newState) ? VisibilityState.none : newState;

      // Reset other states based on visibility
      if (_currentVisibility != VisibilityState.search) {
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
        if (selectedCollection != null) {
          StoreProvider.of(context)
              .photoStore
              .showAllPhotos(context, selectedCollection);
        }
      },
      onCollectionSelectorToggle: toggleCollectionSelector,
      child: DarkGeometricBackground(
        child: Scaffold(
          drawer: AppDrawer(
            selectedCollection: selectedCollection,
            isPhotoAvailable: isPhotoAvailable,
            isProfilePhotoVisible: _isProfilePhotoVisible,
            profilePhotoUrl: profilePhotoUrl,
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
                    final collections = collectionStore.collections;
                    final messageStore = StoreProvider.of(context).messageStore;

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
                          child: _buildMessages(messageStore),
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
                              ApiService.profilePhotoUrl(selectedCollection!),
                              headers: ApiService.headers,
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
        crossCollectionMessages = [];
      });

      try {
        final results = await ApiService.search(query);
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
    _debounce?.cancel();
    setState(() {
      searchController.text = query;
      currentSearchQuery = query;
      isSearchActive = true;
      searchResults = [];
      currentSearchIndex = -1;
    });
    final collection = selectedCollection;
    if (query.trim().isEmpty || collection == null) return;

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final hits = await _searchInConversation(query.trim(), collection);
        if (!mounted || currentSearchQuery != query) return;
        setState(() {
          searchResults = hits;
          isSearchActive = true;
        });
        _showSearchResult(0);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    });
  }

  /// Substring search on the server (whole conversation, oldest first).
  /// The keyword "photo" lists the other person's photos, as before.
  Future<List<Map<String, dynamic>>> _searchInConversation(
      String query, String collection) async {
    if (query.toLowerCase() == 'photo') {
      final photos = await ApiService.fetchPhotos(collection);
      return photos.map((m) => {'timestamp_ms': m['timestamp_ms']}).toList()
        ..sort((a, b) =>
            (a['timestamp_ms'] as int).compareTo(b['timestamp_ms'] as int));
    }
    return ApiService.search(query, collectionName: collection);
  }

  Future<void> _handleCrossCollectionMessageTap(
      String collectionName, int timestamp) async {
    setState(() {
      isSearchActive = false;
      isCrossCollectionSearch = false;
      searchResults = [];
      currentSearchQuery = null;
      currentSearchIndex = -1;
    });
    await _changeCollection(collectionName);
    if (!mounted) return;
    await StoreProvider.of(context).messageStore.jumpTo(timestamp);
  }

  Widget _buildMessages(MessageStore messageStore) {
    if (isCrossCollectionLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (isCrossCollectionSearch) {
      return ListView.builder(
        itemCount: crossCollectionMessages.length,
        itemBuilder: (context, i) {
          final message = Map<String, dynamic>.from(crossCollectionMessages[i]);
          return MessageItem(
            message: message,
            isAuthor: message['sender_name'] == ownerName,
            isHighlighted: false,
            selectedCollectionName: message['collectionName'] ?? '',
            profilePhotoUrl: null,
            isCrossCollectionSearch: true,
            onMessageTap: _handleCrossCollectionMessageTap,
          );
        },
      );
    }
    if (selectedCollection == null) {
      return const Center(child: Text('Select a collection'));
    }
    if (messageStore.isLoading && messageStore.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messageStore.error != null && messageStore.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load messages: ${messageStore.error}'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _changeCollection(selectedCollection),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (messageStore.messages.isEmpty) {
      return const Center(child: Text('No messages found'));
    }
    return MessageList(
      store: messageStore,
      profilePhotoUrl: profilePhotoUrl,
    );
  }
}
