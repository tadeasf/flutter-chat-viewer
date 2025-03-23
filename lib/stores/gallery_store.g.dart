// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$GalleryStore on GalleryStoreBase, Store {
  Computed<bool>? _$hasTargetPhotoComputed;

  @override
  bool get hasTargetPhoto =>
      (_$hasTargetPhotoComputed ??= Computed<bool>(() => super.hasTargetPhoto,
              name: 'GalleryStoreBase.hasTargetPhoto'))
          .value;
  Computed<Map<String, dynamic>?>? _$currentPhotoComputed;

  @override
  Map<String, dynamic>? get currentPhoto => (_$currentPhotoComputed ??=
          Computed<Map<String, dynamic>?>(() => super.currentPhoto,
              name: 'GalleryStoreBase.currentPhoto'))
      .value;

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

  late final _$currentCollectionAtom =
      Atom(name: 'GalleryStoreBase.currentCollection', context: context);

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

  late final _$currentPhotoIndexAtom =
      Atom(name: 'GalleryStoreBase.currentPhotoIndex', context: context);

  @override
  int get currentPhotoIndex {
    _$currentPhotoIndexAtom.reportRead();
    return super.currentPhotoIndex;
  }

  @override
  set currentPhotoIndex(int value) {
    _$currentPhotoIndexAtom.reportWrite(value, super.currentPhotoIndex, () {
      super.currentPhotoIndex = value;
    });
  }

  late final _$targetPhotoAtom =
      Atom(name: 'GalleryStoreBase.targetPhoto', context: context);

  @override
  Map<String, dynamic>? get targetPhoto {
    _$targetPhotoAtom.reportRead();
    return super.targetPhoto;
  }

  @override
  set targetPhoto(Map<String, dynamic>? value) {
    _$targetPhotoAtom.reportWrite(value, super.targetPhoto, () {
      super.targetPhoto = value;
    });
  }

  late final _$targetPhotoIndexAtom =
      Atom(name: 'GalleryStoreBase.targetPhotoIndex', context: context);

  @override
  int? get targetPhotoIndex {
    _$targetPhotoIndexAtom.reportRead();
    return super.targetPhotoIndex;
  }

  @override
  set targetPhotoIndex(int? value) {
    _$targetPhotoIndexAtom.reportWrite(value, super.targetPhotoIndex, () {
      super.targetPhotoIndex = value;
    });
  }

  late final _$photoAvailabilityMapAtom =
      Atom(name: 'GalleryStoreBase.photoAvailabilityMap', context: context);

  @override
  ObservableMap<String, bool> get photoAvailabilityMap {
    _$photoAvailabilityMapAtom.reportRead();
    return super.photoAvailabilityMap;
  }

  @override
  set photoAvailabilityMap(ObservableMap<String, bool> value) {
    _$photoAvailabilityMapAtom.reportWrite(value, super.photoAvailabilityMap,
        () {
      super.photoAvailabilityMap = value;
    });
  }

  late final _$setupGalleryForCollectionAsyncAction = AsyncAction(
      'GalleryStoreBase.setupGalleryForCollection',
      context: context);

  @override
  Future<void> setupGalleryForCollection(
      String collectionName, Map<String, dynamic>? targetPhoto,
      {String? sender}) {
    return _$setupGalleryForCollectionAsyncAction.run(() => super
        .setupGalleryForCollection(collectionName, targetPhoto,
            sender: sender));
  }

  late final _$loadPhotosAsyncAction =
      AsyncAction('GalleryStoreBase.loadPhotos', context: context);

  @override
  Future<void> loadPhotos(String collectionName,
      {bool clearExisting = true, String? sender}) {
    return _$loadPhotosAsyncAction.run(() => super.loadPhotos(collectionName,
        clearExisting: clearExisting, sender: sender));
  }

  late final _$loadMorePhotosAsyncAction =
      AsyncAction('GalleryStoreBase.loadMorePhotos', context: context);

  @override
  Future<void> loadMorePhotos({String? sender}) {
    return _$loadMorePhotosAsyncAction
        .run(() => super.loadMorePhotos(sender: sender));
  }

  late final _$checkPhotoAvailabilityAsyncAction =
      AsyncAction('GalleryStoreBase.checkPhotoAvailability', context: context);

  @override
  Future<bool> checkPhotoAvailability(String collectionName) {
    return _$checkPhotoAvailabilityAsyncAction
        .run(() => super.checkPhotoAvailability(collectionName));
  }

  late final _$uploadPhotoAsyncAction =
      AsyncAction('GalleryStoreBase.uploadPhoto', context: context);

  @override
  Future<bool> uploadPhoto(BuildContext context, String collectionName) {
    return _$uploadPhotoAsyncAction
        .run(() => super.uploadPhoto(context, collectionName));
  }

  late final _$deletePhotoAsyncAction =
      AsyncAction('GalleryStoreBase.deletePhoto', context: context);

  @override
  Future<Map<String, dynamic>> deletePhoto(String collectionName) {
    return _$deletePhotoAsyncAction
        .run(() => super.deletePhoto(collectionName));
  }

  late final _$GalleryStoreBaseActionController =
      ActionController(name: 'GalleryStoreBase', context: context);

  @override
  void setTargetPhoto(Map<String, dynamic> photo) {
    final _$actionInfo = _$GalleryStoreBaseActionController.startAction(
        name: 'GalleryStoreBase.setTargetPhoto');
    try {
      return super.setTargetPhoto(photo);
    } finally {
      _$GalleryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCurrentPhotoIndex(int index) {
    final _$actionInfo = _$GalleryStoreBaseActionController.startAction(
        name: 'GalleryStoreBase.setCurrentPhotoIndex');
    try {
      return super.setCurrentPhotoIndex(index);
    } finally {
      _$GalleryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void nextPhoto() {
    final _$actionInfo = _$GalleryStoreBaseActionController.startAction(
        name: 'GalleryStoreBase.nextPhoto');
    try {
      return super.nextPhoto();
    } finally {
      _$GalleryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void previousPhoto() {
    final _$actionInfo = _$GalleryStoreBaseActionController.startAction(
        name: 'GalleryStoreBase.previousPhoto');
    try {
      return super.previousPhoto();
    } finally {
      _$GalleryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
photos: ${photos},
isLoading: ${isLoading},
currentCollection: ${currentCollection},
currentPhotoIndex: ${currentPhotoIndex},
targetPhoto: ${targetPhoto},
targetPhotoIndex: ${targetPhotoIndex},
photoAvailabilityMap: ${photoAvailabilityMap},
hasTargetPhoto: ${hasTargetPhoto},
currentPhoto: ${currentPhoto}
    ''';
  }
}
