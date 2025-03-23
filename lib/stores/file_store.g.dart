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

  late final _$isLoadingAtom =
      Atom(name: 'FileStoreBase.isLoading', context: context);

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

  late final _$cacheAtom = Atom(name: 'FileStoreBase.cache', context: context);

  @override
  ObservableMap<String, dynamic> get cache {
    _$cacheAtom.reportRead();
    return super.cache;
  }

  @override
  set cache(ObservableMap<String, dynamic> value) {
    _$cacheAtom.reportWrite(value, super.cache, () {
      super.cache = value;
    });
  }

  late final _$getFileAsyncAction =
      AsyncAction('FileStoreBase.getFile', context: context);

  @override
  Future<String?> getFile(String uri, MediaType type,
      {String? collectionName,
      url_formatter.MediaSource source = url_formatter.MediaSource.message}) {
    return _$getFileAsyncAction.run(() => super
        .getFile(uri, type, collectionName: collectionName, source: source));
  }

  late final _$downloadMediaFromMessageAsyncAction =
      AsyncAction('FileStoreBase.downloadMediaFromMessage', context: context);

  @override
  Future<bool> downloadMediaFromMessage(BuildContext context,
      Map<String, dynamic> message, String mediaUri, MediaType type) {
    return _$downloadMediaFromMessageAsyncAction.run(
        () => super.downloadMediaFromMessage(context, message, mediaUri, type));
  }

  late final _$downloadPhotoAsyncAction =
      AsyncAction('FileStoreBase.downloadPhoto', context: context);

  @override
  Future<bool> downloadPhoto(
      BuildContext context, Map<String, dynamic> photo, String collectionName) {
    return _$downloadPhotoAsyncAction
        .run(() => super.downloadPhoto(context, photo, collectionName));
  }

  late final _$downloadFileAsyncAction =
      AsyncAction('FileStoreBase.downloadFile', context: context);

  @override
  Future<bool> downloadFile(BuildContext context, String url, MediaType type) {
    return _$downloadFileAsyncAction
        .run(() => super.downloadFile(context, url, type));
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
errorStates: ${errorStates},
isLoading: ${isLoading},
cache: ${cache}
    ''';
  }
}
