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

  int? getIndexForTimestamp(int timestamp, {bool isPhotoSearch = false}) {
    if (_timestampToIndexMap == null || _timestampToIndexMap!.isEmpty) {
      return null;
    }

    if (isPhotoSearch) {
      // For photos, find the message that contains this photo's creation timestamp
      for (var i = 0; i < _sortedMessages!.length; i++) {
        var message = _sortedMessages![i];
        if (message['photos'] != null) {
          for (var photo in message['photos']) {
            if ((photo['creation_timestamp'] * 1000) == timestamp) {
              return i;
            }
          }
        }
      }
    }

    // If no photo match found or not a photo search, use regular timestamp matching
    var timestamps = _timestampToIndexMap!.keys.toList()..sort();

    if (_timestampToIndexMap!.containsKey(timestamp)) {
      return _timestampToIndexMap![timestamp];
    }

    // Find closest timestamp
    var closestTimestamp = timestamps.reduce((a, b) {
      return (timestamp - a).abs() < (timestamp - b).abs() ? a : b;
    });
    return _timestampToIndexMap![closestTimestamp];
  }

  List<dynamic> get sortedMessages => _sortedMessages ?? [];
  List<Map<String, dynamic>> get allPhotos => _allPhotos ?? [];
}
