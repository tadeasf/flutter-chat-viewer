import 'package:flutter/material.dart';
import 'profile_photo_store.dart';
import 'collection_store.dart';
import 'message_store.dart';
import 'theme_store.dart';
import 'file_store.dart';
import 'gallery_store.dart';
import 'photo_store/photo_store.dart';

/// A provider for MobX stores throughout the application
class StoreProvider extends InheritedWidget {
  final ProfilePhotoStore profilePhotoStore;
  final CollectionStore collectionStore;
  final MessageStore messageStore;
  final ThemeStore themeStore;
  final FileStore fileStore;
  final GalleryStore galleryStore;
  final PhotoStore photoStore;

  const StoreProvider({
    super.key,
    required this.profilePhotoStore,
    required this.collectionStore,
    required this.messageStore,
    required this.themeStore,
    required this.fileStore,
    required this.galleryStore,
    required this.photoStore,
    required super.child,
  });

  static StoreProvider of(BuildContext context) {
    final StoreProvider? result =
        context.dependOnInheritedWidgetOfExactType<StoreProvider>();
    assert(result != null, 'No StoreProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(StoreProvider oldWidget) {
    return profilePhotoStore != oldWidget.profilePhotoStore ||
        collectionStore != oldWidget.collectionStore ||
        messageStore != oldWidget.messageStore ||
        themeStore != oldWidget.themeStore ||
        fileStore != oldWidget.fileStore ||
        galleryStore != oldWidget.galleryStore ||
        photoStore != oldWidget.photoStore;
  }
}

/// Utility class to manage global store instances
class Stores {
  static final fileStore = FileStore();
  static final collectionStore = CollectionStore();
  static final messageStore = MessageStore();
  static final themeStore = ThemeStore();
  static final galleryStore = GalleryStore();

  // PhotoStore depends on file store
  static final photoStore = PhotoStore(
    fileStore: fileStore,
    collectionStore: collectionStore,
  );

  // ProfilePhotoStore depends on file store
  static final profilePhotoStore = ProfilePhotoStore(
    fileStore: fileStore,
  );
}
