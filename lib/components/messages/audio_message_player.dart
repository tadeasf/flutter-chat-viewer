import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../utils/api_db/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../stores/store_provider.dart';
import '../../stores/file_store.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Function(String uri, AudioPlayer player) onPlayerCreated;
  final Function(String uri) onPlayerDisposed;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.onPlayerCreated,
    required this.onPlayerDisposed,
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

      if (kIsWeb) {
        // For web, use URL directly
        await _audioPlayer!.setUrl(
          widget.audioUrl,
          headers: ApiService.headers,
        );
      } else {
        // Try to get from cache first
        final cachedPath =
            await fileStore.getFile(widget.audioUrl, MediaType.audio);

        if (cachedPath != null) {
          // Use cached file
          await _audioPlayer!.setFilePath(cachedPath);
        } else {
          // Fetch the audio data
          final bytes = await ApiService.fetchAudioData(widget.audioUrl);

          // Get temporary directory
          final dir = await getTemporaryDirectory();
          final file = File(
              '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.aac');

          // Write the bytes to a temporary file
          await file.writeAsBytes(bytes);

          // Set the audio source from the file
          await _audioPlayer!.setFilePath(file.path);
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

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Start playing immediately after loading
      _audioPlayer!.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load audio';
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
                              fontFamily: 'CaskaydiaCove Nerd Font',
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
