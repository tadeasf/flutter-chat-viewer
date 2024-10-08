import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchPressed;
  final VoidCallback onDatabasePressed;
  final VoidCallback onCollectionSelectorPressed;
  final bool isCollectionSelectorVisible;

  const Navbar({
    super.key,
    required this.title,
    required this.onSearchPressed,
    required this.onDatabasePressed,
    required this.onCollectionSelectorPressed,
    required this.isCollectionSelectorVisible,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: onSearchPressed,
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: onDatabasePressed,
          ),
        ],
      ),
    );
  }
}
