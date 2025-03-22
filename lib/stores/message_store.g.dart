// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MessageStore on MessageStoreBase, Store {
  Computed<List<Map<dynamic, dynamic>>>? _$sortedMessagesComputed;

  @override
  List<Map<dynamic, dynamic>> get sortedMessages =>
      (_$sortedMessagesComputed ??= Computed<List<Map<dynamic, dynamic>>>(
              () => super.sortedMessages,
              name: 'MessageStoreBase.sortedMessages'))
          .value;

  late final _$messagesAtom =
      Atom(name: 'MessageStoreBase.messages', context: context);

  @override
  ObservableList<Map<dynamic, dynamic>> get messages {
    _$messagesAtom.reportRead();
    return super.messages;
  }

  @override
  set messages(ObservableList<Map<dynamic, dynamic>> value) {
    _$messagesAtom.reportWrite(value, super.messages, () {
      super.messages = value;
    });
  }

  late final _$crossCollectionMessagesAtom =
      Atom(name: 'MessageStoreBase.crossCollectionMessages', context: context);

  @override
  ObservableList<Map<dynamic, dynamic>> get crossCollectionMessages {
    _$crossCollectionMessagesAtom.reportRead();
    return super.crossCollectionMessages;
  }

  @override
  set crossCollectionMessages(ObservableList<Map<dynamic, dynamic>> value) {
    _$crossCollectionMessagesAtom
        .reportWrite(value, super.crossCollectionMessages, () {
      super.crossCollectionMessages = value;
    });
  }

  late final _$allPhotosAtom =
      Atom(name: 'MessageStoreBase.allPhotos', context: context);

  @override
  ObservableList<Map<String, dynamic>> get allPhotos {
    _$allPhotosAtom.reportRead();
    return super.allPhotos;
  }

  @override
  set allPhotos(ObservableList<Map<String, dynamic>> value) {
    _$allPhotosAtom.reportWrite(value, super.allPhotos, () {
      super.allPhotos = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'MessageStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$isCrossCollectionLoadingAtom =
      Atom(name: 'MessageStoreBase.isCrossCollectionLoading', context: context);

  @override
  bool get isCrossCollectionLoading {
    _$isCrossCollectionLoadingAtom.reportRead();
    return super.isCrossCollectionLoading;
  }

  @override
  set isCrossCollectionLoading(bool value) {
    _$isCrossCollectionLoadingAtom
        .reportWrite(value, super.isCrossCollectionLoading, () {
      super.isCrossCollectionLoading = value;
    });
  }

  late final _$currentCollectionAtom =
      Atom(name: 'MessageStoreBase.currentCollection', context: context);

  @override
  String? get currentCollection {
    _$currentCollectionAtom.reportRead();
    return super.currentCollection;
  }

  @override
  set currentCollection(String? value) {
    _$currentCollectionAtom.reportWrite(value, super.currentCollection, () {
      super.currentCollection = value;
    });
  }

  late final _$searchResultsAtom =
      Atom(name: 'MessageStoreBase.searchResults', context: context);

  @override
  ObservableList<int> get searchResults {
    _$searchResultsAtom.reportRead();
    return super.searchResults;
  }

  @override
  set searchResults(ObservableList<int> value) {
    _$searchResultsAtom.reportWrite(value, super.searchResults, () {
      super.searchResults = value;
    });
  }

  late final _$currentSearchIndexAtom =
      Atom(name: 'MessageStoreBase.currentSearchIndex', context: context);

  @override
  int get currentSearchIndex {
    _$currentSearchIndexAtom.reportRead();
    return super.currentSearchIndex;
  }

  @override
  set currentSearchIndex(int value) {
    _$currentSearchIndexAtom.reportWrite(value, super.currentSearchIndex, () {
      super.currentSearchIndex = value;
    });
  }

  late final _$isSearchActiveAtom =
      Atom(name: 'MessageStoreBase.isSearchActive', context: context);

  @override
  bool get isSearchActive {
    _$isSearchActiveAtom.reportRead();
    return super.isSearchActive;
  }

  @override
  set isSearchActive(bool value) {
    _$isSearchActiveAtom.reportWrite(value, super.isSearchActive, () {
      super.isSearchActive = value;
    });
  }

  late final _$currentSearchQueryAtom =
      Atom(name: 'MessageStoreBase.currentSearchQuery', context: context);

  @override
  String? get currentSearchQuery {
    _$currentSearchQueryAtom.reportRead();
    return super.currentSearchQuery;
  }

  @override
  set currentSearchQuery(String? value) {
    _$currentSearchQueryAtom.reportWrite(value, super.currentSearchQuery, () {
      super.currentSearchQuery = value;
    });
  }

  late final _$fromDateAtom =
      Atom(name: 'MessageStoreBase.fromDate', context: context);

  @override
  DateTime? get fromDate {
    _$fromDateAtom.reportRead();
    return super.fromDate;
  }

  @override
  set fromDate(DateTime? value) {
    _$fromDateAtom.reportWrite(value, super.fromDate, () {
      super.fromDate = value;
    });
  }

  late final _$toDateAtom =
      Atom(name: 'MessageStoreBase.toDate', context: context);

  @override
  DateTime? get toDate {
    _$toDateAtom.reportRead();
    return super.toDate;
  }

  @override
  set toDate(DateTime? value) {
    _$toDateAtom.reportWrite(value, super.toDate, () {
      super.toDate = value;
    });
  }

  late final _$isCrossCollectionSearchAtom =
      Atom(name: 'MessageStoreBase.isCrossCollectionSearch', context: context);

  @override
  bool get isCrossCollectionSearch {
    _$isCrossCollectionSearchAtom.reportRead();
    return super.isCrossCollectionSearch;
  }

  @override
  set isCrossCollectionSearch(bool value) {
    _$isCrossCollectionSearchAtom
        .reportWrite(value, super.isCrossCollectionSearch, () {
      super.isCrossCollectionSearch = value;
    });
  }

  late final _$fetchMessagesAsyncAction =
      AsyncAction('MessageStoreBase.fetchMessages', context: context);

  @override
  Future<void> fetchMessages(String? collectionName,
      {DateTime? fromDate, DateTime? toDate}) {
    return _$fetchMessagesAsyncAction.run(() => super
        .fetchMessages(collectionName, fromDate: fromDate, toDate: toDate));
  }

  late final _$performCrossCollectionSearchAsyncAction = AsyncAction(
      'MessageStoreBase.performCrossCollectionSearch',
      context: context);

  @override
  Future<void> performCrossCollectionSearch(String query) {
    return _$performCrossCollectionSearchAsyncAction
        .run(() => super.performCrossCollectionSearch(query));
  }

  late final _$searchMessagesAsyncAction =
      AsyncAction('MessageStoreBase.searchMessages', context: context);

  @override
  Future<void> searchMessages(String query) {
    return _$searchMessagesAsyncAction.run(() => super.searchMessages(query));
  }

  late final _$MessageStoreBaseActionController =
      ActionController(name: 'MessageStoreBase', context: context);

  @override
  void navigateSearch(int direction) {
    final _$actionInfo = _$MessageStoreBaseActionController.startAction(
        name: 'MessageStoreBase.navigateSearch');
    try {
      return super.navigateSearch(direction);
    } finally {
      _$MessageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSearch() {
    final _$actionInfo = _$MessageStoreBaseActionController.startAction(
        name: 'MessageStoreBase.clearSearch');
    try {
      return super.clearSearch();
    } finally {
      _$MessageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void exitCrossCollectionMode() {
    final _$actionInfo = _$MessageStoreBaseActionController.startAction(
        name: 'MessageStoreBase.exitCrossCollectionMode');
    try {
      return super.exitCrossCollectionMode();
    } finally {
      _$MessageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearCache([String? specificCollection]) {
    final _$actionInfo = _$MessageStoreBaseActionController.startAction(
        name: 'MessageStoreBase.clearCache');
    try {
      return super.clearCache(specificCollection);
    } finally {
      _$MessageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
messages: ${messages},
crossCollectionMessages: ${crossCollectionMessages},
allPhotos: ${allPhotos},
isLoading: ${isLoading},
isCrossCollectionLoading: ${isCrossCollectionLoading},
currentCollection: ${currentCollection},
searchResults: ${searchResults},
currentSearchIndex: ${currentSearchIndex},
isSearchActive: ${isSearchActive},
currentSearchQuery: ${currentSearchQuery},
fromDate: ${fromDate},
toDate: ${toDate},
isCrossCollectionSearch: ${isCrossCollectionSearch},
sortedMessages: ${sortedMessages}
    ''';
  }
}
