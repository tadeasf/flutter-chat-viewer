import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/api_db/api_service.dart';
import 'message_profile_photo.dart';
import '../gallery/photo_view_gallery.dart';
import '../search/search_type.dart';
import '../search/scroll_to_highlighted_message.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../messages/message_index_manager.dart';
import '../gallery/photo_gallery.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_message_player.dart';
import '../media/video_player_screen.dart';
import 'package:intl/intl.dart';
import '../ui_utils/theme_manager.dart';

class MessageItem extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isAuthor;
  final bool isHighlighted;
  final bool isSearchActive;
  final String selectedCollectionName;
  final String? profilePhotoUrl;
  final bool isCrossCollectionSearch;
  final Function(String collectionName, int timestamp) onMessageTap;
  final List<Map<dynamic, dynamic>> messages;
  final ItemScrollController itemScrollController;

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
    required this.messages,
    required this.itemScrollController,
  });

  @override
  MessageItemState createState() => MessageItemState();
}

class MessageItemState extends State<MessageItem> {
  bool _isExpanded = false;
  final Map<String, AudioPlayer> _audioPlayers = {};

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

  void _handlePhotoTap(BuildContext context, int index, List<dynamic> photos) {
    final manager = MessageIndexManager();
    manager.updateMessages(widget.messages);

    final allPhotos = manager.allPhotos;
    final startingPhoto = photos[index];
    final startingIndex = allPhotos.indexWhere((photo) =>
        photo['uri'] == startingPhoto['uri'] &&
        photo['timestamp_ms'] == widget.message['timestamp_ms']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewGalleryScreen(
          photos: allPhotos,
          initialIndex: startingIndex >= 0 ? startingIndex : 0,
          onLongPress: (currentPhoto) {
            Navigator.pop(context);
            final messageIndex = manager.getIndexForTimestamp(
              currentPhoto['timestamp_ms'] as int,
              isPhotoTimestamp: true,
            );

            if (messageIndex != null) {
              scrollToHighlightedMessage(
                messageIndex,
                [messageIndex],
                widget.itemScrollController,
                SearchType.photoView,
              );
            }
          },
          onJumpToGallery: (currentIndex) {
            Navigator.pop(context);
            final currentPhoto = allPhotos[currentIndex];
            PhotoGalleryState.navigateToGalleryAndScroll(
              context,
              widget.isCrossCollectionSearch
                  ? widget.message['collectionName']
                  : widget.selectedCollectionName,
              currentPhoto,
              widget.messages,
              widget.itemScrollController,
            );
          },
          collectionName: widget.isCrossCollectionSearch
              ? widget.message['collectionName']
              : widget.selectedCollectionName,
          showAppBar: true,
        ),
      ),
    );
  }

  void _handleVideoTap(BuildContext context, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Color getTextColor() {
    final theme = Theme.of(context);
    if (widget.isHighlighted) {
      return theme.colorScheme.onSurface;
    }
    return theme.colorScheme.onSurface;
  }

  Widget buildMessageContent() {
    final theme = Theme.of(context);
    final List<Widget> mediaWidgets = [];
    const double displayWidth = 300.0;

    // Add text content if present
    if (widget.message['content'] != null &&
        widget.message['content'].toString().isNotEmpty) {
      mediaWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: displayWidth),
            child: Text(
              _ensureDecoded(widget.message['content']),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: ThemeManager.fontSize,
              ),
            ),
          ),
        ),
      );
    }

    // Handle photos
    if (widget.message['photos'] != null &&
        (widget.message['photos'] as List).isNotEmpty) {
      final photos = widget.message['photos'] as List;
      mediaWidgets.add(
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: photos.map<Widget>((photo) {
            return GestureDetector(
              onTap: () => _handlePhotoTap(
                  context, photos.indexOf(photo), widget.message['photos']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _generateFullUri(photo['uri']),
                  httpHeaders: ApiService.headers,
                  width: displayWidth,
                  fit: BoxFit.cover,
                  memCacheWidth: (displayWidth * 2).toInt(),
                  placeholder: (context, url) => SizedBox(
                    width: displayWidth,
                    height: displayWidth,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => SizedBox(
                    width: displayWidth,
                    height: displayWidth,
                    child: Center(
                      child: Icon(
                        Icons.error,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Handle videos
    if (widget.message['videos'] != null &&
        (widget.message['videos'] as List).isNotEmpty) {
      final videos = widget.message['videos'] as List;
      mediaWidgets.add(
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: videos.map<Widget>((video) {
            final videoUrl = ApiService.getVideoUrl(
              widget.selectedCollectionName,
              video['uri'],
            );
            return GestureDetector(
              onTap: () => _handleVideoTap(context, videoUrl),
              child: Container(
                width: displayWidth,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (video['thumbnail_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: ApiService.getPhotoUrl(
                            widget.selectedCollectionName,
                            video['thumbnail_url'],
                          ),
                          httpHeaders: ApiService.headers,
                          width: displayWidth,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.background.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: theme.colorScheme.onBackground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Play Video',
                            style: TextStyle(
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Handle audio files
    if (widget.message['audio_files'] != null &&
        (widget.message['audio_files'] as List).isNotEmpty) {
      final audioFiles = widget.message['audio_files'] as List;
      mediaWidgets.add(
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: audioFiles.map<Widget>((audio) {
            final audioUrl = ApiService.getAudioUrl(
              widget.selectedCollectionName,
              audio['uri'],
            );

            return AudioMessagePlayer(
              key: ValueKey(audio['uri']),
              audioUrl: audioUrl,
              onPlayerCreated: (String uri, AudioPlayer player) {
                _audioPlayers[uri] = player;
              },
              onPlayerDisposed: (String uri) {
                _audioPlayers.remove(uri);
              },
            );
          }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: mediaWidgets,
    );
  }

  Future<void> _handleLongPress(BuildContext context) async {
    if (!mounted || !widget.isCrossCollectionSearch) return;

    final collectionName = widget.message['collectionName'];
    if (collectionName == null) return;

    bool collectionReady = false;
    int maxAttempts = 3;
    int currentAttempt = 0;

    // Store context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );

    while (!collectionReady && currentAttempt < maxAttempts) {
      try {
        final messages = await ApiService.fetchMessages(collectionName);

        if (!mounted) return;

        // Check if we got the "please wait" response
        final messageContent =
            messages[0]['content']?.toString().toLowerCase() ?? '';
        if (messages.length == 1 &&
            messageContent.contains('please try loading collection again')) {
          await Future.delayed(const Duration(seconds: 5));
          currentAttempt++;
          continue;
        }

        // If we get here, the collection is ready
        collectionReady = true;

        if (!mounted) return;
        navigator.pop(); // Remove loading dialog
        widget.onMessageTap(
          collectionName,
          widget.message['timestamp_ms'],
        );
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Error switching to collection: $e');
        }
        currentAttempt++;
      }
    }

    // If we get here, all attempts failed
    if (!mounted) return;
    navigator.pop(); // Remove loading dialog
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          'Collection is still being prepared. Please try again in a moment.',
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isInstagram = widget.message.containsKey('is_geoblocked_for_viewer');

    Color getBubbleColor() {
      if (widget.isHighlighted) {
        return theme.colorScheme.primary.withOpacity(0.2);
      }
      if (isInstagram) {
        // Instagram styling
        if (widget.isAuthor) {
          return isDarkMode
              ? theme.colorScheme.secondary.withOpacity(0.3)
              : theme.colorScheme.secondary.withOpacity(0.3);
        } else {
          return isDarkMode
              ? theme.colorScheme.secondary.withOpacity(0.6)
              : theme.colorScheme.secondary.withOpacity(0.6);
        }
      } else {
        // Facebook styling
        if (widget.isAuthor) {
          return isDarkMode
              ? theme.colorScheme.surface.withOpacity(0.3)
              : theme.colorScheme.surface.withOpacity(0.3);
        } else {
          return isDarkMode
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.3);
        }
      }
    }

    return GestureDetector(
      onLongPress: () {
        _handleLongPress(context);
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
          constraints: const BoxConstraints(
            maxWidth: 400,
            minWidth: 100,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.isCrossCollectionSearch)
                        Text(
                          ' (${_ensureDecoded(widget.message['collectionName'] ?? 'Unknown collection')})',
                          style: theme.textTheme.bodySmall,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getBubbleColor(),
                    borderRadius: BorderRadius.circular(20),
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
                              widget.message['timestamp_ms'],
                            ),
                          ),
                          style: theme.textTheme.bodySmall,
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
