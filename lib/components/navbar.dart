import 'package:flutter/material.dart';
import '../components/ui_utils/visibility_state.dart';
import '../components/search/cross_collection_search.dart';

class Navbar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchPressed;
  final VoidCallback onCollectionSelectorPressed;
  final bool isCollectionSelectorVisible;
  final String? selectedCollection;
  final VisibilityState currentVisibility;
  final Function(List<Map<String, dynamic>>) onCrossCollectionSearch;

  const Navbar({
    super.key,
    required this.title,
    required this.onSearchPressed,
    required this.onCollectionSelectorPressed,
    required this.isCollectionSelectorVisible,
    required this.selectedCollection,
    required this.currentVisibility,
    required this.onCrossCollectionSearch,
  });

  void _showSearchOptions(BuildContext context, VoidCallback onSearchPressed) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'collection',
          child: ListTile(
            leading: const Icon(Icons.search),
            title:
                Text('Search in ${selectedCollection?.split('_').join(' ')}'),
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'cross',
          child: ListTile(
            leading: Icon(Icons.search_outlined),
            title: Text('Search All Collections'),
            dense: true,
          ),
        ),
      ],
    ).then((value) async {
      if (value == null) return;

      if (value == 'collection') {
        onSearchPressed();
      } else if (value == 'cross') {
        await Future.microtask(() {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return CrossCollectionSearchDialog(
                  onSearchResults: onCrossCollectionSearch,
                );
              },
            );
          }
        });
      }
    });
  }

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
          Builder(
            builder: (context) => IconButton(
              icon: Icon(currentVisibility == VisibilityState.search
                  ? Icons.search_off
                  : Icons.search),
              onPressed: hasCollection
                  ? () => _showSearchOptions(context, onSearchPressed)
                  : null,
              tooltip: hasCollection
                  ? 'Search options'
                  : 'Select a collection first',
            ),
          ),
        ],
      ),
    );
  }
}
