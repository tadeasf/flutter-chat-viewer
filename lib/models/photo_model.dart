class PhotoModel {
  final String uri;
  final int timestampMs;
  final int creationTimestamp;
  final String? collectionName;
  final Map<String, dynamic> rawData;

  PhotoModel({
    required this.uri,
    required this.timestampMs,
    required this.creationTimestamp,
    this.collectionName,
    required this.rawData,
  });

  factory PhotoModel.fromMessageJson(
      Map<String, dynamic> messageJson, Map<String, dynamic> photoJson) {
    return PhotoModel(
      uri: photoJson['uri'] as String,
      timestampMs: messageJson['timestamp_ms'] as int,
      creationTimestamp: (photoJson['creation_timestamp'] as int?) != null 
          ? (photoJson['creation_timestamp'] as int) * 1000
          : messageJson['timestamp_ms'] as int,
      collectionName: messageJson['collectionName'] ??
          messageJson['collection_name'] as String?,
      rawData: {...photoJson, 'message': messageJson},
    );
  }

  Map<String, dynamic> toJson() => rawData;
}