// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_photo_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProfilePhotoStore on ProfilePhotoStoreBase, Store {
  late final _$profilePhotoUrlsAtom =
      Atom(name: 'ProfilePhotoStoreBase.profilePhotoUrls', context: context);

  @override
  ObservableMap<String, String?> get profilePhotoUrls {
    _$profilePhotoUrlsAtom.reportRead();
    return super.profilePhotoUrls;
  }

  @override
  set profilePhotoUrls(ObservableMap<String, String?> value) {
    _$profilePhotoUrlsAtom.reportWrite(value, super.profilePhotoUrls, () {
      super.profilePhotoUrls = value;
    });
  }

  late final _$getProfilePhotoUrlAsyncAction =
      AsyncAction('ProfilePhotoStoreBase.getProfilePhotoUrl', context: context);

  @override
  Future<String?> getProfilePhotoUrl(String collectionName) {
    return _$getProfilePhotoUrlAsyncAction
        .run(() => super.getProfilePhotoUrl(collectionName));
  }

  late final _$ProfilePhotoStoreBaseActionController =
      ActionController(name: 'ProfilePhotoStoreBase', context: context);

  @override
  void photoChanged(String collectionName) {
    final _$actionInfo = _$ProfilePhotoStoreBaseActionController.startAction(
        name: 'ProfilePhotoStoreBase.photoChanged');
    try {
      return super.photoChanged(collectionName);
    } finally {
      _$ProfilePhotoStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
profilePhotoUrls: ${profilePhotoUrls}
    ''';
  }
}
