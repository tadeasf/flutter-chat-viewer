import 'package:flutter/material.dart';
import '../components/ui_utils/visibility_state.dart';

class Navbar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchPressed;
  final VoidCallback onCollectionSelectorPressed;
  final bool isCollectionSelectorVisible;
  final String? selectedCollection;
  final VisibilityState currentVisibility;

  const Navbar({
    super.key,
    required this.title,
    required this.onSearchPressed,
    required this.onCollectionSelectorPressed,
    required this.isCollectionSelectorVisible,
    required this.selectedCollection,
    required this.currentVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCollection =
        selectedCollection != null && selectedCollection!.isNotEmpty;

    return BottomAppBar(
      elevation: 8.0,
      color: Theme.of(context).primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(currentVisibility == VisibilityState.drawer
                ? Icons.menu_open
                : Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          IconButton(
            icon: Icon(currentVisibility == VisibilityState.collectionSelector
                ? Icons.view_list
                : Icons.view_list_outlined),
            onPressed: onCollectionSelectorPressed,
          ),
          IconButton(
            icon: Icon(currentVisibility == VisibilityState.search
                ? Icons.search_off
                : Icons.search),
            onPressed: hasCollection ? onSearchPressed : null,
            tooltip: hasCollection
                ? 'Search in ${selectedCollection!.split('_').join(' ')}'
                : 'Select a collection first',
          ),
        ],
      ),
    );
  }
}
