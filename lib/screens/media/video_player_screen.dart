import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../utils/api_db/api_service.dart';

/// Full-screen video. Streams over HTTP; mpv seeks with range requests.
/// Keyboard: space play/pause, arrows/J/L seek, up/down volume, Esc closes.
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  @override
  void initState() {
    super.initState();
    _player.open(Media(widget.videoUrl,
        httpHeaders: ApiService.headersFor(widget.videoUrl)));
  }

  void _seekBy(Duration delta) {
    final target = _player.state.position + delta;
    _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  void _volumeBy(double delta) =>
      _player.setVolume((_player.state.volume + delta).clamp(0, 100));

  /// media_kit's defaults, except that Esc closes the player (in fullscreen
  /// it still only leaves fullscreen).
  late final Map<ShortcutActivator, VoidCallback> _shortcuts = {
    const SingleActivator(LogicalKeyboardKey.space): _player.playOrPause,
    const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
        _player.playOrPause,
    const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
        _seekBy(const Duration(seconds: -2)),
    const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
        _seekBy(const Duration(seconds: 2)),
    const SingleActivator(LogicalKeyboardKey.keyJ): () =>
        _seekBy(const Duration(seconds: -10)),
    const SingleActivator(LogicalKeyboardKey.keyL): () =>
        _seekBy(const Duration(seconds: 10)),
    const SingleActivator(LogicalKeyboardKey.arrowUp): () => _volumeBy(5),
    const SingleActivator(LogicalKeyboardKey.arrowDown): () => _volumeBy(-5),
    const SingleActivator(LogicalKeyboardKey.escape): () =>
        Navigator.of(context).maybePop(),
  };

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bound here as well as in the controls theme: the controls only get
    // keyboard focus after they are clicked.
    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<String>(
            stream: _player.stream.error,
            builder: (context, error) => error.hasData
                ? Center(
                    child: Text(
                      'Cannot play video: ${error.data}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : MaterialDesktopVideoControlsTheme(
                    normal: MaterialDesktopVideoControlsThemeData(
                      keyboardShortcuts: _shortcuts,
                    ),
                    fullscreen: const MaterialDesktopVideoControlsThemeData(),
                    child: Video(controller: _controller),
                  ),
          ),
        ),
      ),
    );
  }
}
