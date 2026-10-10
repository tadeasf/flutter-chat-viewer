// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MessageStore on MessageStoreBase, Store {
  Computed<bool>? _$hasOlderComputed;

  @override
  bool get hasOlder =>
      (_$hasOlderComputed ??= Computed<bool>(() => super.hasOlder,
              name: 'MessageStoreBase.hasOlder'))
          .value;
  Computed<bool>? _$hasNewerComputed;

  @override
  bool get hasNewer =>
      (_$hasNewerComputed ??= Computed<bool>(() => super.hasNewer,
              name: 'MessageStoreBase.hasNewer'))
          .value;

  late final _$collectionAtom =
      Atom(name: 'MessageStoreBase.collection', context: context);

  @override
  String? get collection {
    _$collectionAtom.reportRead();
    return super.collection;
  }

  @override
  set collection(String? value) {
    _$collectionAtom.reportWrite(value, super.collection, () {
      super.collection = value;
    });
  }

  late final _$totalAtom =
      Atom(name: 'MessageStoreBase.total', context: context);

  @override
  int get total {
    _$totalAtom.reportRead();
    return super.total;
  }

  @override
  set total(int value) {
    _$totalAtom.reportWrite(value, super.total, () {
      super.total = value;
    });
  }

  late final _$startAtom =
      Atom(name: 'MessageStoreBase.start', context: context);

  @override
  int get start {
    _$startAtom.reportRead();
    return super.start;
  }

  @override
  set start(int value) {
    _$startAtom.reportWrite(value, super.start, () {
      super.start = value;
    });
  }

  late final _$anchorAtom =
      Atom(name: 'MessageStoreBase.anchor', context: context);

  @override
  int get anchor {
    _$anchorAtom.reportRead();
    return super.anchor;
  }

  @override
  set anchor(int value) {
    _$anchorAtom.reportWrite(value, super.anchor, () {
      super.anchor = value;
    });
  }

  late final _$anchoredAtBottomAtom =
      Atom(name: 'MessageStoreBase.anchoredAtBottom', context: context);

  @override
  bool get anchoredAtBottom {
    _$anchoredAtBottomAtom.reportRead();
    return super.anchoredAtBottom;
  }

  @override
  set anchoredAtBottom(bool value) {
    _$anchoredAtBottomAtom.reportWrite(value, super.anchoredAtBottom, () {
      super.anchoredAtBottom = value;
    });
  }

  late final _$generationAtom =
      Atom(name: 'MessageStoreBase.generation', context: context);

  @override
  int get generation {
    _$generationAtom.reportRead();
    return super.generation;
  }

  @override
  set generation(int value) {
    _$generationAtom.reportWrite(value, super.generation, () {
      super.generation = value;
    });
  }

  late final _$highlightIdAtom =
      Atom(name: 'MessageStoreBase.highlightId', context: context);

  @override
  String? get highlightId {
    _$highlightIdAtom.reportRead();
    return super.highlightId;
  }

  @override
  set highlightId(String? value) {
    _$highlightIdAtom.reportWrite(value, super.highlightId, () {
      super.highlightId = value;
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

  late final _$errorAtom =
      Atom(name: 'MessageStoreBase.error', context: context);

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

  late final _$openAsyncAction =
      AsyncAction('MessageStoreBase.open', context: context);

  @override
  Future<void> open(String name) {
    return _$openAsyncAction.run(() => super.open(name));
  }

  late final _$jumpToLatestAsyncAction =
      AsyncAction('MessageStoreBase.jumpToLatest', context: context);

  @override
  Future<void> jumpToLatest() {
    return _$jumpToLatestAsyncAction.run(() => super.jumpToLatest());
  }

  late final _$jumpToAsyncAction =
      AsyncAction('MessageStoreBase.jumpTo', context: context);

  @override
  Future<void> jumpTo(int timestamp, {String? id}) {
    return _$jumpToAsyncAction.run(() => super.jumpTo(timestamp, id: id));
  }

  late final _$loadOlderAsyncAction =
      AsyncAction('MessageStoreBase.loadOlder', context: context);

  @override
  Future<void> loadOlder() {
    return _$loadOlderAsyncAction.run(() => super.loadOlder());
  }

  late final _$loadNewerAsyncAction =
      AsyncAction('MessageStoreBase.loadNewer', context: context);

  @override
  Future<void> loadNewer() {
    return _$loadNewerAsyncAction.run(() => super.loadNewer());
  }

  late final _$_replaceWindowAsyncAction =
      AsyncAction('MessageStoreBase._replaceWindow', context: context);

  @override
  Future<void> _replaceWindow(
      Future<(int, List<Map<String, dynamic>>, int, String?)> Function() load) {
    return _$_replaceWindowAsyncAction.run(() => super._replaceWindow(load));
  }

  late final _$MessageStoreBaseActionController =
      ActionController(name: 'MessageStoreBase', context: context);

  @override
  void _prepend(List<Map<String, dynamic>> page, int newStart) {
    final _$actionInfo = _$MessageStoreBaseActionController.startAction(
        name: 'MessageStoreBase._prepend');
    try {
      return super._prepend(page, newStart);
    } finally {
      _$MessageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _append(List<Map<String, dynamic>> page) {
    final _$actionInfo = _$MessageStoreBaseActionController.startAction(
        name: 'MessageStoreBase._append');
    try {
      return super._append(page);
    } finally {
      _$MessageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
collection: ${collection},
total: ${total},
start: ${start},
anchor: ${anchor},
anchoredAtBottom: ${anchoredAtBottom},
generation: ${generation},
highlightId: ${highlightId},
isLoading: ${isLoading},
error: ${error},
hasOlder: ${hasOlder},
hasNewer: ${hasNewer}
    ''';
  }
}
