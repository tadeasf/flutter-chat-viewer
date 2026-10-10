import 'package:flutter/material.dart';
import '../screens/gallery/photo_gallery.dart';

class PhotoHandler {
  // This method is still useful as it's a UI navigation function
  static void handleShowAllPhotos(
    BuildContext context,
    String? selectedCollection,
  ) {
    if (selectedCollection == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGallery(collectionName: selectedCollection),
      ),
    );
  }
}
