import 'package:mobx/mobx.dart';
import 'file_store.dart';
import '../utils/api_db/api_service.dart';
// Include the generated file
part 'profile_photo_store.g.dart';

// This is the class used by rest of the codebase
class ProfilePhotoStore = ProfilePhotoStoreBase with _$ProfilePhotoStore;

// The store class
abstract class ProfilePhotoStoreBase with Store {
  final FileStore fileStore;

  ProfilePhotoStoreBase({
    required this.fileStore,
  });

  // Observable map to store URLs by collection name
  @observable
  ObservableMap<String, String?> profilePhotoUrls =
      ObservableMap<String, String?>();

  // Observable for loading states
  @observable
  ObservableMap<String, bool> loadingStates = ObservableMap<String, bool>();

  // Observable for error states
  @observable
  ObservableMap<String, bool> errorStates = ObservableMap<String, bool>();

  // Action to fetch profile photo
  @action
  Future<String?> getProfilePhotoUrl(String collectionName) async {
    // Check if we have the URL cached
    if (profilePhotoUrls.containsKey(collectionName)) {
      return profilePhotoUrls[collectionName];
    }

    loadingStates[collectionName] = true;
    final exists = await ApiService.profilePhotoExists(collectionName);
    loadingStates[collectionName] = false;
    errorStates[collectionName] = !exists;
    if (!exists) return null;

    final url = ApiService.profilePhotoUrl(collectionName);
    profilePhotoUrls[collectionName] = url;
    return url;
  }

  // Action to clear cache for a specific collection
  @action
  void clearCache(String collectionName) {
    profilePhotoUrls.remove(collectionName);
    loadingStates.remove(collectionName);
    errorStates.remove(collectionName);
  }

  // Action to clear all cache
  @action
  void clearAllCache() {
    profilePhotoUrls.clear();
    loadingStates.clear();
    errorStates.clear();
  }

  // Helper to get loading state
  bool isLoading(String collectionName) {
    return loadingStates[collectionName] ?? false;
  }

  // Helper to get error state
  bool hasError(String collectionName) {
    return errorStates[collectionName] ?? false;
  }
}
