import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../utils/api_db/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoMessage extends StatefulWidget {
  final String videoUri;
  final String collectionName;

  const VideoMessage({
    super.key,
    required this.videoUri,
    required this.collectionName,
  });

  @override
  VideoMessageState createState() => VideoMessageState();
}

class VideoMessageState extends State<VideoMessage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final videoUrl = ApiService.getVideoUrl(
        widget.collectionName,
        widget.videoUri,
      );

      // First fetch the video data
      final videoData = await ApiService.fetchVideoData(videoUrl);

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

      // Write video data to temporary file
      await file.writeAsBytes(videoData);

      // Initialize video player with local file
      _videoPlayerController = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        showControls: true,
        aspectRatio: _videoPlayerController.value.aspectRatio,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading video: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _initializeVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading || !_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
