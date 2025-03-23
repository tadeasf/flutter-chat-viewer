import 'package:flutter/material.dart';
import '../stores/store_provider.dart';
import './profile_photo/profile_photo.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

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
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text('Gallery',
                      style: Theme.of(context).textTheme.bodyMedium),
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
