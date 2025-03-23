// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_index_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MessageIndexStore on MessageIndexStoreBase, Store {
  late final _$sortedMessagesAtom =
      Atom(name: 'MessageIndexStoreBase.sortedMessages', context: context);

  @override
  ObservableList<MessageModel> get sortedMessages {
    _$sortedMessagesAtom.reportRead();
    return super.sortedMessages;
  }

  @override
  set sortedMessages(ObservableList<MessageModel> value) {
    _$sortedMessagesAtom.reportWrite(value, super.sortedMessages, () {
      super.sortedMessages = value;
    });
  }

  late final _$allPhotosAtom =
      Atom(name: 'MessageIndexStoreBase.allPhotos', context: context);

  @override
  ObservableList<PhotoModel> get allPhotos {
    _$allPhotosAtom.reportRead();
    return super.allPhotos;
  }

  @override
  set allPhotos(ObservableList<PhotoModel> value) {
    _$allPhotosAtom.reportWrite(value, super.allPhotos, () {
      super.allPhotos = value;
    });
  }

  late final _$timestampToIndexMapAtom =
      Atom(name: 'MessageIndexStoreBase.timestampToIndexMap', context: context);

  @override
  ObservableMap<int, int> get timestampToIndexMap {
    _$timestampToIndexMapAtom.reportRead();
    return super.timestampToIndexMap;
  }

  @override
  set timestampToIndexMap(ObservableMap<int, int> value) {
    _$timestampToIndexMapAtom.reportWrite(value, super.timestampToIndexMap, () {
      super.timestampToIndexMap = value;
    });
  }

  late final _$MessageIndexStoreBaseActionController =
      ActionController(name: 'MessageIndexStoreBase', context: context);

  @override
  void updateMessages(List<MessageModel> messages, List<PhotoModel> photos) {
    final _$actionInfo = _$MessageIndexStoreBaseActionController.startAction(
        name: 'MessageIndexStoreBase.updateMessages');
    try {
      return super.updateMessages(messages, photos);
    } finally {
      _$MessageIndexStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateMessagesFromRaw(List<dynamic> rawMessages) {
    final _$actionInfo = _$MessageIndexStoreBaseActionController.startAction(
        name: 'MessageIndexStoreBase.updateMessagesFromRaw');
    try {
      return super.updateMessagesFromRaw(rawMessages);
    } finally {
      _$MessageIndexStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
sortedMessages: ${sortedMessages},
allPhotos: ${allPhotos},
timestampToIndexMap: ${timestampToIndexMap}
    ''';
  }
}
