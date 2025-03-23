import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './gallery/photo_handler.dart';
import '../stores/store_provider.dart';
import './profile_photo/profile_photo.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class AppDrawer extends StatelessWidget {
  final String? selectedCollection;
  final bool isPhotoAvailable;
  final bool isProfilePhotoVisible;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? profilePhotoUrl;
  final Function refreshCollections;
  final Function setState;
  final Function fetchMessages;
  final void Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;
  final ImagePicker picker;
  final Function(List<dynamic>) onCrossCollectionSearch;
  final VoidCallback onDrawerClosed;
  final List<Map<dynamic, dynamic>> messages;
  final ItemScrollController itemScrollController;
  final VoidCallback onFontSizeChanged;

  const AppDrawer({
    super.key,
    required this.selectedCollection,
    required this.isPhotoAvailable,
    required this.isProfilePhotoVisible,
    required this.fromDate,
    required this.toDate,
    required this.profilePhotoUrl,
    required this.refreshCollections,
    required this.setState,
    required this.fetchMessages,
    required this.setThemeMode,
    required this.themeMode,
    required this.picker,
    required this.onCrossCollectionSearch,
    required this.onDrawerClosed,
    required this.messages,
    required this.itemScrollController,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeStore = StoreProvider.of(context).themeStore;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      onDrawerClosed();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    selectedCollection ?? 'No Collection Selected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                ),
                if (isProfilePhotoVisible && selectedCollection != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ProfilePhoto(
                      key: ValueKey(profilePhotoUrl), // Add this line
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
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text('Gallery',
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    PhotoHandler.handleShowAllPhotos(
                      context,
                      selectedCollection,
                      messages: messages,
                      itemScrollController: itemScrollController,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text('Settings',
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    themeStore.showSettingsDialog(context);
                  },
                ),
                const Divider(),
                Observer(
                  builder: (_) => ListTile(
                    leading: const Icon(Icons.format_size),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Text Size',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () async {
                            await themeStore.decreaseFontSize();
                            onFontSizeChanged();
                          },
                        ),
                        Text(
                          themeStore.fontSize.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () async {
                            await themeStore.increaseFontSize();
                            onFontSizeChanged();
                          },
                        ),
                      ],
                    ),
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
