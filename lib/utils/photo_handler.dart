import 'package:flutter/material.dart';
import '../screens/gallery/photo_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PhotoHandler {
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
}
