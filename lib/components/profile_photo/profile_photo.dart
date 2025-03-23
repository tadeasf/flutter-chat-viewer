import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../stores/store_provider.dart';
import '../../utils/api_db/api_service.dart';

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final String? profilePhotoUrl;
  final bool showButtons;
  final VoidCallback? onPhotoDeleted;

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 128.0,
    this.isOnline = true,
    required this.profilePhotoUrl,
    this.showButtons = false,
    this.onPhotoDeleted,
  });

  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.size * 1.25,
          height: widget.size * 1.25,
          margin: EdgeInsets.all(widget.size * 0.15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: widget.profilePhotoUrl != null &&
                  widget.profilePhotoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(widget.size * 1.25 / 2),
                  child: CachedNetworkImage(
                    imageUrl: widget.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    httpHeaders: {'x-api-key': ApiService.apiKey},
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.white54,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: widget.size * 0.625,
                  color: Colors.white54,
                ),
        ),
        if (widget.isOnline)
          Positioned(
            right: widget.size * 0.15,
            bottom: widget.size * 0.15,
            child: Container(
              width: widget.size * 0.25 * 1.25,
              height: widget.size * 0.25 * 1.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        if (widget.showButtons &&
            widget.profilePhotoUrl != null &&
            widget.profilePhotoUrl!.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final profilePhotoStore =
                    StoreProvider.of(context).profilePhotoStore;
                final String collectionToDelete = widget.collectionName;
                final VoidCallback? deleteCallback = widget.onPhotoDeleted;

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Delete Profile Photo?'),
                      content: const Text(
                          'Are you sure you want to delete this profile photo?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  await profilePhotoStore
                      .deleteProfilePhoto(collectionToDelete);

                  if (!mounted) return;

                  if (deleteCallback != null) {
                    deleteCallback();
                  }
                }
              },
            ),
          ),
      ],
    );
  }
}
