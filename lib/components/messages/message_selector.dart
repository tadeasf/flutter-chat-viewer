import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
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

  void _navigateSearch(int direction) {
    navigateSearch(
      direction,
      searchResults,
      currentSearchIndex,
      (index) {
        setState(() {
          currentSearchIndex = index;
        });
      },
      scrollToHighlightedMessage,
      itemScrollController,
    );
  }

  Future<void> _changeCollection(String? newValue) async {
    setState(() {
      selectedCollection = newValue;
      isCollectionSelectorVisible = false;
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

  void toggleSearchBar() {
    if (selectedCollection == null) return;

    setState(() {
      isSearchBarVisible = !isSearchBarVisible;
      if (isSearchBarVisible) {
        isCollectionSelectorVisible = false;
      }
      // Clear search when closing
      if (!isSearchBarVisible) {
        searchController.clear();
        searchResults.clear();
        currentSearchIndex = -1;
        isSearchActive = false;
      }
    });
  }

  void _handleSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        isGlobalLoading = true;
      });

      searchMessages(
        query,
        _debounce,
        setState,
        messages,
        (index) {
          if (searchResults.isNotEmpty &&
              index >= 0 &&
              index < searchResults.length) {
            Future.microtask(() => scrollToHighlightedMessage(
                  index,
                  searchResults,
                  itemScrollController,
                  SearchType.searchWidget,
                ));
          }
        },
        (results) {
          setState(() {
            searchResults = results;
            currentFoundMatches = results.length;
            isSearchActive = results.isNotEmpty;
            isGlobalLoading = false;
            if (results.isNotEmpty) {
              currentSearchIndex = 0;
              Future.microtask(() => scrollToHighlightedMessage(
                    0,
                    results,
                    itemScrollController,
                    SearchType.searchWidget,
                  ));
            } else {
              currentSearchIndex = -1;
            }
          });
        },
        updateCurrentSearchIndex,
        (active) {
          setState(() {
            isSearchActive = active;
          });
        },
        selectedCollection,
      );
    });
  }

  void refreshCollections() {
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
      });
    });
  }

  void toggleCollectionSelector() {
    setState(() {
      isCollectionSelectorVisible = !isCollectionSelectorVisible;
    });
  }

  void _handleCrossCollectionSearch(List<dynamic> searchResults) {
    setState(() {
      crossCollectionMessages = searchResults.where((result) {
        if (result is! Map) return false;
        return result['collectionName'] != 'unified_collection';
      }).map((result) {
        return Map<dynamic, dynamic>.from({
          'content': _decodeIfNeeded(result['content'] ?? ''),
          'sender_name': _decodeIfNeeded(result['sender_name'] ?? 'Unknown'),
          'collectionName':
              _decodeIfNeeded(result['collectionName'] ?? 'Unknown Collection'),
          'timestamp_ms': result['timestamp_ms'] ?? 0,
          'photos': result['photos'] ?? [],
          'is_geoblocked_for_viewer':
              result['is_geoblocked_for_viewer'] ?? false,
          'is_online': result['is_online'] ?? false,
        });
      }).toList();
      isCrossCollectionSearch = true;
    });
  }

  String _decodeIfNeeded(String? text) {
    if (text == null) return '';
    try {
      return utf8.decode(text.runes.toList());
    } catch (e) {
      return text;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadCollections((loadedCollections) {
            setState(() {
              collections = loadedCollections;
              filteredCollections = loadedCollections;
            });
          });
        },
        child: collections.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Pull down to refresh collections'),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Meta Elysia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : MessageList(
                            messages: isCrossCollectionSearch
                                ? crossCollectionMessages
                                : messages,
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
                  if (isSearchBarVisible) ...[
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Search messages...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward),
                                    onPressed: () => _navigateSearch(-1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward),
                                    onPressed: () => _navigateSearch(1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: toggleSearchBar,
                                  ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: _handleSearch,
                          ),
                          if (isGlobalLoading)
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Found $currentFoundMatches matches so far...'),
                                ],
                              ),
                            ),
                          if (!isGlobalLoading && searchResults.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${currentSearchIndex + 1}/${searchResults.length} results',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
      bottomNavigationBar: Navbar(
        title: 'Meta Elysia',
        onSearchPressed: toggleSearchBar,
        onCollectionSelectorPressed: toggleCollectionSelector,
        isCollectionSelectorVisible: isCollectionSelectorVisible,
        selectedCollection: selectedCollection ?? '',
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
}
