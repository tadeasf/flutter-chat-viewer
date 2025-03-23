import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PhotoDetails extends StatelessWidget {
  final Map<String, dynamic> photo;
  final VoidCallback? onClose;

  const PhotoDetails({
    super.key,
    required this.photo,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse timestamp
    final timestamp = photo['creation_timestamp'];
    String date = 'Unknown date';

    if (timestamp != null) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
        date = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
      } catch (e) {
        date = 'Invalid date';
      }
    }

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 230),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photo Details',
                style: theme.textTheme.titleLarge,
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
            ],
          ),
          const Divider(),
          _buildInfoRow(context, 'Created', date),
          if (photo['width'] != null && photo['height'] != null)
            _buildInfoRow(context, 'Dimensions',
                '${photo['width']} × ${photo['height']}'),
          if (photo['uri'] != null)
            _buildInfoRow(
                context, 'Filename', _getFilenameFromUri(photo['uri'])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilenameFromUri(String uri) {
    return uri.split('/').last;
  }
}
