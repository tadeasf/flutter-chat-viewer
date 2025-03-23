// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MessageStore on MessageStoreBase, Store {
  Computed<bool>? _$needsMessageRefreshComputed;

  @override
  bool get needsMessageRefresh => (_$needsMessageRefreshComputed ??=
          Computed<bool>(() => super.needsMessageRefresh,
              name: 'MessageStoreBase.needsMessageRefresh'))
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

  late final _$searchMessagesAsyncAction =
      AsyncAction('MessageStoreBase.searchMessages', context: context);

  @override
  Future<void> searchMessages(String query, {bool isCrossCollection = false}) {
    return _$searchMessagesAsyncAction.run(() =>
        super.searchMessages(query, isCrossCollection: isCrossCollection));
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
currentCollection: ${currentCollection},
lastMessageFetch: ${lastMessageFetch},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
searchResults: ${searchResults},
isSearchActive: ${isSearchActive},
searchQuery: ${searchQuery},
needsMessageRefresh: ${needsMessageRefresh}
    ''';
  }
}
