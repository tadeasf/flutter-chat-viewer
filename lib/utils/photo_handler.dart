import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_db/api_service.dart';
import '../screens/gallery/photo_gallery.dart';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../stores/store_provider.dart';

class PhotoHandler {
  static final Logger _logger = Logger('PhotoHandler');
  static XFile? image;

  // Check photo availability by using the ProfilePhotoStore
  static Future<void> checkPhotoAvailability(
      String? collectionName, Function setState) async {
    if (collectionName == null) return;

    try {
      final response = await ApiService.get(
        '/collection/has-photo/${Uri.encodeComponent(collectionName)}',
        headers: {'x-api-key': ApiService.apiKey},
      );
      // ignore: unused_local_variable
      final result = json.decode(response.body);

      setState(() {
        // Update the UI state with photo availability
      });
    } catch (e) {
      _logger.warning('Error checking photo availability: $e');
    }
  }

  // This method is still useful as it's a UI navigation function
  static void handleShowAllPhotos(
    BuildContext context,
    String? selectedCollection, {
    List<Map<dynamic, dynamic>>? messages = const [],
    ItemScrollController? itemScrollController,
  }) {
    if (selectedCollection == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGallery(
          collectionName: selectedCollection,
          messages: messages ?? [],
          itemScrollController: itemScrollController ?? ItemScrollController(),
        ),
      ),
    );
  }

  static Future<void> getImage(ImagePicker picker, Function setState) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        image = pickedFile;
      }
    });
  }

  static Future<void> uploadImage(BuildContext context, XFile? image,
      String? selectedCollection, Function setState) async {
    if (image == null || selectedCollection == null) return;

    setState(() {
      // UI state update only
    });

    try {
      // Read image data
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Create request data
      final photoData = {
        'photo': base64Image,
      };

      // Make API call
      await ApiService.post(
        '/upload/photo/${Uri.encodeComponent(selectedCollection)}',
        body: photoData,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiService.apiKey,
        },
      );

      if (!context.mounted) return;

      // Update the store
      final store = StoreProvider.of(context).profilePhotoStore;
      store.clearCache(selectedCollection);
      await store.getProfilePhotoUrl(selectedCollection);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')));
      }
    } catch (e) {
      _logger.warning('Error uploading photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error uploading photo')));
      }
    }
  }

  static Future<void> deletePhoto(
      BuildContext context, String collectionName, Function setState) async {
    try {
      final response = await ApiService.delete(
        '/delete/photo/${Uri.encodeComponent(collectionName)}',
        headers: {'x-api-key': ApiService.apiKey},
      );
      final result = json.decode(response.body);

      if (!context.mounted) return;

      if (result['success']) {
        // Update the store
        final store = StoreProvider.of(context).profilePhotoStore;
        store.clearCache(collectionName);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          // UI navigation
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      _logger.warning('Error deleting photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting photo: ${e.toString()}')),
        );
      }
    }
  }
}
