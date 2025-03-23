import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
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
  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();
    // Schedule the profile photo loading for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilePhoto();
      _setupReactions();
    });
  }

  void _setupReactions() {
    final store = StoreProvider.of(context).profilePhotoStore;

    // React to error state changes
    _disposers.add(
        reaction((_) => store.errorStates[widget.collectionName], (hasError) {
      if (hasError == true) {
        _logger.warning(
            'Error loading profile photo for ${widget.collectionName}');
      }
    }));
  }

  @override
  void dispose() {
    // Dispose of all reactions
    for (final disposer in _disposers) {
      disposer();
    }
    super.dispose();
  }

  Future<void> _loadProfilePhoto() async {
    if (!mounted) return;

    // Use the store to fetch the profile photo
    final store = StoreProvider.of(context).profilePhotoStore;
    await store.getProfilePhotoUrl(widget.collectionName);
  }

  Future<void> _handlePhotoAction(bool isUpload) async {
    final profileStore = StoreProvider.of(context).profilePhotoStore;
    final galleryStore = StoreProvider.of(context).galleryStore;

    try {
      if (isUpload) {
        // Upload photo using the gallery store
        final success =
            await galleryStore.uploadPhoto(context, widget.collectionName);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')),
          );
        }
      } else {
        // Delete photo using the gallery store
        final result = await galleryStore.deletePhoto(widget.collectionName);

        if (mounted && result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );

          // Close dialog if needed
          Navigator.of(context).pop(true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        }
      }

      // Clear cache and refresh after upload/delete
      profileStore.clearCache(widget.collectionName);
      await profileStore.getProfilePhotoUrl(widget.collectionName);

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
    return Observer(builder: (_) {
      final store = StoreProvider.of(context).profilePhotoStore;
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
                          httpHeaders: {'x-api-key': ApiService.apiKey},
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
