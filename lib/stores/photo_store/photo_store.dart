import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import '../../utils/photo_handler.dart';
import '../../utils/api_db/api_service.dart';

// Include the generated file
part 'photo_store.g.dart';

// This is the class used by rest of the codebase
class PhotoStore = PhotoStoreBase with _$PhotoStore;

// The store class
abstract class PhotoStoreBase with Store {
  final Logger _logger = Logger('PhotoStore');
  // Check if photos are available for a collection
  Future<bool> checkPhotoAvailability(String? collectionName) async {
    if (collectionName == null) return false;

    try {
      return await ApiService.profilePhotoExists(collectionName);
    } catch (e) {
      _logger.warning('Error checking photo availability: $e');
      return false;
    }
  }

  // Show all photos in gallery
  void showAllPhotos(BuildContext context, String? collectionName) {
    PhotoHandler.handleShowAllPhotos(context, collectionName);
  }

  // Set state callback for photo availability
  Future<void> updatePhotoAvailability(
      String? collectionName, Function(bool) updateState) async {
    if (collectionName == null) return;

    final isAvailable = await checkPhotoAvailability(collectionName);
    updateState(isAvailable);
  }
}
