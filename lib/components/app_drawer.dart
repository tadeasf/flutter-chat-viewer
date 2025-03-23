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
              crossAxisAlignment: CrossAxisAlignment.center, // Center content
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
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
                if (isProfilePhotoVisible && selectedCollection != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      // Center the profile photo
                      child: ProfilePhoto(
                        key: ValueKey(profilePhotoUrl),
                        collectionName: selectedCollection!,
                        size: 120.0,
                        isOnline: true,
                        profilePhotoUrl: profilePhotoUrl,
                        showButtons: true,
                        onPhotoDeleted: () {
                          // Add this callback
                          setState(() {
                            // Update the state to reflect the deleted photo
                          });
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E24), // Slightly lighter background
                    borderRadius: BorderRadius.circular(16), // Rounded corners
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
                          // Use the PhotoStore to handle gallery navigation
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
                // Removed Text Size section as it's in settings
              ],
            ),
          ),
        ),
      ),
    );
  }
}
