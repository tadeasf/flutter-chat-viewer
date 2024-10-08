import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'photo_view_screen.dart';
import '../api_db/api_service.dart';
import 'dart:async';
import 'package:logging/logging.dart';

class PhotoGallery extends StatefulWidget {
  final String collectionName;

  const PhotoGallery({
    super.key,
    required this.collectionName,
  });

  @override
  PhotoGalleryState createState() => PhotoGalleryState();
}

class PhotoGalleryState extends State<PhotoGallery> {
  final List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger('PhotoGallery');

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photos = await ApiService.fetchPhotos(widget.collectionName);
      setState(() {
        _photos.addAll(photos);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading photos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photos - ${widget.collectionName}'),
      ),
      body: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
        ),
        itemCount: _photos.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _photos.length && _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (index >= _photos.length) {
            return Container();
          }
          final photo = _photos[index]['photos'][0];
          return GestureDetector(
            onTap: () async {
              final imageUrl =
                  await ApiService.getSecureImageUrl(photo['fullUri']);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewScreen(
                      imageUrl: imageUrl,
                      collectionName: widget.collectionName,
                    ),
                  ),
                );
              }
            },
            child: FutureBuilder<String>(
              future: ApiService.getSecureImageUrl(photo['fullUri']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  httpHeaders: ApiService.headers,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
