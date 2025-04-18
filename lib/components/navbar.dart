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

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: isDarkMode ? Color(0xFF1E1E24) : theme.colorScheme.surface,
      items: [
        PopupMenuItem<String>(
          value: 'collection',
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color:
                      isDarkMode ? Colors.white70 : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search in ${selectedCollection?.split('_').join(' ')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'JetBrains Mono Nerd Font',
                    color: isDarkMode
                        ? Colors.white70
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'cross',
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search_outlined,
                  size: 20,
                  color:
                      isDarkMode ? Colors.white70 : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search All Collections',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'JetBrains Mono Nerd Font',
                    color: isDarkMode
                        ? Colors.white70
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
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

    // Darker color for navbar
    final darkNavbarColor = Color(0xFF121214);

    return BottomAppBar(
      elevation: 8.0,
      color: darkNavbarColor,
      shape: const AutomaticNotchedShape(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
                currentVisibility == VisibilityState.drawer
                    ? Icons.menu_open
                    : Icons.menu,
                color: Colors.white70),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          IconButton(
            icon: Icon(
                currentVisibility == VisibilityState.collectionSelector
                    ? Icons.view_list
                    : Icons.view_list_outlined,
                color: Colors.white70),
            onPressed: onCollectionSelectorPressed,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                  currentVisibility == VisibilityState.search
                      ? Icons.search_off
                      : Icons.search,
                  color: Colors.white70),
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
