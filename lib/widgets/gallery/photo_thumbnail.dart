import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/web_image_viewer.dart';
import '../../utils/api_db/api_service.dart';
import '../../components/ui_utils/media_unavailable.dart';

class PhotoThumbnail extends StatelessWidget {
  final String imageUrl;
  final String collectionName;
  final double? aspectRatio;

  const PhotoThumbnail({
    super.key,
    required this.imageUrl,
    required this.collectionName,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'photo_$imageUrl',
      child: kIsWeb
          ? WebImageViewer(
              imageUrl: imageUrl,
              width: MediaQuery.of(context).size.width / 3 - 8,
              height: MediaQuery.of(context).size.width / 3 - 8,
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: imageUrl,
              httpHeaders: ApiService.headersFor(imageUrl),
              fit: BoxFit.cover,
              // Decode at tile size instead of full resolution.
              memCacheWidth: 600,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const MediaUnavailable(),
            ),
    );
  }
}
