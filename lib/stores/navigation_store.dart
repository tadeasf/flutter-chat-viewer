import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:logging/logging.dart';
import 'message_store.dart';
import 'collection_store.dart';
import 'message_index_store.dart';

// Include the generated file
part 'navigation_store.g.dart';

// This is the class used by rest of the codebase
class NavigationStore = NavigationStoreBase with _$NavigationStore;

// The store class
abstract class NavigationStoreBase with Store {
  final Logger _logger = Logger('NavigationStore');
  final MessageStore messageStore;
  final CollectionStore collectionStore;
  final MessageIndexStore messageIndexStore;

  NavigationStoreBase({
    required this.messageStore,
    required this.collectionStore,
    required this.messageIndexStore,
  });

  // Observable state for cross-collection navigation
  @observable
  bool isNavigating = false;

  @observable
  String? targetCollection;

  @observable
  int? targetTimestamp;

  @observable
  int? targetMessageIndex;

  // Action to navigate to a specific message in a collection
  @action
  Future<bool> navigateToMessage(
    BuildContext context,
    String collectionName,
    int timestamp, {
    required Function(int) onScrollComplete,
    bool popCurrent = false,
  }) async {
    try {
      isNavigating = true;
      targetCollection = collectionName;
      targetTimestamp = timestamp;

      // Cache canPop before async operation
      final canPopBeforeAsyncOp = popCurrent && Navigator.canPop(context);

      // If we need to change collections
      if (messageStore.currentCollection != collectionName) {
        // Set collection and load messages
        await messageStore.setCollection(collectionName);

        // If navigation was requested from a different screen, pop it first
        if (canPopBeforeAsyncOp) {
          // Check if context is still valid after async operation
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      }

      // Find the message index for this timestamp
      messageIndexStore.updateMessagesFromRaw(messageStore.messages);
      targetMessageIndex = messageIndexStore.getIndexForTimestampRaw(timestamp);

      isNavigating = false;

      if (targetMessageIndex != null) {
        // Callback to scroll to the message (implemented by the component)
        onScrollComplete(targetMessageIndex!);
        return true;
      }

      return targetMessageIndex != null;
    } catch (e) {
      _logger.warning('Error navigating to message: $e');
      isNavigating = false;
      return false;
    }
  }

  // Action to navigate to a collection
  @action
  Future<bool> navigateToCollection(
    BuildContext context,
    String collectionName, {
    bool popCurrent = false,
  }) async {
    try {
      isNavigating = true;
      targetCollection = collectionName;

      // Cache canPop before async operation
      final canPopBeforeAsyncOp = popCurrent && Navigator.canPop(context);

      // Set collection and load messages
      await messageStore.setCollection(collectionName);

      // If navigation was requested from a different screen, pop it first
      if (canPopBeforeAsyncOp) {
        // Check if context is still valid after async operation
        if (context.mounted) {
          Navigator.pop(context);
        }
      }

      isNavigating = false;
      return true;
    } catch (e) {
      _logger.warning('Error navigating to collection: $e');
      isNavigating = false;
      return false;
    }
  }

  // Reset navigation state
  @action
  void resetNavigation() {
    isNavigating = false;
    targetCollection = null;
    targetTimestamp = null;
    targetMessageIndex = null;
  }
}
