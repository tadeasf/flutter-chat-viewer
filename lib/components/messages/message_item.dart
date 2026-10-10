import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/api_db/api_service.dart';
import 'message_profile_photo.dart';
import '../../screens/gallery/photo_view_gallery.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_message_player.dart';
import '../../screens/media/video_player_screen.dart';
import 'package:intl/intl.dart';
import '../../stores/store_provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../stores/theme_store.dart';

class MessageItem extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isAuthor;
  final bool isHighlighted;
  final String selectedCollectionName;
  final String? profilePhotoUrl;
  final bool isCrossCollectionSearch;
  final Function(String collectionName, int timestamp) onMessageTap;

  const MessageItem({
    super.key,
    required this.message,
    required this.isAuthor,
    required this.isHighlighted,
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

  void _handlePhotoTap(BuildContext context, int index, List<dynamic> photos) {
    // Cast to Map<String, dynamic> to avoid type issues
    final photosAsMaps = List<Map<String, dynamic>>.from(
        photos.map((photo) => Map<String, dynamic>.from(photo)));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewGalleryScreen(
          photos: photosAsMaps,
          initialIndex: index,
          collectionName: widget.isCrossCollectionSearch
              ? widget.message['collectionName'] ?? ''
              : widget.selectedCollectionName,
          showAppBar: true,
        ),
      ),
    );
  }

  void _handleVideoTap(BuildContext context, String videoUri) {
    final videoUrl = ApiService.mediaUrl(videoUri);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  void _handleAudioTap(Map<String, dynamic> audio) {
    final audioUri = audio['uri'] as String;
    final audioUrl = ApiService.mediaUrl(audioUri);

    // Check if this audio player exists
    if (!_audioPlayers.containsKey(audioUri)) {
      _audioPlayers[audioUri] = AudioPlayer();
    }

    // Get the audio player
    final player = _audioPlayers[audioUri]!;

    if (player.playing) {
      player.pause();
    } else {
      // Load and play the audio
      player
          .setUrl(audioUrl, headers: ApiService.headersFor(audioUrl))
          .then((_) {
        player.play();
      });
    }
  }

  @override
  void dispose() {
    // Dispose all audio players
    for (final player in _audioPlayers.values) {
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
    final themeStore = StoreProvider.of(context).themeStore;
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
            child: Observer(
              builder: (_) => Text(
                _ensureDecoded(widget.message['content']),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'CaskaydiaCoveNerdFontMono',
                  fontSize: themeStore.fontSize,
                ),
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
                  imageUrl: ApiService.mediaUrl(photo['uri']),
                  httpHeaders:
                      ApiService.headersFor(ApiService.mediaUrl(photo['uri'])),
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
            final videoUri = video['uri'] as String;
            return GestureDetector(
              onTap: () => _handleVideoTap(context, videoUri),
              child: Container(
                width: displayWidth,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (video['thumbnail_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: ApiService.mediaUrl(video['thumbnail_url']),
                          httpHeaders: ApiService.headersFor(
                              ApiService.mediaUrl(video['thumbnail_url'])),
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
                        color: theme.colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Play Video',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
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
            return GestureDetector(
              onTap: () => _handleAudioTap(Map<String, dynamic>.from(audio)),
              child: AudioMessagePlayer(
                key: ValueKey(audio['uri']),
                audioUrl: audio['uri'],
                collectionName: widget.isCrossCollectionSearch
                    ? widget.message['collectionName']
                    : widget.selectedCollectionName,
                onPlayerCreated: (String uri, AudioPlayer player) {
                  _audioPlayers[uri] = player;
                },
                onPlayerDisposed: (String uri) {
                  _audioPlayers.remove(uri);
                },
              ),
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

  void _handleLongPress() {
    final collectionName = widget.message['collectionName'];
    if (!widget.isCrossCollectionSearch || collectionName == null) return;
    widget.onMessageTap(collectionName, widget.message['timestamp_ms']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInstagram = widget.message.containsKey('is_geoblocked_for_viewer');

    Color getBubbleColor() {
      if (widget.isHighlighted) {
        return theme.colorScheme.primary.withAlpha(51); // 0.2 alpha
      }
      if (isInstagram) {
        // Instagram styling
        if (widget.isAuthor) {
          return AppColors.authorBubble;
        } else {
          return AppColors.senderBubble;
        }
      } else {
        // Facebook styling
        if (widget.isAuthor) {
          return AppColors.authorBubble;
        } else {
          return AppColors.senderBubble;
        }
      }
    }

    return GestureDetector(
      onLongPress: _handleLongPress,
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
                        size: 32.0,
                        isOnline: widget.message['is_online'] ?? false,
                        profilePhotoUrl: widget.profilePhotoUrl,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ensureDecoded(
                            widget.message['sender_name'] ?? 'Unknown sender'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'JetBrains Mono Nerd Font',
                          fontSize: 14,
                        ),
                      ),
                      if (widget.isCrossCollectionSearch)
                        Text(
                          ' (${_ensureDecoded(widget.message['collectionName'] ?? 'Unknown collection')})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'JetBrains Mono Nerd Font',
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getBubbleColor(),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'CaskaydiaCoveNerdFontMono',
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
