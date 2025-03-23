import 'package:mobx/mobx.dart';
import '../models/message_model.dart';
import '../models/photo_model.dart';
import 'package:logging/logging.dart';

// Include the generated file
part 'message_index_store.g.dart';

// This is the class used by rest of the codebase
class MessageIndexStore = MessageIndexStoreBase with _$MessageIndexStore;

// The store class
abstract class MessageIndexStoreBase with Store {
  final Logger _log = Logger('MessageIndexStore');

  @observable
  ObservableList<MessageModel> sortedMessages = ObservableList<MessageModel>();

  @observable
  ObservableList<PhotoModel> allPhotos = ObservableList<PhotoModel>();

  @observable
  ObservableMap<int, int> timestampToIndexMap = ObservableMap<int, int>();

  // Action to update messages and build indices
  @action
  void updateMessages(List<MessageModel> messages, List<PhotoModel> photos) {
    // Sort messages by timestamp
    sortedMessages = ObservableList.of(List<MessageModel>.from(messages)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs)));

    // Update timestamp to index map
    timestampToIndexMap = ObservableMap.of(
      Map.fromEntries(
        sortedMessages.asMap().entries.map((entry) => MapEntry(
              entry.value.timestampMs,
              entry.key,
            )),
      ),
    );

    // Update all photos
    allPhotos = ObservableList.of(photos);
  }

  @action
  void updateMessagesFromRaw(List<dynamic> rawMessages) {
    try {
      final List<MessageModel> messages = rawMessages
          .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList();

      final List<PhotoModel> photos = [];
      for (var message in rawMessages) {
        if (message['photos'] != null &&
            (message['photos'] as List).isNotEmpty) {
          for (var photo in message['photos']) {
            photos.add(PhotoModel.fromMessageJson(
                message as Map<String, dynamic>,
                photo as Map<String, dynamic>));
          }
        }
      }

      updateMessages(messages, photos);
    } catch (e) {
      _log.warning('Error updating messages from raw data: $e');
    }
  }

  // Function to get index for a timestamp
  int? getIndexForTimestamp(String timestamp, {bool isPhoto = false}) {
    try {
      return getIndexForTimestampRaw(int.parse(timestamp),
          isPhotoTimestamp: isPhoto);
    } catch (e) {
      _log.warning('Error parsing timestamp: $e');
      return null;
    }
  }

  // Function to get index for a timestamp as int
  int? getIndexForTimestampRaw(int timestamp, {bool isPhotoTimestamp = false}) {
    _log.info(
        'Looking for message with timestamp: $timestamp, isPhoto: $isPhotoTimestamp');

    // First try exact match in the timestamp map
    if (timestampToIndexMap.containsKey(timestamp)) {
      _log.info('Found exact timestamp match');
      return timestampToIndexMap[timestamp];
    }

    if (isPhotoTimestamp && allPhotos.isNotEmpty) {
      // Try to find the message with a photo matching this timestamp
      for (var photo in allPhotos) {
        _log.info(
            'Checking photo: ${photo.uri} with creation timestamp: ${photo.creationTimestamp}, message timestamp: ${photo.timestampMs}');

        // Try exact match on creation timestamp
        if (photo.creationTimestamp == timestamp) {
          _log.info('Found matching photo with timestamp ${photo.timestampMs}');
          return getIndexForTimestampRaw(photo.timestampMs);
        }

        // Try with original timestamp (not multiplied by 1000)
        if (timestamp > 1000000000000 &&
            photo.creationTimestamp * 1000 == timestamp) {
          _log.info('Found matching photo with adjusted timestamp');
          return getIndexForTimestampRaw(photo.timestampMs);
        }

        // Try with timestamp divided by 1000 (if it's already multiplied)
        if (timestamp < 1000000000000 &&
            photo.creationTimestamp == timestamp * 1000) {
          _log.info('Found matching photo with timestamp divided by 1000');
          return getIndexForTimestampRaw(photo.timestampMs);
        }
      }

      // If still not found, look for the closest timestamp in sorted messages
      if (sortedMessages.isNotEmpty) {
        _log.info('Looking for closest timestamp match');
        // For photos, we can try to find the closest message in time
        final targetTimestamp =
            timestamp > 1000000000000 ? timestamp : timestamp * 1000;

        int closestIndex = 0;
        int minDifference =
            (sortedMessages[0].timestampMs - targetTimestamp).abs();

        for (int i = 1; i < sortedMessages.length; i++) {
          final difference =
              (sortedMessages[i].timestampMs - targetTimestamp).abs();
          if (difference < minDifference) {
            minDifference = difference;
            closestIndex = i;
          }
        }

        // Only use the closest match if it's within a reasonable time range (30 minutes)
        if (minDifference < 1800000) {
          _log.info(
              'Found closest message at index $closestIndex with time difference ${minDifference / 1000} seconds');
          return closestIndex;
        }
      }
    }

    _log.warning('No matching message found for timestamp: $timestamp');
    return null;
  }
}
