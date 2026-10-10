// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$GalleryStore on GalleryStoreBase, Store {
  late final _$photosAtom =
      Atom(name: 'GalleryStoreBase.photos', context: context);

  @override
  ObservableList<Map<String, dynamic>> get photos {
    _$photosAtom.reportRead();
    return super.photos;
  }

  @override
  set photos(ObservableList<Map<String, dynamic>> value) {
    _$photosAtom.reportWrite(value, super.photos, () {
      super.photos = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'GalleryStoreBase.isLoading', context: context);

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
      Atom(name: 'GalleryStoreBase.error', context: context);

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

  late final _$setupGalleryForCollectionAsyncAction = AsyncAction(
      'GalleryStoreBase.setupGalleryForCollection',
      context: context);

  @override
  Future<void> setupGalleryForCollection(String collectionName) {
    return _$setupGalleryForCollectionAsyncAction
        .run(() => super.setupGalleryForCollection(collectionName));
  }

  late final _$uploadPhotoAsyncAction =
      AsyncAction('GalleryStoreBase.uploadPhoto', context: context);

  @override
  Future<bool> uploadPhoto(String collectionName) {
    return _$uploadPhotoAsyncAction
        .run(() => super.uploadPhoto(collectionName));
  }

  late final _$deletePhotoAsyncAction =
      AsyncAction('GalleryStoreBase.deletePhoto', context: context);

  @override
  Future<Map<String, dynamic>> deletePhoto(String collectionName) {
    return _$deletePhotoAsyncAction
        .run(() => super.deletePhoto(collectionName));
  }

  @override
  String toString() {
    return '''
photos: ${photos},
isLoading: ${isLoading},
error: ${error}
    ''';
  }
}
