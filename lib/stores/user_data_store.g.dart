// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$UserDataStore on UserDataStoreBase, Store {
  late final _$togglePinAsyncAction =
      AsyncAction('UserDataStoreBase.togglePin', context: context);

  @override
  Future<void> togglePin(String collection) {
    return _$togglePinAsyncAction.run(() => super.togglePin(collection));
  }

  late final _$toggleBookmarkAsyncAction =
      AsyncAction('UserDataStoreBase.toggleBookmark', context: context);

  @override
  Future<void> toggleBookmark(String collection, Map<String, dynamic> message) {
    return _$toggleBookmarkAsyncAction
        .run(() => super.toggleBookmark(collection, message));
  }

  late final _$UserDataStoreBaseActionController =
      ActionController(name: 'UserDataStoreBase', context: context);

  @override
  void setPosition(String collection, int? timestamp) {
    final _$actionInfo = _$UserDataStoreBaseActionController.startAction(
        name: 'UserDataStoreBase.setPosition');
    try {
      return super.setPosition(collection, timestamp);
    } finally {
      _$UserDataStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''

    ''';
  }
}
