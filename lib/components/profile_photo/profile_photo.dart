import 'package:flutter/material.dart';

import '../gallery/photo_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_photo_manager.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_db/api_service.dart';

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final bool showButtons;
  final String? profilePhotoUrl;
  final VoidCallback? onPhotoDeleted; // Add this callback

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 100.0,
    this.isOnline = false,
    this.showButtons = true,
    this.profilePhotoUrl,
    this.onPhotoDeleted, // Add this to the constructor
  });

  @override
  ProfilePhotoState createState() => ProfilePhotoState();
}

class ProfilePhotoState extends State<ProfilePhoto> {
  final Logger _logger = Logger('ProfilePhoto');
  String? _imageUrl;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchProfilePhoto();
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final url =
          await ProfilePhotoManager.getProfilePhotoUrl(widget.collectionName);
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.warning('Error fetching profile photo: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePhotoAction(bool isUpload) async {
    setState(() => _isLoading = true);
    try {
      if (isUpload) {
        // Upload photo
        await PhotoHandler.getImage(ImagePicker(), (newState) {
          if (mounted) {
            setState(newState);
          }
        });
        if (PhotoHandler.image != null && mounted) {
          await PhotoHandler.uploadImage(
            context,
            PhotoHandler.image,
            widget.collectionName,
            (newState) {
              if (mounted) {
                setState(newState);
              }
            },
          );
        }
      } else {
        // Delete photo
        await PhotoHandler.deletePhoto(
          context,
          widget.collectionName,
          (newState) {
            if (mounted) {
              setState(newState);
            }
          },
        );
        ProfilePhotoManager.clearCache(widget.collectionName);
        widget.onPhotoDeleted?.call();
      }
      _fetchProfilePhoto(); // Refresh the photo status
    } catch (e) {
      _logger.warning('Error ${isUpload ? 'uploading' : 'deleting'} photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to ${isUpload ? 'upload' : 'delete'} photo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            if (_isLoading)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_isError || _imageUrl == null)
              Icon(
                Icons.account_circle,
                size: widget.size,
                color: Colors.grey,
              )
            else
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  httpHeaders: ApiService.headers,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, error, stackTrace) {
                    _logger.warning('Error loading image: $error');
                    return Icon(
                      Icons.account_circle,
                      size: widget.size,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            if (widget.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showButtons) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _handlePhotoAction(false),
                tooltip: 'Delete Photo',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () => _handlePhotoAction(true),
                tooltip: 'Upload Photo',
              ),
            ],
          ),
        ],
      ],
    );
  }
}
