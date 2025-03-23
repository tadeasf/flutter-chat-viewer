import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../file_store.dart';
import '../collection_store.dart';
import '../../utils/photo_handler.dart';

// Include the generated file
part 'photo_store.g.dart';

// This is the class used by rest of the codebase
class PhotoStore = PhotoStoreBase with _$PhotoStore;

// The store class
abstract class PhotoStoreBase with Store {
  final Logger _logger = Logger('PhotoStore');
  final FileStore fileStore;
  final CollectionStore collectionStore;

  PhotoStoreBase({
    required this.fileStore,
    required this.collectionStore,
  });

  // Check if photos are available for a collection
  Future<bool> checkPhotoAvailability(String? collectionName) async {
    if (collectionName == null) return false;

    try {
      final isAvailable = await fileStore.checkMediaAvailability(
          collectionName, MediaType.image);
      return isAvailable;
    } catch (e) {
      _logger.warning('Error checking photo availability: $e');
      return false;
    }
  }

  // Show all photos in gallery
  void showAllPhotos(
    BuildContext context,
    String? collectionName, {
    required List<Map<dynamic, dynamic>> messages,
    required ItemScrollController itemScrollController,
  }) {
    if (collectionName == null || messages.isEmpty) return;

    // Use the PhotoHandler to navigate to PhotoGallery screen directly
    PhotoHandler.handleShowAllPhotos(
      context,
      collectionName,
      messages: messages,
      itemScrollController: itemScrollController,
    );
  }

  // Set state callback for photo availability
  Future<void> updatePhotoAvailability(
      String? collectionName, Function(bool) updateState) async {
    if (collectionName == null) return;

    final isAvailable = await checkPhotoAvailability(collectionName);
    updateState(isAvailable);
  }
}
