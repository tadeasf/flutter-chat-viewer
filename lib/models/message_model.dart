class MessageModel {
  final int timestampMs;
  final String? text;
  final List<Map<String, dynamic>>? photos;
  final String? collectionName;
  final String? senderName;
  final String? senderId;
  final Map<String, dynamic> rawData;

  MessageModel({
    required this.timestampMs,
    this.text,
    this.photos,
    this.collectionName,
    this.senderName,
    this.senderId,
    required this.rawData,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      timestampMs: json['timestamp_ms'] as int,
      text: json['content'] as String?,
      photos: json['photos'] != null
          ? (json['photos'] as List)
              .map((p) => p as Map<String, dynamic>)
              .toList()
          : null,
      collectionName:
          json['collectionName'] ?? json['collection_name'] as String?,
      senderName: json['sender_name'] as String?,
      senderId: json['sender_id'] as String?,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() => rawData;
}