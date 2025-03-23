import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'file_store.dart';
import '../utils/api_db/api_service.dart';
import 'package:http/http.dart' as http;
// Include the generated file
part 'profile_photo_store.g.dart';

// This is the class used by rest of the codebase
class ProfilePhotoStore = ProfilePhotoStoreBase with _$ProfilePhotoStore;

// The store class
abstract class ProfilePhotoStoreBase with Store {
  final Logger _logger = Logger('ProfilePhotoStore');
  final FileStore fileStore;
  final String baseUrl = 'https://backend.jevrej.cz';

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

    try {
      final encodedName = Uri.encodeComponent(collectionName);
      final url = '$baseUrl/serve/photo/$encodedName';

      // Set loading state
      loadingStates[collectionName] = true;
      errorStates[collectionName] = false;

      // Use GET request instead of HEAD to properly fetch the photo
      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      // Reset loading state
      loadingStates[collectionName] = false;

      if (response.statusCode != 200) {
        errorStates[collectionName] = true;
        return null;
      }

      // Store in cache
      profilePhotoUrls[collectionName] = url;
      return url;
    } catch (e) {
      _logger.warning('Error getting profile photo URL: $e');
      return null;
    }
  }

  // Method to delete a profile photo
  @action
  Future<bool> deleteProfilePhoto(String collectionName) async {
    try {
      final photoUrl = await getProfilePhotoUrl(collectionName);
      if (photoUrl == null) {
        _logger.warning('No profile photo URL found for $collectionName');
        return false;
      }

      // Use the FileStore deleteMedia method
      final result = await fileStore.deleteMedia(photoUrl, MediaType.image);
      if (result) {
        profilePhotoUrls[collectionName] = null;
        return true;
      } else {
        _logger.warning('Failed to delete profile photo for $collectionName');
        return false;
      }
    } catch (e) {
      _logger.warning('Error deleting profile photo: $e');
      return false;
    }
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

// Helper function to run JSON decode in an isolate
