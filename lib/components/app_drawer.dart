import 'package:flutter/material.dart';
import '../stores/store_provider.dart';
import './profile_photo/profile_photo.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class AppDrawer extends StatefulWidget {
  final String? selectedCollection;
  final bool isPhotoAvailable;
  final bool isProfilePhotoVisible;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Map<dynamic, dynamic>> messages;
  final ItemScrollController itemScrollController;
  final VoidCallback onDrawerClosed;
  final VoidCallback onFontSizeChanged;
  final String? profilePhotoUrl;

  const AppDrawer({
    super.key,
    this.selectedCollection,
    this.isPhotoAvailable = false,
    this.isProfilePhotoVisible = true,
    this.fromDate,
    this.toDate,
    required this.messages,
    required this.itemScrollController,
    required this.onDrawerClosed,
    required this.onFontSizeChanged,
    this.profilePhotoUrl,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? get selectedCollection => widget.selectedCollection;
  bool get isPhotoAvailable => widget.isPhotoAvailable;
  bool get isProfilePhotoVisible => widget.isProfilePhotoVisible;
  List<Map<dynamic, dynamic>> get messages => widget.messages;
  ItemScrollController get itemScrollController => widget.itemScrollController;
  VoidCallback get onDrawerClosed => widget.onDrawerClosed;
  VoidCallback get onFontSizeChanged => widget.onFontSizeChanged;
  String? get profilePhotoUrl => widget.profilePhotoUrl;

  bool get hasProfilePhoto =>
      profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty;

  Future<void> _handlePhotoAction(BuildContext context, bool isUpload) async {
    if (selectedCollection == null) return;

    // Store the context-dependent values before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final galleryStore = StoreProvider.of(context).galleryStore;
    final profileStore = StoreProvider.of(context).profilePhotoStore;
    final messageStore = StoreProvider.of(context).messageStore;
    final String currentCollection = selectedCollection!;

    try {
      if (isUpload) {
        // Upload photo using the gallery store
        final success =
            await galleryStore.uploadPhoto(context, currentCollection);

        if (!mounted) return;

        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')),
          );
        }
      } else {
        // Show confirmation dialog before deleting
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Delete Profile Photo?'),
              content: const Text(
                  'Are you sure you want to delete this profile photo?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );

        if (!mounted || confirmed != true) return;

        // Delete photo using the gallery store
        final result = await galleryStore.deletePhoto(currentCollection);

        if (!mounted) return;

        if (result['success']) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
          return; // Don't proceed with reload if delete failed
        }
      }

      // Clear cache and refresh after upload/delete
      if (!mounted) return;

      profileStore.clearCache(currentCollection);
      await profileStore.getProfilePhotoUrl(currentCollection);

      // Reload the collection to reflect changes
      if (!mounted) return;
      await messageStore.setCollection(currentCollection);

      if (!mounted) return;
      setState(() {
        // Update the state to reflect changes
      });
    } catch (e) {
      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              'Failed to ${isUpload ? 'upload' : 'delete'} photo. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStore = StoreProvider.of(context).themeStore;
    final photoStore = StoreProvider.of(context).photoStore;

    // Darker color for the drawer background
    final darkGreyColor = Color(0xFF121214);

    return Drawer(
      backgroundColor: darkGreyColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    selectedCollection ?? 'No Collection Selected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontFamily: 'JetBrains Mono Nerd Font',
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isProfilePhotoVisible && selectedCollection != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Center(
                          child: ProfilePhoto(
                            key: ValueKey(profilePhotoUrl),
                            collectionName: selectedCollection!,
                            size: 120.0,
                            isOnline: true,
                            profilePhotoUrl: profilePhotoUrl,
                            showButtons:
                                false, // Don't show buttons in ProfilePhoto
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasProfilePhoto)
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white70),
                                onPressed: () =>
                                    _handlePhotoAction(context, false),
                                tooltip: 'Delete Photo',
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.upload,
                                    color: Colors.white70),
                                onPressed: () =>
                                    _handlePhotoAction(context, true),
                                tooltip: 'Upload Photo',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library,
                            color: Colors.white70),
                        title: Text(
                          'Gallery',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'JetBrains Mono Nerd Font',
                                    color: Colors.white,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (selectedCollection != null) {
                            photoStore.showAllPhotos(
                              context,
                              selectedCollection,
                              messages: messages,
                              itemScrollController: itemScrollController,
                            );
                          }
                        },
                      ),
                      const Divider(color: Color(0xFF2D2D3A)),
                      ListTile(
                        leading:
                            const Icon(Icons.settings, color: Colors.white70),
                        title: Text(
                          'Settings',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'JetBrains Mono Nerd Font',
                                    color: Colors.white,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          themeStore.showSettingsDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
