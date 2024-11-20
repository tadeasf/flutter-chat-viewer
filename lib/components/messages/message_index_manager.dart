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

    // Extract all photos from messages
    _allPhotos = [];
    for (var message in _sortedMessages!) {
      if (message['photos'] != null && (message['photos'] as List).isNotEmpty) {
        for (var photo in message['photos']) {
          _allPhotos!.add({
            'uri': photo['uri'],
            'timestamp_ms': message['timestamp_ms'],
            'collectionName': message['collectionName']
          });
        }
      }
    }
  }

  int? getIndexForTimestamp(int timestamp) {
    if (_timestampToIndexMap == null || _timestampToIndexMap!.isEmpty) {
      return null;
    }

    // First try exact match
    if (_timestampToIndexMap!.containsKey(timestamp)) {
      return _timestampToIndexMap![timestamp];
    }

    // If no exact match, find the closest message
    var timestamps = _timestampToIndexMap!.keys.toList()..sort();
    var closestTimestamp = timestamps.firstWhere(
      (t) => t >= timestamp,
      orElse: () => timestamps.last,
    );

    return _timestampToIndexMap![closestTimestamp];
  }

  List<dynamic> get sortedMessages => _sortedMessages ?? [];
  List<Map<String, dynamic>> get allPhotos => _allPhotos ?? [];
}
