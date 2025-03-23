// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NavigationStore on NavigationStoreBase, Store {
  late final _$isNavigatingAtom =
      Atom(name: 'NavigationStoreBase.isNavigating', context: context);

  @override
  bool get isNavigating {
    _$isNavigatingAtom.reportRead();
    return super.isNavigating;
  }

  @override
  set isNavigating(bool value) {
    _$isNavigatingAtom.reportWrite(value, super.isNavigating, () {
      super.isNavigating = value;
    });
  }

  late final _$targetCollectionAtom =
      Atom(name: 'NavigationStoreBase.targetCollection', context: context);

  @override
  String? get targetCollection {
    _$targetCollectionAtom.reportRead();
    return super.targetCollection;
  }

  @override
  set targetCollection(String? value) {
    _$targetCollectionAtom.reportWrite(value, super.targetCollection, () {
      super.targetCollection = value;
    });
  }

  late final _$targetTimestampAtom =
      Atom(name: 'NavigationStoreBase.targetTimestamp', context: context);

  @override
  int? get targetTimestamp {
    _$targetTimestampAtom.reportRead();
    return super.targetTimestamp;
  }

  @override
  set targetTimestamp(int? value) {
    _$targetTimestampAtom.reportWrite(value, super.targetTimestamp, () {
      super.targetTimestamp = value;
    });
  }

  late final _$targetMessageIndexAtom =
      Atom(name: 'NavigationStoreBase.targetMessageIndex', context: context);

  @override
  int? get targetMessageIndex {
    _$targetMessageIndexAtom.reportRead();
    return super.targetMessageIndex;
  }

  @override
  set targetMessageIndex(int? value) {
    _$targetMessageIndexAtom.reportWrite(value, super.targetMessageIndex, () {
      super.targetMessageIndex = value;
    });
  }

  late final _$navigateToMessageAsyncAction =
      AsyncAction('NavigationStoreBase.navigateToMessage', context: context);

  @override
  Future<bool> navigateToMessage(
      BuildContext context, String collectionName, int timestamp,
      {required dynamic Function(int) onScrollComplete,
      bool popCurrent = false}) {
    return _$navigateToMessageAsyncAction.run(() => super.navigateToMessage(
        context, collectionName, timestamp,
        onScrollComplete: onScrollComplete, popCurrent: popCurrent));
  }

  late final _$navigateToCollectionAsyncAction =
      AsyncAction('NavigationStoreBase.navigateToCollection', context: context);

  @override
  Future<bool> navigateToCollection(BuildContext context, String collectionName,
      {bool popCurrent = false}) {
    return _$navigateToCollectionAsyncAction.run(() => super
        .navigateToCollection(context, collectionName, popCurrent: popCurrent));
  }

  late final _$NavigationStoreBaseActionController =
      ActionController(name: 'NavigationStoreBase', context: context);

  @override
  void resetNavigation() {
    final _$actionInfo = _$NavigationStoreBaseActionController.startAction(
        name: 'NavigationStoreBase.resetNavigation');
    try {
      return super.resetNavigation();
    } finally {
      _$NavigationStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isNavigating: ${isNavigating},
targetCollection: ${targetCollection},
targetTimestamp: ${targetTimestamp},
targetMessageIndex: ${targetMessageIndex}
    ''';
  }
}
