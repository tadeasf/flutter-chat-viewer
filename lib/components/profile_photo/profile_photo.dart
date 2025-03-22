import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_mobx/flutter_mobx.dart';

import '../gallery/photo_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/api_db/api_service.dart';
import '../../utils/web_image_viewer.dart';
import '../../stores/store_provider.dart';

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final bool showButtons;
  final VoidCallback? onPhotoDeleted;
  final String? profilePhotoUrl;

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 100.0,
    this.isOnline = false,
    this.showButtons = true,
    this.onPhotoDeleted,
    this.profilePhotoUrl,
  });

  @override
  ProfilePhotoState createState() => ProfilePhotoState();
}

class ProfilePhotoState extends State<ProfilePhoto> {
  final Logger _logger = Logger('ProfilePhoto');

  @override
  void initState() {
    super.initState();
    // Schedule the profile photo loading for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilePhoto();
    });
  }

  Future<void> _loadProfilePhoto() async {
    if (!mounted) return;

    // Use the store to fetch the profile photo
    final store = StoreProvider.of(context).profilePhotoStore;
    await store.getProfilePhotoUrl(widget.collectionName);
  }

  Future<void> _handlePhotoAction(bool isUpload) async {
    final store = StoreProvider.of(context).profilePhotoStore;

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
      }

      // Clear cache and refresh after upload/delete
      store.clearCache(widget.collectionName);
      await store.getProfilePhotoUrl(widget.collectionName);

      widget.onPhotoDeleted?.call();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context).profilePhotoStore;

    return Observer(builder: (_) {
      final isLoading = store.isLoading(widget.collectionName);
      final hasError = store.hasError(widget.collectionName);
      final imageUrl = store.profilePhotoUrls[widget.collectionName];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              if (isLoading)
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (hasError || imageUrl == null)
                Icon(
                  Icons.account_circle,
                  size: widget.size,
                  color: Colors.grey,
                )
              else
                ClipOval(
                  child: kIsWeb
                      ? WebImageViewer(
                          imageUrl: imageUrl,
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
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
    });
  }
}
