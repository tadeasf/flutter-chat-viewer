// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MessageStore on MessageStoreBase, Store {
  Computed<bool>? _$hasDateFilterComputed;

  @override
  bool get hasDateFilter =>
      (_$hasDateFilterComputed ??= Computed<bool>(() => super.hasDateFilter,
              name: 'MessageStoreBase.hasDateFilter'))
          .value;

  late final _$messagesAtom =
      Atom(name: 'MessageStoreBase.messages', context: context);

  @override
  ObservableList<Map<String, dynamic>> get messages {
    _$messagesAtom.reportRead();
    return super.messages;
  }

  @override
  set messages(ObservableList<Map<String, dynamic>> value) {
    _$messagesAtom.reportWrite(value, super.messages, () {
      super.messages = value;
    });
  }

  late final _$filteredMessagesAtom =
      Atom(name: 'MessageStoreBase.filteredMessages', context: context);

  @override
  ObservableList<Map<String, dynamic>> get filteredMessages {
    _$filteredMessagesAtom.reportRead();
    return super.filteredMessages;
  }

  @override
  set filteredMessages(ObservableList<Map<String, dynamic>> value) {
    _$filteredMessagesAtom.reportWrite(value, super.filteredMessages, () {
      super.filteredMessages = value;
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

  late final _$lastMessageFetchAtom =
      Atom(name: 'MessageStoreBase.lastMessageFetch', context: context);

  @override
  DateTime get lastMessageFetch {
    _$lastMessageFetchAtom.reportRead();
    return super.lastMessageFetch;
  }

  @override
  set lastMessageFetch(DateTime value) {
    _$lastMessageFetchAtom.reportWrite(value, super.lastMessageFetch, () {
      super.lastMessageFetch = value;
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

  late final _$errorMessageAtom =
      Atom(name: 'MessageStoreBase.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
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

  late final _$searchResultsAtom =
      Atom(name: 'MessageStoreBase.searchResults', context: context);

  @override
  ObservableList<Map<String, dynamic>> get searchResults {
    _$searchResultsAtom.reportRead();
    return super.searchResults;
  }

  @override
  set searchResults(ObservableList<Map<String, dynamic>> value) {
    _$searchResultsAtom.reportWrite(value, super.searchResults, () {
      super.searchResults = value;
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

  late final _$searchQueryAtom =
      Atom(name: 'MessageStoreBase.searchQuery', context: context);

  @override
  String? get searchQuery {
    _$searchQueryAtom.reportRead();
    return super.searchQuery;
  }

  @override
  set searchQuery(String? value) {
    _$searchQueryAtom.reportWrite(value, super.searchQuery, () {
      super.searchQuery = value;
    });
  }

  late final _$isCrossCollectionSearchingAtom = Atom(
      name: 'MessageStoreBase.isCrossCollectionSearching', context: context);

  @override
  bool get isCrossCollectionSearching {
    _$isCrossCollectionSearchingAtom.reportRead();
    return super.isCrossCollectionSearching;
  }

  @override
  set isCrossCollectionSearching(bool value) {
    _$isCrossCollectionSearchingAtom
        .reportWrite(value, super.isCrossCollectionSearching, () {
      super.isCrossCollectionSearching = value;
    });
  }

  late final _$crossCollectionResultsAtom =
      Atom(name: 'MessageStoreBase.crossCollectionResults', context: context);

  @override
  ObservableList<Map<String, dynamic>> get crossCollectionResults {
    _$crossCollectionResultsAtom.reportRead();
    return super.crossCollectionResults;
  }

  @override
  set crossCollectionResults(ObservableList<Map<String, dynamic>> value) {
    _$crossCollectionResultsAtom
        .reportWrite(value, super.crossCollectionResults, () {
      super.crossCollectionResults = value;
    });
  }

  late final _$searchIndexAtom =
      Atom(name: 'MessageStoreBase.searchIndex', context: context);

  @override
  ObservableMap<String, Map<String, List<int>>> get searchIndex {
    _$searchIndexAtom.reportRead();
    return super.searchIndex;
  }

  @override
  set searchIndex(ObservableMap<String, Map<String, List<int>>> value) {
    _$searchIndexAtom.reportWrite(value, super.searchIndex, () {
      super.searchIndex = value;
    });
  }

  late final _$setCollectionAsyncAction =
      AsyncAction('MessageStoreBase.setCollection', context: context);

  @override
  Future<void> setCollection(String? collectionName) {
    return _$setCollectionAsyncAction
        .run(() => super.setCollection(collectionName));
  }

  late final _$refreshMessagesAsyncAction =
      AsyncAction('MessageStoreBase.refreshMessages', context: context);

  @override
  Future<void> refreshMessages() {
    return _$refreshMessagesAsyncAction.run(() => super.refreshMessages());
  }

  late final _$fetchMessagesForDateRangeAsyncAction = AsyncAction(
      'MessageStoreBase.fetchMessagesForDateRange',
      context: context);

  @override
  Future<void> fetchMessagesForDateRange(
      String collectionName, DateTime? from, DateTime? to) {
    return _$fetchMessagesForDateRangeAsyncAction
        .run(() => super.fetchMessagesForDateRange(collectionName, from, to));
  }

  late final _$searchMessagesAsyncAction =
      AsyncAction('MessageStoreBase.searchMessages', context: context);

  @override
  Future<void> searchMessages(String query, {bool isCrossCollection = false}) {
    return _$searchMessagesAsyncAction.run(() =>
        super.searchMessages(query, isCrossCollection: isCrossCollection));
  }

  late final _$searchAcrossCollectionsAsyncAction =
      AsyncAction('MessageStoreBase.searchAcrossCollections', context: context);

  @override
  Future<void> searchAcrossCollections(String query) {
    return _$searchAcrossCollectionsAsyncAction
        .run(() => super.searchAcrossCollections(query));
  }

  late final _$MessageStoreBaseActionController =
      ActionController(name: 'MessageStoreBase', context: context);

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
  String toString() {
    return '''
messages: ${messages},
filteredMessages: ${filteredMessages},
currentCollection: ${currentCollection},
lastMessageFetch: ${lastMessageFetch},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
fromDate: ${fromDate},
toDate: ${toDate},
searchResults: ${searchResults},
isSearchActive: ${isSearchActive},
searchQuery: ${searchQuery},
isCrossCollectionSearching: ${isCrossCollectionSearching},
crossCollectionResults: ${crossCollectionResults},
searchIndex: ${searchIndex},
hasDateFilter: ${hasDateFilter}
    ''';
  }
}
