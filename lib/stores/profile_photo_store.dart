import 'package:mobx/mobx.dart';

import '../utils/api_db/api_service.dart';

part 'profile_photo_store.g.dart';

class ProfilePhotoStore = ProfilePhotoStoreBase with _$ProfilePhotoStore;

/// Profile photo URLs per conversation (null when there is no photo).
abstract class ProfilePhotoStoreBase with Store {
  @observable
  ObservableMap<String, String?> profilePhotoUrls =
      ObservableMap<String, String?>();

  /// Bumped when a photo is uploaded or deleted. It is part of the URL, so
  /// image caches never show the previous photo.
  final Map<String, int> _versions = {};

  @action
  Future<String?> getProfilePhotoUrl(String collectionName) async {
    if (profilePhotoUrls.containsKey(collectionName)) {
      return profilePhotoUrls[collectionName];
    }
    final exists = await ApiService.profilePhotoExists(collectionName);
    final version = _versions[collectionName] ?? 0;
    final base = ApiService.profilePhotoUrl(collectionName);
    final url = exists ? (version == 0 ? base : '$base?v=$version') : null;
    profilePhotoUrls[collectionName] = url;
    return url;
  }

  /// Call after an upload or delete; the next lookup asks the server again.
  @action
  void photoChanged(String collectionName) {
    _versions[collectionName] = (_versions[collectionName] ?? 0) + 1;
    profilePhotoUrls.remove(collectionName);
  }
}
