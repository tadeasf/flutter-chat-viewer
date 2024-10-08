import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_db/api_service.dart';
import 'photo_gallery.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

class PhotoHandler {
  static final Logger _logger = Logger('PhotoHandler');
  static XFile? image;
  static bool isPhotoAvailable = false;
  static bool isUploading = false;
  static String? imageUrl;

  static void handleShowAllPhotos(
      BuildContext context, String? selectedCollection) {
    if (selectedCollection == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGallery(collectionName: selectedCollection),
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
      isUploading = true;
    });

    try {
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final photoData = {
        'photo': base64Image,
      };

      await ApiService.post(
        '/upload/photo/${Uri.encodeComponent(selectedCollection)}',
        body: photoData,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiService.apiKey,
        },
      );

      setState(() {
        isUploading = false;
        isPhotoAvailable = true;
        imageUrl = ApiService.getProfilePhotoUrl(selectedCollection);
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')));
        await checkPhotoAvailability(selectedCollection, setState);
      }
    } catch (e) {
      _logger.warning('Error uploading photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error uploading photo')));
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  static Future<void> checkPhotoAvailability(
      String? selectedCollection, Function setState) async {
    if (selectedCollection == null) return;

    try {
      final response = await ApiService.get(
        '/messages/${Uri.encodeComponent(selectedCollection)}/photo',
        headers: {'x-api-key': ApiService.apiKey},
      );
      final isAvailable = json.decode(response.body)['isPhotoAvailable'];
      setState(() {
        isPhotoAvailable = isAvailable;
      });
    } catch (e) {
      _logger.warning('Error checking photo availability: $e');
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

      if (result['success']) {
        setState(() {
          isPhotoAvailable = false;
          imageUrl = null; // Clear the imageUrl
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          // Notify the app that the photo has been deleted
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
