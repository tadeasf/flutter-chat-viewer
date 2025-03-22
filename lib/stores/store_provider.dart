import 'package:flutter/material.dart';
import 'profile_photo_store.dart';
import 'collection_store.dart';
import 'message_store.dart';

/// A provider for MobX stores throughout the application
class StoreProvider extends InheritedWidget {
  final ProfilePhotoStore profilePhotoStore;
  final CollectionStore collectionStore;
  final MessageStore messageStore;

  const StoreProvider({
    super.key,
    required this.profilePhotoStore,
    required this.collectionStore,
    required this.messageStore,
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
        messageStore != oldWidget.messageStore;
  }
}

/// Utility class to manage global store instances
class Stores {
  static final profilePhotoStore = ProfilePhotoStore();
  static final collectionStore = CollectionStore();
  static final messageStore = MessageStore();
}
