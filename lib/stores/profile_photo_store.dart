import 'package:mobx/mobx.dart';
import '../utils/api_db/api_service.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;

// Include the generated file
part 'profile_photo_store.g.dart';

// This is the class used by rest of the codebase
class ProfilePhotoStore = ProfilePhotoStoreBase with _$ProfilePhotoStore;

// The store class
abstract class ProfilePhotoStoreBase with Store {
  final Logger _logger = Logger('ProfilePhotoStore');

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
    // Return from cache if available
    if (profilePhotoUrls.containsKey(collectionName)) {
      return profilePhotoUrls[collectionName];
    }

    // Set loading state
    loadingStates[collectionName] = true;
    errorStates[collectionName] = false;

    try {
      final response = await ApiService.get(
        '/messages/${Uri.encodeComponent(collectionName)}/photo',
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final jsonData = response.bodyBytes;

        // Parse the response
        final Map<String, dynamic> parsedData =
            await compute(_jsonDecodeIsolate, jsonData);

        if (parsedData['isPhotoAvailable'] == true) {
          final String url = ApiService.getProfilePhotoUrl(collectionName);

          // Update the store
          profilePhotoUrls[collectionName] = url;
          loadingStates[collectionName] = false;

          return url;
        } else {
          // No photo available
          profilePhotoUrls[collectionName] = null;
          loadingStates[collectionName] = false;
          return null;
        }
      } else {
        // Error occurred
        _logger
            .warning('Failed to fetch profile photo: ${response.statusCode}');
        errorStates[collectionName] = true;
        loadingStates[collectionName] = false;
        return null;
      }
    } catch (e) {
      _logger.warning('Error fetching profile photo URL: $e');
      errorStates[collectionName] = true;
      loadingStates[collectionName] = false;
      return null;
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
Map<String, dynamic> _jsonDecodeIsolate(List<int> bodyBytes) {
  return json.decode(utf8.decode(bodyBytes));
}
