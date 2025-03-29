import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../utils/api_db/api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:io';
import '../../stores/store_provider.dart';
import '../../stores/file_store.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _didInitialize = false;
  String? _localVideoPath;

  @override
  void initState() {
    super.initState();
    // Don't initialize here as it will cause dependency issues
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once
    if (!_didInitialize) {
      _didInitialize = true;
      _initializePlayer();
    }
  }

  Future<void> _openInSystemPlayer() async {
    try {
      if (_localVideoPath != null) {
        // For Linux, use Haruna video player
        if (kDebugMode) {
          print('Opening video in Haruna: $_localVideoPath');
        }

        final result = await Process.run('haruna', [_localVideoPath!]);
        if (result.exitCode != 0) {
          if (kDebugMode) {
            print('Haruna error: ${result.stderr}');
          }
          // If Haruna fails, try falling back to xdg-open
          final fallbackResult =
              await Process.run('xdg-open', [_localVideoPath!]);
          if (fallbackResult.exitCode != 0) {
            throw Exception('Failed to open video: ${fallbackResult.stderr}');
          }
        }

        if (mounted) {
          Navigator.of(context)
              .pop(); // Close the video screen after opening in Haruna
        }
      } else {
        throw Exception('No local video file available');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening video player: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error opening video: $e\nPlease make sure Haruna video player is installed.';
        });
      }
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (kDebugMode) {
        print('Initializing video player with URL: ${widget.videoUrl}');
      }

      // Get the video file (either from cache or network)
      final fileStore = StoreProvider.of(context).fileStore;
      final cachedPath =
          await fileStore.getFile(widget.videoUrl, MediaType.video);
      _localVideoPath = cachedPath;

      // On Linux, we'll use the system video player
      if (Platform.isLinux && !kIsWeb) {
        if (cachedPath != null) {
          await _openInSystemPlayer();
        } else {
          throw Exception('Failed to get video file');
        }
        return;
      }

      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          httpHeaders: ApiService.headers,
        );
      } else {
        if (cachedPath != null) {
          if (kDebugMode) {
            print('Using cached video file: $cachedPath');
          }
          _videoPlayerController = VideoPlayerController.file(
            File(cachedPath),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          if (kDebugMode) {
            print('No cached video found, using network URL');
          }
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(widget.videoUrl),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            httpHeaders: ApiService.headers,
          );
          fileStore.prefetchFile(widget.videoUrl, MediaType.video);
        }
      }

      if (_videoPlayerController == null) {
        throw Exception('Failed to initialize video player controller');
      }

      await _videoPlayerController!.initialize();

      if (_videoPlayerController!.value.hasError) {
        throw Exception(
            'Video player initialization error: ${_videoPlayerController!.value.errorDescription}');
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing video player: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading video: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (Platform.isLinux && _localVideoPath != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: _openInSystemPlayer,
              tooltip: 'Open in system player',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (Platform.isLinux && !kIsWeb) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Built-in video player is not supported on Linux.\nClick the button to open in Haruna video player.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _openInSystemPlayer,
            child: const Text('Open in Haruna'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Please ensure Haruna video player is installed.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _initializePlayer,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_isLoading || !_isInitialized || _chewieController == null) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    }

    return Chewie(controller: _chewieController!);
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
