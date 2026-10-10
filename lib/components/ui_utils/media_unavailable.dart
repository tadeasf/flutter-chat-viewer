import 'package:flutter/material.dart';

/// Shown instead of a photo that cannot be loaded (for example an old
/// Facebook CDN link stored in the message, which has expired).
class MediaUnavailable extends StatelessWidget {
  final double? width;
  final double? height;

  const MediaUnavailable({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text('Unavailable',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
