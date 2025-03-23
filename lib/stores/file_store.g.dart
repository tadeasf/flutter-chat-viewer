// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FileStore on FileStoreBase, Store {
  late final _$imagePathsAtom =
      Atom(name: 'FileStoreBase.imagePaths', context: context);

  @override
  ObservableMap<String, String?> get imagePaths {
    _$imagePathsAtom.reportRead();
    return super.imagePaths;
  }

  @override
  set imagePaths(ObservableMap<String, String?> value) {
    _$imagePathsAtom.reportWrite(value, super.imagePaths, () {
      super.imagePaths = value;
    });
  }

  late final _$videoPathsAtom =
      Atom(name: 'FileStoreBase.videoPaths', context: context);

  @override
  ObservableMap<String, String?> get videoPaths {
    _$videoPathsAtom.reportRead();
    return super.videoPaths;
  }

  @override
  set videoPaths(ObservableMap<String, String?> value) {
    _$videoPathsAtom.reportWrite(value, super.videoPaths, () {
      super.videoPaths = value;
    });
  }

  late final _$audioPathsAtom =
      Atom(name: 'FileStoreBase.audioPaths', context: context);

  @override
  ObservableMap<String, String?> get audioPaths {
    _$audioPathsAtom.reportRead();
    return super.audioPaths;
  }

  @override
  set audioPaths(ObservableMap<String, String?> value) {
    _$audioPathsAtom.reportWrite(value, super.audioPaths, () {
      super.audioPaths = value;
    });
  }

  late final _$loadingStatesAtom =
      Atom(name: 'FileStoreBase.loadingStates', context: context);

  @override
  ObservableMap<String, bool> get loadingStates {
    _$loadingStatesAtom.reportRead();
    return super.loadingStates;
  }

  @override
  set loadingStates(ObservableMap<String, bool> value) {
    _$loadingStatesAtom.reportWrite(value, super.loadingStates, () {
      super.loadingStates = value;
    });
  }

  late final _$errorStatesAtom =
      Atom(name: 'FileStoreBase.errorStates', context: context);

  @override
  ObservableMap<String, bool> get errorStates {
    _$errorStatesAtom.reportRead();
    return super.errorStates;
  }

  @override
  set errorStates(ObservableMap<String, bool> value) {
    _$errorStatesAtom.reportWrite(value, super.errorStates, () {
      super.errorStates = value;
    });
  }

  late final _$getFileAsyncAction =
      AsyncAction('FileStoreBase.getFile', context: context);

  @override
  Future<String?> getFile(String url, MediaType type) {
    return _$getFileAsyncAction.run(() => super.getFile(url, type));
  }

  late final _$clearCacheAsyncAction =
      AsyncAction('FileStoreBase.clearCache', context: context);

  @override
  Future<void> clearCache(String url, MediaType type) {
    return _$clearCacheAsyncAction.run(() => super.clearCache(url, type));
  }

  late final _$clearTypeCacheAsyncAction =
      AsyncAction('FileStoreBase.clearTypeCache', context: context);

  @override
  Future<void> clearTypeCache(MediaType type) {
    return _$clearTypeCacheAsyncAction.run(() => super.clearTypeCache(type));
  }

  late final _$clearAllCacheAsyncAction =
      AsyncAction('FileStoreBase.clearAllCache', context: context);

  @override
  Future<void> clearAllCache() {
    return _$clearAllCacheAsyncAction.run(() => super.clearAllCache());
  }

  late final _$prefetchFileAsyncAction =
      AsyncAction('FileStoreBase.prefetchFile', context: context);

  @override
  Future<void> prefetchFile(String url, MediaType type) {
    return _$prefetchFileAsyncAction.run(() => super.prefetchFile(url, type));
  }

  late final _$FileStoreBaseActionController =
      ActionController(name: 'FileStoreBase', context: context);

  @override
  void _setFilePath(String url, String? path, MediaType type) {
    final _$actionInfo = _$FileStoreBaseActionController.startAction(
        name: 'FileStoreBase._setFilePath');
    try {
      return super._setFilePath(url, path, type);
    } finally {
      _$FileStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
imagePaths: ${imagePaths},
videoPaths: ${videoPaths},
audioPaths: ${audioPaths},
loadingStates: ${loadingStates},
errorStates: ${errorStates}
    ''';
  }
}
