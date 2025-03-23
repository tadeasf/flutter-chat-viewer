import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/api_db/api_service.dart';
import '../utils/api_db/url_formatter.dart';

// Include the generated file
part 'gallery_store.g.dart';

// This is the class used by rest of the codebase
class GalleryStore = GalleryStoreBase with _$GalleryStore;

// The store class
abstract class GalleryStoreBase with Store {
  final Logger _logger = Logger('GalleryStore');

  // Observable fields for gallery state
  @observable
  ObservableList<Map<String, dynamic>> photos =
      ObservableList<Map<String, dynamic>>();

  @observable
  bool isLoading = false;

  @observable
  String? currentCollection;

  @observable
  int currentPhotoIndex = 0;

  @observable
  Map<String, dynamic>? targetPhoto;

  @observable
  int? targetPhotoIndex;

  @observable
  ObservableMap<String, bool> photoAvailabilityMap =
      ObservableMap<String, bool>();

  // Computed property to check if there is a target photo
  @computed
  bool get hasTargetPhoto => targetPhoto != null;

  // Action to set up the gallery for a specific collection and target photo
  @action
  Future<void> setupGalleryForCollection(
      String collectionName, Map<String, dynamic>? targetPhoto,
      {String? sender}) async {
    // Set target photo first
    this.targetPhoto = targetPhoto;
    targetPhotoIndex = null;

    // Then load photos
    await loadPhotos(collectionName, sender: sender);

    // Find target photo index if needed
    if (targetPhoto != null && photos.isNotEmpty) {
      _findTargetPhotoIndex();
    }
  }

  // Internal method to find the index of the target photo
  void _findTargetPhotoIndex() {
    if (targetPhoto == null) return;

    final targetUri = targetPhoto!['uri'] as String?;
    if (targetUri == null) return;

    final index =
        photos.indexWhere((photo) => photo['photos'][0]['uri'] == targetUri);

    if (index != -1) {
      targetPhotoIndex = index;
    }
  }

  // Action to set the target photo
  @action
  void setTargetPhoto(Map<String, dynamic> photo) {
    targetPhoto = photo;
    targetPhotoIndex = null;
  }

  // Action to load photos for a collection
  @action
  Future<void> loadPhotos(String collectionName,
      {bool clearExisting = true, String? sender}) async {
    if (isLoading) return;

    if (clearExisting) {
      photos.clear();
      currentCollection = collectionName;
    }

    isLoading = true;
    _logger.info(
        'Loading photos for collection: $collectionName, sender: $sender');

    try {
      final loadedPhotos =
          await ApiService.fetchPhotos(collectionName, senderName: sender);
      photos.addAll(loadedPhotos);
      _logger.info('Loaded ${loadedPhotos.length} photos for $collectionName');

      // After loading photos, try to find the target photo index
      if (targetPhoto != null) {
        _findTargetPhotoIndex();
      }

      isLoading = false;
    } catch (e) {
      _logger.severe('Error loading photos: $e');
      isLoading = false;
    }
  }

  // Action to load more photos (pagination)
  @action
  Future<void> loadMorePhotos({String? sender}) async {
    if (isLoading || currentCollection == null) return;

    await loadPhotos(currentCollection!, clearExisting: false, sender: sender);
  }

  // Action to check photo availability for a collection
  @action
  Future<bool> checkPhotoAvailability(String collectionName) async {
    if (photoAvailabilityMap.containsKey(collectionName)) {
      return photoAvailabilityMap[collectionName] ?? false;
    }

    try {
      final response = await ApiService.get(
        '/collection/has-photo/${Uri.encodeComponent(collectionName)}',
        headers: {'x-api-key': ApiService.apiKey},
      );
      final result = json.decode(response.body);
      final availability = result['hasPhoto'] ?? false;

      photoAvailabilityMap[collectionName] = availability;
      return availability;
    } catch (e) {
      _logger.warning('Error checking photo availability: $e');
      photoAvailabilityMap[collectionName] = false;
      return false;
    }
  }

  // Action to set current photo index
  @action
  void setCurrentPhotoIndex(int index) {
    if (index >= 0 && index < photos.length) {
      currentPhotoIndex = index;
    }
  }

  // Action to navigate to next photo
  @action
  void nextPhoto() {
    if (currentPhotoIndex < photos.length - 1) {
      currentPhotoIndex++;
    }
  }

  // Action to navigate to previous photo
  @action
  void previousPhoto() {
    if (currentPhotoIndex > 0) {
      currentPhotoIndex--;
    }
  }

  // Computed property for current photo
  @computed
  Map<String, dynamic>? get currentPhoto {
    if (photos.isEmpty || currentPhotoIndex >= photos.length) {
      return null;
    }
    return photos[currentPhotoIndex];
  }

  // Method to get a photo at a specific index
  Map<String, dynamic> getPhotoAt(int index) {
    if (index < 0 || index >= photos.length) {
      throw Exception('Photo index out of bounds: $index');
    }

    // The server returns each photo message with a 'photos' array containing the photo objects
    // Photos returned from the /photos endpoint have a specific structure we need to handle
    final photoData = photos[index];

    if (photoData.containsKey('photos') &&
        photoData['photos'] is List &&
        photoData['photos'].isNotEmpty) {
      return photoData['photos'][0]; // Return the first photo in the array
    } else {
      // If for some reason the structure is different, return the entire photo data
      _logger.warning('Unexpected photo data structure: $photoData');
      return photoData;
    }
  }

  // Method to get processed photos for gallery view
  List<Map<String, dynamic>> getPhotosForGallery() {
    try {
      return photos.map((photo) {
        if (photo.containsKey('photos') &&
            photo['photos'] is List &&
            photo['photos'].isNotEmpty) {
          // Create a copy of the photo data
          Map<String, dynamic> photoData =
              Map<String, dynamic>.from(photo['photos'][0]);

          // Ensure creation_timestamp is included from the parent message if needed
          if (!photoData.containsKey('creation_timestamp') &&
              photo.containsKey('timestamp_ms')) {
            photoData['creation_timestamp'] = photo['timestamp_ms'];
          }

          // Include the message timestamp for reference
          if (photo.containsKey('timestamp_ms')) {
            photoData['message_timestamp'] = photo['timestamp_ms'];
          }

          return photoData;
        } else {
          _logger.warning('Unexpected photo data structure: $photo');
          return Map<String, dynamic>.from(photo);
        }
      }).toList();
    } catch (e) {
      _logger.severe('Error getting photos for gallery: $e');
      return [];
    }
  }

  // Get photo URL
  String getPhotoUrl(Map<String, dynamic> photo, String defaultCollectionName) {
    if (photo['fullUri'] != null) return photo['fullUri'] as String;

    final uri = photo['uri'] as String;
    String collectionName = defaultCollectionName;

    // Extract collection name from path if available
    if (uri.startsWith('messages/inbox/')) {
      collectionName = uri.split('/')[2];
    }

    final filename = uri.split('/').last;
    return UrlFormatter.formatUrl(
      uri: filename,
      type: MediaType.photo,
      collectionName: collectionName,
      source: MediaSource.message,
    );
  }

  // Get filename from photo
  String getFilename(Map<String, dynamic> photo) {
    final uri = photo['uri'] as String;
    return uri.split('/').last;
  }

  // Upload photo
  @action
  Future<bool> uploadPhoto(BuildContext context, String collectionName) async {
    isLoading = true;

    try {
      // Get image from gallery
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        isLoading = false;
        return false;
      }

      // Read image data
      List<int> imageBytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Create request data
      final photoData = {
        'photo': base64Image,
      };

      // Make API call
      await ApiService.post(
        '/upload/photo/${Uri.encodeComponent(collectionName)}',
        body: photoData,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiService.apiKey,
        },
      );

      // Clear photo availability cache
      photoAvailabilityMap.remove(collectionName);

      isLoading = false;
      return true;
    } catch (e) {
      _logger.warning('Error uploading photo: $e');
      isLoading = false;
      return false;
    }
  }

  // Delete photo
  @action
  Future<Map<String, dynamic>> deletePhoto(String collectionName) async {
    isLoading = true;

    try {
      final result = await ApiService.deletePhoto(collectionName);

      // Clear photo availability cache
      photoAvailabilityMap.remove(collectionName);

      isLoading = false;
      return result;
    } catch (e) {
      _logger.warning('Error deleting photo: $e');
      isLoading = false;
      return {
        'success': false,
        'message': 'Error deleting photo: ${e.toString()}',
      };
    }
  }

  // Get web download URL for direct browser downloads
  String getWebDownloadUrl(String collectionName, String filename) {
    return ApiService.getWebDownloadUrl(collectionName, filename);
  }
}
