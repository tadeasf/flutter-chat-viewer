import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/store_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// A widget that provides a UI for navigating between collections
class CollectionNavigator extends StatelessWidget {
  final Function(String)? onCollectionSelected;
  final ItemScrollController? itemScrollController;

  const CollectionNavigator({
    super.key,
    this.onCollectionSelected,
    this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final collectionStore = StoreProvider.of(context).collectionStore;
    final navigationStore = StoreProvider.of(context).navigationStore;

    return Observer(
      builder: (_) {
        if (collectionStore.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final collections = collectionStore.filteredCollections;

        if (collections.isEmpty) {
          return const Center(
            child: Text('No collections available'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Collections',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  collectionStore.setFilterQuery(value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  final collectionName =
                      collection['name'] as String? ?? 'Unknown';
                  final messageCount = collection['messageCount'] as int? ?? 0;

                  return ListTile(
                    title: Text(collectionName),
                    subtitle: Text('$messageCount messages'),
                    leading: const Icon(Icons.chat),
                    onTap: () async {
                      // Use NavigationStore to navigate to the selected collection
                      await navigationStore.navigateToCollection(
                        context,
                        collectionName,
                        popCurrent: true,
                      );

                      // Call the callback if provided
                      if (onCollectionSelected != null) {
                        onCollectionSelected!(collectionName);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A dialog that shows the CollectionNavigator
class CollectionNavigatorDialog extends StatelessWidget {
  final Function(String)? onCollectionSelected;
  final ItemScrollController? itemScrollController;

  const CollectionNavigatorDialog({
    super.key,
    this.onCollectionSelected,
    this.itemScrollController,
  });

  static Future<void> show(
    BuildContext context, {
    Function(String)? onCollectionSelected,
    ItemScrollController? itemScrollController,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => CollectionNavigatorDialog(
        onCollectionSelected: onCollectionSelected,
        itemScrollController: itemScrollController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Collection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: CollectionNavigator(
                onCollectionSelected: (collection) {
                  Navigator.of(context).pop();
                  if (onCollectionSelected != null) {
                    onCollectionSelected!(collection);
                  }
                },
                itemScrollController: itemScrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
