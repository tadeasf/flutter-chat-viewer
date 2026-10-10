import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../theme.dart';
import '../../utils/api_db/api_service.dart';

/// Inline player for a voice message. Streams over HTTP (mpv seeks with range
/// requests and detects the format itself, so `.aac` served as
/// application/octet-stream plays fine). The player is created on first play.
class AudioMessagePlayer extends StatefulWidget {
  /// Message `uri` of the audio file.
  final String uri;

  const AudioMessagePlayer({super.key, required this.uri});

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  Player? _player;
  final List<StreamSubscription> _subscriptions = [];
  bool _playing = false;
  bool _buffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  Future<void> _start() async {
    final url = ApiService.mediaUrl(widget.uri);
    final player = Player();
    _player = player;
    _subscriptions.addAll([
      player.stream.playing.listen((v) => _update(() => _playing = v)),
      player.stream.buffering.listen((v) => _update(() => _buffering = v)),
      player.stream.position.listen((v) => _update(() => _position = v)),
      player.stream.duration.listen((v) => _update(() => _duration = v)),
      player.stream.error.listen((e) => _update(() => _error = e)),
      player.stream.completed.listen((done) {
        if (done) player.seek(Duration.zero).then((_) => player.pause());
      }),
    ]);
    await player.open(Media(url, httpHeaders: ApiService.headersFor(url)));
  }

  void _update(VoidCallback change) {
    if (mounted) setState(change);
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player == null) {
      setState(() => _buffering = true);
      await _start();
    } else {
      await player.playOrPause();
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  static String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = _duration.inMilliseconds.toDouble();
    if (_error != null) {
      return Container(
        width: 280,
        padding: const EdgeInsets.all(Space.m),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(Radii.bubble),
        ),
        child: Text('Cannot play this voice message: $_error',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onErrorContainer)),
      );
    }
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(6, 6, Space.m, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.bubble),
      ),
      child: Row(
        children: [
          IconButton.filled(
            tooltip: _playing ? 'Pause' : 'Play',
            onPressed: _toggle,
            iconSize: 20,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            icon: _buffering && !_playing
                ? SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: scheme.onPrimary),
                  )
                : Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.m),
                child: Slider(
                  max: max > 0 ? max : 1,
                  value: _position.inMilliseconds
                      .clamp(0, max > 0 ? max : 1)
                      .toDouble(),
                  onChanged: max > 0
                      ? (v) => setState(
                          () => _position = Duration(milliseconds: v.round()))
                      : null,
                  onChangeEnd: max > 0
                      ? (v) => _player?.seek(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
            ),
          ),
          Text(
            _duration == Duration.zero
                ? '--:--'
                : '${_format(_position)} / ${_format(_duration)}',
            style: monoStyle(context),
          ),
        ],
      ),
    );
  }
}
