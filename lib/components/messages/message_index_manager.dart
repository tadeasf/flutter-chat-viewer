class MessageIndexManager {
  static final MessageIndexManager _instance = MessageIndexManager._internal();
  factory MessageIndexManager() => _instance;
  MessageIndexManager._internal();

  Map<int, int>? _timestampToIndexMap;
  List<dynamic>? _sortedMessages;
  List<Map<String, dynamic>>? _allPhotos;

  void updateMessages(List<dynamic> messages) {
    _sortedMessages = List<dynamic>.from(messages)
      ..sort((a, b) =>
          (a['timestamp_ms'] as int).compareTo(b['timestamp_ms'] as int));

    _timestampToIndexMap = Map.fromEntries(
      _sortedMessages!.asMap().entries.map((entry) => MapEntry(
            entry.value['timestamp_ms'] as int,
            entry.key,
          )),
    );

    _allPhotos = [];
    for (var message in _sortedMessages!) {
      if (message['photos'] != null && (message['photos'] as List).isNotEmpty) {
        for (var photo in message['photos']) {
          _allPhotos!.add({
            'uri': photo['uri'],
            'timestamp_ms': message['timestamp_ms'],
            'creation_timestamp': photo['creation_timestamp'] * 1000,
            'collectionName':
                message['collectionName'] ?? message['collection_name'],
          });
        }
      }
    }
  }

  int? getIndexForTimestamp(
    int timestamp, {
    bool isPhotoTimestamp = false,
    bool useCreationTimestamp = false,
  }) {
    if (_sortedMessages == null || _sortedMessages!.isEmpty) {
      return null;
    }

    if (isPhotoTimestamp) {
      // Convert photo timestamp to milliseconds for comparison
      final photoTimestampMs = timestamp * 1000;

      for (var i = 0; i < _sortedMessages!.length; i++) {
        final message = _sortedMessages![i];
        if (message['photos'] != null &&
            (message['photos'] as List).isNotEmpty) {
          for (var photo in message['photos']) {
            final photoCreationTime =
                (photo['creation_timestamp'] as int?) ?? 0;
            if (photoCreationTime * 1000 == photoTimestampMs) {
              return i;
            }
          }
        }
      }
    }

    return _timestampToIndexMap?[timestamp];
  }

  List<dynamic> get sortedMessages => _sortedMessages ?? [];
  List<Map<String, dynamic>> get allPhotos => _allPhotos ?? [];
}
