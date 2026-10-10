// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CollectionStore on CollectionStoreBase, Store {
  late final _$collectionsAtom =
      Atom(name: 'CollectionStoreBase.collections', context: context);

  @override
  ObservableList<Map<String, dynamic>> get collections {
    _$collectionsAtom.reportRead();
    return super.collections;
  }

  @override
  set collections(ObservableList<Map<String, dynamic>> value) {
    _$collectionsAtom.reportWrite(value, super.collections, () {
      super.collections = value;
    });
  }

  late final _$filteredCollectionsAtom =
      Atom(name: 'CollectionStoreBase.filteredCollections', context: context);

  @override
  ObservableList<Map<String, dynamic>> get filteredCollections {
    _$filteredCollectionsAtom.reportRead();
    return super.filteredCollections;
  }

  @override
  set filteredCollections(ObservableList<Map<String, dynamic>> value) {
    _$filteredCollectionsAtom.reportWrite(value, super.filteredCollections, () {
      super.filteredCollections = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'CollectionStoreBase.isLoading', context: context);

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

  late final _$errorAtom =
      Atom(name: 'CollectionStoreBase.error', context: context);

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$isMessageLoadingAtom =
      Atom(name: 'CollectionStoreBase.isMessageLoading', context: context);

  @override
  bool get isMessageLoading {
    _$isMessageLoadingAtom.reportRead();
    return super.isMessageLoading;
  }

  @override
  set isMessageLoading(bool value) {
    _$isMessageLoadingAtom.reportWrite(value, super.isMessageLoading, () {
      super.isMessageLoading = value;
    });
  }

  late final _$filterQueryAtom =
      Atom(name: 'CollectionStoreBase.filterQuery', context: context);

  @override
  String get filterQuery {
    _$filterQueryAtom.reportRead();
    return super.filterQuery;
  }

  @override
  set filterQuery(String value) {
    _$filterQueryAtom.reportWrite(value, super.filterQuery, () {
      super.filterQuery = value;
    });
  }

  late final _$loadCollectionsAsyncAction =
      AsyncAction('CollectionStoreBase.loadCollections', context: context);

  @override
  Future<void> loadCollections() {
    return _$loadCollectionsAsyncAction.run(() => super.loadCollections());
  }

  late final _$refreshCollectionsAsyncAction =
      AsyncAction('CollectionStoreBase.refreshCollections', context: context);

  @override
  Future<void> refreshCollections() {
    return _$refreshCollectionsAsyncAction
        .run(() => super.refreshCollections());
  }

  late final _$refreshCollectionsIfNeededAsyncAction = AsyncAction(
      'CollectionStoreBase.refreshCollectionsIfNeeded',
      context: context);

  @override
  Future<void> refreshCollectionsIfNeeded() {
    return _$refreshCollectionsIfNeededAsyncAction
        .run(() => super.refreshCollectionsIfNeeded());
  }

  late final _$CollectionStoreBaseActionController =
      ActionController(name: 'CollectionStoreBase', context: context);

  @override
  void setMessageLoading(bool loading) {
    final _$actionInfo = _$CollectionStoreBaseActionController.startAction(
        name: 'CollectionStoreBase.setMessageLoading');
    try {
      return super.setMessageLoading(loading);
    } finally {
      _$CollectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFilterQuery(String query) {
    final _$actionInfo = _$CollectionStoreBaseActionController.startAction(
        name: 'CollectionStoreBase.setFilterQuery');
    try {
      return super.setFilterQuery(query);
    } finally {
      _$CollectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearFilter() {
    final _$actionInfo = _$CollectionStoreBaseActionController.startAction(
        name: 'CollectionStoreBase.clearFilter');
    try {
      return super.clearFilter();
    } finally {
      _$CollectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setCollections(List<Map<String, dynamic>> list) {
    final _$actionInfo = _$CollectionStoreBaseActionController.startAction(
        name: 'CollectionStoreBase._setCollections');
    try {
      return super._setCollections(list);
    } finally {
      _$CollectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
collections: ${collections},
filteredCollections: ${filteredCollections},
isLoading: ${isLoading},
error: ${error},
isMessageLoading: ${isMessageLoading},
filterQuery: ${filterQuery}
    ''';
  }
}
