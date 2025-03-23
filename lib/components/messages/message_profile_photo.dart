import 'package:flutter/material.dart';
import '../profile_photo/profile_photo.dart';

class MessageProfilePhoto extends StatelessWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final String? profilePhotoUrl;

  const MessageProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 40.0,
    this.isOnline = true,
    required this.profilePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ProfilePhoto(
        key: ValueKey(profilePhotoUrl),
        collectionName: collectionName,
        size: size,
        isOnline: isOnline,
        showButtons: false,
        profilePhotoUrl: profilePhotoUrl,
      ),
    );
  }
}
