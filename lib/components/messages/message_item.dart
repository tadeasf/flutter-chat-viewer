import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/api_db/api_service.dart';
import 'message_profile_photo.dart';
import '../gallery/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../messages/message_index_manager.dart';

class MessageItem extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isAuthor;
  final bool isHighlighted;
  final bool isSearchActive;
  final String selectedCollectionName;
  final String? profilePhotoUrl;
  final bool isCrossCollectionSearch;
  final Function(String collectionName, int timestamp) onMessageTap;

  const MessageItem({
    super.key,
    required this.message,
    required this.isAuthor,
    required this.isHighlighted,
    required this.isSearchActive,
    required this.selectedCollectionName,
    this.profilePhotoUrl,
    required this.isCrossCollectionSearch,
    required this.onMessageTap,
  });

  @override
  MessageItemState createState() => MessageItemState();
}

class MessageItemState extends State<MessageItem> {
  bool _isExpanded = false;

  // Darker and less vibrant Catppuccin Mocha inspired colors
  static const Color base = Color(0xFF0D0D0D);
  static const Color surface0 = Color(0xFF1A1A1A);
  static const Color surface1 = Color(0xFF262626);
  static const Color surface2 = Color(0xFF333333);
  static const Color blue = Color(0xFF4A90A4); // Adjusted blue
  static const Color lavender = Color(0xFF6A6A75);
  static const Color sapphire = Color(0xFF005B99);
  static const Color sky = Color(0xFF4A90A4);
  static const Color teal = Color(0xFF3A8C7E);
  static const Color green = Color(0xFF2A8C59);
  static const Color yellow = Color(0xFFCCAA00);
  static const Color peach = Color(0xFFCC7A00);
  static const Color maroon = Color(0xFFCC3A30);
  static const Color red = Color(0xFFCC2D55);
  static const Color mauve = Color(0xFF8A52CC);
  static const Color pink = Color(0xFFCC2D55);
  static const Color flamingo = Color(0xFFCC3A30);
  static const Color rosewater = Color(0xFFCC2D55);
  static const Color text = Color(0xFFE5E5EA);
  static const Color subtext1 = Color(0xFF8E8E93);

  String _ensureDecoded(dynamic text) {
    if (text == null) return '';
    if (text is! String) return text.toString();
    try {
      return utf8.decode(text.runes.toList());
    } catch (e) {
      return text;
    }
  }

  String _generateFullUri(String uri) {
    // If it's already a full URL, return it
    if (uri.startsWith('http')) return uri;

    // The URI from the API response is in format: messages/inbox/collectionName/photos/filename
    // We need to extract just the collection name and filename
    final parts = uri.split('/');
    String collectionName;
    String filename;

    if (parts.length >= 5) {
      // Extract from full path
      collectionName = parts[2];
      filename = parts.last;
    } else {
      // Fallback to the current collection
      collectionName = widget.isCrossCollectionSearch
          ? widget.message['collectionName'] ?? widget.selectedCollectionName
          : widget.selectedCollectionName;
      filename = uri.split('/').last;
    }

    return '${ApiService.baseUrl}/inbox/$collectionName/photos/$filename';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isInstagram = widget.message['is_geoblocked_for_viewer'] != null;

    Color getBubbleColor() {
      if (widget.isHighlighted) {
        return isDarkMode
            ? const Color(0xFFFFD700)
                .withOpacity(0.3) // Gold color for dark mode
            : const Color(0xFFFFD700)
                .withOpacity(0.2); // Gold color for light mode
      }
      if (isInstagram) {
        if (widget.isAuthor) {
          return isDarkMode
              ? const Color(0xFF8A4F6D).withOpacity(0.3)
              : const Color(0xFF8A4F6D).withOpacity(0.3);
        } else {
          return isDarkMode
              ? const Color(0xFF8A4F6D).withOpacity(0.6)
              : const Color(0xFF8A4F6D).withOpacity(0.6);
        }
      }
      // Facebook styling
      if (widget.isAuthor) {
        return isDarkMode ? surface1 : surface1.withOpacity(0.3);
      } else {
        return isDarkMode ? sapphire : sapphire.withOpacity(0.3);
      }
    }

    Color getTextColor() {
      if (widget.isHighlighted) {
        return isDarkMode ? Colors.white : Colors.black;
      }
      return isDarkMode ? text : Colors.black87;
    }

    Widget buildMessageContent() {
      if (widget.message['photos'] != null &&
          (widget.message['photos'] as List).isNotEmpty) {
        final photos = widget.message['photos'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message['content'] != null &&
                widget.message['content'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _ensureDecoded(widget.message['content']),
                  style: TextStyle(
                    color: getTextColor(),
                    fontSize: 16,
                  ),
                ),
              ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: photos.map<Widget>((photo) {
                return GestureDetector(
                  onTap: () {
                    final manager = MessageIndexManager();
                    final allPhotos = manager.allPhotos;

                    // Find the index of the current photo in all photos
                    final currentPhotoUri = photo['uri'];
                    final initialIndex = allPhotos
                        .indexWhere((p) => p['uri'] == currentPhotoUri);

                    final galleryPhotos = allPhotos.map((photo) {
                      return {
                        'filename': photo['uri'].split('/').last,
                        'fullUri': _generateFullUri(photo['uri']),
                        'timestamp_ms': photo['creation_timestamp'],
                        'collectionName': photo['collectionName'],
                      };
                    }).toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewGalleryScreen(
                          collectionName: widget.selectedCollectionName,
                          initialIndex: initialIndex,
                          photos: galleryPhotos,
                          showAppBar: true,
                          onLongPress: (currentPhoto) {
                            Navigator.pop(context);
                            final timestamp = currentPhoto['timestamp_ms'];
                            final collectionName =
                                widget.isCrossCollectionSearch
                                    ? widget.message['collectionName'] ??
                                        widget.selectedCollectionName
                                    : widget.selectedCollectionName;
                            widget.onMessageTap(collectionName, timestamp);
                          },
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onLongPress: () {
                      final collectionName = widget.isCrossCollectionSearch
                          ? widget.message['collectionName'] ??
                              widget.selectedCollectionName
                          : widget.selectedCollectionName;
                      final timestamp =
                          widget.message['timestamp_ms'] as int? ?? 0;
                      widget.onMessageTap(collectionName, timestamp);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _generateFullUri(photo['uri']),
                        httpHeaders: ApiService.headers,
                        fit: BoxFit.cover,
                        width: 200,
                        height: 200,
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                        placeholder: (context, url) => const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Error loading image: $error');
                          return const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      } else {
        return Text(
          _ensureDecoded(widget.message['content'] ?? 'No content'),
          style: TextStyle(
            color: getTextColor(),
            fontSize: 16,
          ),
        );
      }
    }

    return GestureDetector(
      onLongPress: () {
        final collectionName = widget.isCrossCollectionSearch
            ? widget.message['collectionName'] ?? widget.selectedCollectionName
            : widget.selectedCollectionName;
        final timestamp = widget.message['timestamp_ms'] as int? ?? 0;
        widget.onMessageTap(collectionName, timestamp);
      },
      child: Align(
        alignment:
            widget.isAuthor ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: widget.isAuthor ? 64 : 8,
            right: widget.isAuthor ? 8 : 64,
          ),
          child: Column(
            crossAxisAlignment: widget.isAuthor
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!widget.isAuthor || widget.isCrossCollectionSearch)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MessageProfilePhoto(
                        collectionName: widget.isCrossCollectionSearch
                            ? widget.message['collectionName']
                            : widget.selectedCollectionName,
                        size: 24.0,
                        isOnline: widget.message['is_online'] ?? false,
                        profilePhotoUrl: widget.profilePhotoUrl,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ensureDecoded(
                            widget.message['sender_name'] ?? 'Unknown sender'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDarkMode ? subtext1 : Colors.grey[700],
                        ),
                      ),
                      if (widget.isCrossCollectionSearch)
                        Text(
                          ' (${_ensureDecoded(widget.message['collectionName'] ?? 'Unknown collection')})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? subtext1 : Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: getBubbleColor(),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildMessageContent(),
                      if (_isExpanded) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                widget.message['timestamp_ms']),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: getTextColor().withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
