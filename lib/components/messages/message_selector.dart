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
import '../../utils/api_db/database_manager.dart';
import '../search/navigate_search.dart';
import '../app_drawer.dart';
import 'collection_selector.dart';
import '../navbar.dart';
import '../search/scroll_to_highlighted_message.dart';
import '../search/search_messages.dart';
import 'message_index_manager.dart';

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
    setState(() {
      currentSearchIndex = index;
    });
  }

  void _navigateSearch(int direction) {
    navigateSearch(
      direction,
      searchResults,
      currentSearchIndex,
      (int index) {
        setState(() {
          currentSearchIndex = index;
        });
        scrollToHighlightedMessage(index, searchResults, itemScrollController);
      },
      () {},
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

  // Add this method
  void _performSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchMessages(
        query,
        _debounce,
        setState,
        messages,
        scrollToHighlightedMessage,
        (results) {
          setState(() {
            searchResults = results;
          });
        },
        updateCurrentSearchIndex,
        (active) {
          setState(() {
            isSearchActive = active;
          });
        },
        selectedCollection,
        itemScrollController,
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
      crossCollectionMessages = searchResults.map((result) {
        if (result is! Map) return <String, dynamic>{};

        return <dynamic, dynamic>{
          'content': _decodeIfNeeded(result['content'] ?? ''),
          'sender_name': _decodeIfNeeded(result['sender_name'] ?? 'Unknown'),
          'collectionName':
              _decodeIfNeeded(result['collectionName'] ?? 'Unknown Collection'),
          'timestamp_ms': result['timestamp_ms'] ?? 0,
          'photos': result['photos'] ?? [],
          'is_geoblocked_for_viewer': result['is_geoblocked_for_viewer'],
          'is_online': result['is_online'] ?? false,
        };
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

  Future<void> _navigateToMessage(String collectionName, int timestamp) async {
    if (isCrossCollectionSearch && collectionName != selectedCollection) {
      setState(() {
        isLoading = true;
      });
      await _changeCollection(collectionName);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        isLoading = false;
        isCrossCollectionSearch = false;
        crossCollectionMessages = [];
      });
    }

    final manager = MessageIndexManager();
    manager.updateMessages(
        isCrossCollectionSearch ? crossCollectionMessages : messages);
    final messageIndex =
        manager.getIndexForTimestamp(timestamp, isPhotoSearch: true);

    if (messageIndex != null) {
      await scrollToHighlightedMessage(0, [messageIndex], itemScrollController);
      setState(() {
        searchResults = [messageIndex];
        currentSearchIndex = 0;
        isSearchVisible = true;
        isSearchActive = true;
      });
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
                            onMessageTap: _navigateToMessage,
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
                  if (isSearchVisible) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search messages',
                                suffixIcon: Icon(Icons.search),
                              ),
                              onChanged: _performSearch,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: () => _navigateSearch(-1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: () => _navigateSearch(1),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                          '${searchResults.isNotEmpty ? currentSearchIndex + 1 : 0}/${searchResults.length} results'),
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
        onSearchPressed: () {
          setState(() {
            isSearchVisible = !isSearchVisible;
            if (!isSearchVisible) {
              searchController.clear();
              searchResults.clear();
              currentSearchIndex = -1;
              isSearchActive = false;
            }
          });
        },
        onDatabasePressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Database Management'),
                content:
                    DatabaseManager(refreshCollections: refreshCollections),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        onCollectionSelectorPressed: toggleCollectionSelector,
        isCollectionSelectorVisible: isCollectionSelectorVisible,
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
