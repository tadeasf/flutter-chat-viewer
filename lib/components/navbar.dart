import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchPressed;
  final VoidCallback onCollectionSelectorPressed;
  final bool isCollectionSelectorVisible;
  final String? selectedCollection;

  const Navbar({
    super.key,
    required this.title,
    required this.onSearchPressed,
    required this.onCollectionSelectorPressed,
    required this.isCollectionSelectorVisible,
    required this.selectedCollection,
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
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          IconButton(
            icon: Icon(isCollectionSelectorVisible
                ? Icons.view_list
                : Icons.view_list_outlined),
            onPressed: onCollectionSelectorPressed,
          ),
          IconButton(
            icon: const Icon(Icons.search),
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
