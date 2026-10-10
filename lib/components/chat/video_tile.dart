import 'package:flutter/material.dart';

import '../../screens/media/video_player_screen.dart';
import '../../theme.dart';
import '../../utils/api_db/api_service.dart';

/// Placeholder for a video (no thumbnails on the server); click to play.
class VideoTile extends StatelessWidget {
  /// Message `uri` of the video file.
  final String uri;
  final double width;
  final double height;

  const VideoTile(
      {super.key, required this.uri, this.width = 300, this.height = 188});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                VideoPlayerScreen(videoUrl: ApiService.mediaUrl(uri)))),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.bubble),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D3A4A), Color(0xFF11161C)],
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Color(0xE6FFFFFF), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                size: 32, color: Color(0xFF11161C)),
          ),
        ),
      ),
    );
  }
}
