import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobx/mobx.dart';

import '../utils/api_db/api_service.dart';

part 'gallery_store.g.dart';

class GalleryStore = GalleryStoreBase with _$GalleryStore;

/// Photos of one conversation (sent by the other person), oldest first.
abstract class GalleryStoreBase with Store {
  /// One entry per photo: the photo object (`uri`, `creation_timestamp`)
  /// plus `message_timestamp` of the message it belongs to.
  @observable
  ObservableList<Map<String, dynamic>> photos =
      ObservableList<Map<String, dynamic>>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  int currentPhotoIndex = 0;

  @observable
  Map<String, dynamic>? targetPhoto;

  @observable
  int? targetPhotoIndex;

  @computed
  bool get hasTargetPhoto => targetPhoto != null;

  @action
  Future<void> setupGalleryForCollection(
      String collectionName, Map<String, dynamic>? target) async {
    targetPhoto = target;
    targetPhotoIndex = null;
    photos.clear();
    isLoading = true;
    error = null;
    try {
      final messages = await ApiService.fetchPhotos(collectionName);
      photos.addAll([
        for (final m in messages)
          for (final p in (m['photos'] as List? ?? const []))
            {
              ...(p as Map<String, dynamic>),
              'message_timestamp': m['timestamp_ms'],
            }
      ]..sort((a, b) => (a['message_timestamp'] as int? ?? 0)
          .compareTo(b['message_timestamp'] as int? ?? 0)));
      final uri = target?['uri'];
      if (uri != null) {
        final index = photos.indexWhere((p) => p['uri'] == uri);
        if (index >= 0) targetPhotoIndex = index;
      }
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
    }
  }

  @action
  void setTargetPhoto(Map<String, dynamic> photo) {
    targetPhoto = photo;
    targetPhotoIndex = null;
  }

  @action
  void setCurrentPhotoIndex(int index) {
    if (index >= 0 && index < photos.length) currentPhotoIndex = index;
  }

  Map<String, dynamic> getPhotoAt(int index) => photos[index];

  List<Map<String, dynamic>> getPhotosForGallery() => photos.toList();

  // Built from `uri`: the server's `fullUri` is derived from the request Host
  // header, is cached per conversation and can point at an internal address.
  String getPhotoUrl(Map<String, dynamic> photo) =>
      ApiService.mediaUrl(photo['uri'] as String);

  /// Picks an image and uploads it as the profile photo. Returns false if
  /// nothing was picked; throws [ApiException] if the server rejects it.
  @action
  Future<bool> uploadPhoto(BuildContext context, String collectionName) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return false;

    isLoading = true;
    try {
      await ApiService.uploadPhoto(
          collectionName, await pickedFile.readAsBytes());
      return true;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<Map<String, dynamic>> deletePhoto(String collectionName) async {
    isLoading = true;
    try {
      final message = await ApiService.deletePhoto(collectionName);
      return {'success': true, 'message': message};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    } finally {
      isLoading = false;
    }
  }
}
