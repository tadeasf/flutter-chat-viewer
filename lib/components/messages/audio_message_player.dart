import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../stores/store_provider.dart';
import '../../stores/file_store.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Function(String uri, AudioPlayer player) onPlayerCreated;
  final Function(String uri) onPlayerDisposed;
  final String? collectionName;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.onPlayerCreated,
    required this.onPlayerDisposed,
    this.collectionName,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _errorMessage;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once and when user clicks play
    if (!_didInitialize && !_isInitialized && !_isLoading) {
      _didInitialize = true;
    }
  }

  String _getFormattedUrl() {
    // If it's already a full URL, return it
    if (widget.audioUrl.startsWith('http')) return widget.audioUrl;

    final fileStore = StoreProvider.of(context).fileStore;
    final collectionName = widget.collectionName ?? 'default';

    // Use FileStore to format the audio URL
    return fileStore.formatMediaUrl(
      uri: widget.audioUrl,
      type: MediaType.audio,
      collectionName: collectionName,
    );
  }

  Future<void> _initializePlayer() async {
    if (_isInitialized || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _audioPlayer = AudioPlayer();
      widget.onPlayerCreated(widget.audioUrl, _audioPlayer!);

      final fileStore = StoreProvider.of(context).fileStore;
      final formattedUrl = _getFormattedUrl();

      if (kIsWeb) {
        // For web, use URL directly
        await _audioPlayer!.setUrl(
          formattedUrl,
          headers: {'x-api-key': fileStore.apiKey},
        );
      } else {
        // Try to get from cache first
        final cachedPath =
            await fileStore.getFile(widget.audioUrl, MediaType.audio);

        if (cachedPath != null) {
          // Use cached file
          await _audioPlayer!.setFilePath(cachedPath);
        } else {
          // Use the URL
          await _audioPlayer!.setUrl(
            formattedUrl,
            headers: {'x-api-key': fileStore.apiKey},
          );
        }
      }

      _audioPlayer!.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });

        // Start playing immediately after loading
        _audioPlayer!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load audio: $e';
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _errorMessage != null
          ? Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _initializePlayer();
                  },
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLoading
                            ? Icons.hourglass_empty
                            : _isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (!_isInitialized) {
                                _initializePlayer();
                              } else if (_isPlaying) {
                                _audioPlayer?.pause();
                              } else {
                                _audioPlayer?.play();
                              }
                            },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value:
                                _isInitialized && _duration.inMilliseconds > 0
                                    ? _position.inMilliseconds /
                                        _duration.inMilliseconds
                                    : 0,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isInitialized
                                ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                                : '00:00 / 00:00',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'JetBrains Mono Nerd Font',
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
      widget.onPlayerDisposed(widget.audioUrl);
    }
    super.dispose();
  }
}
