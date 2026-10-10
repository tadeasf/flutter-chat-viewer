import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../stores/store_provider.dart';
import '../stores/theme_store.dart';
import '../theme.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = StoreProvider.of(context).themeStore;
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 360,
        child: Observer(
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: theme.textTheme.labelLarge),
              const SizedBox(height: Space.s),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {store.themeMode},
                onSelectionChanged: (s) => store.setThemeMode(s.first),
              ),
              const SizedBox(height: Space.xl),
              Text('Message text size: ${store.fontSize.round()}',
                  style: theme.textTheme.labelLarge),
              Slider(
                min: ThemeStoreBase.minFontSize,
                max: ThemeStoreBase.maxFontSize,
                divisions:
                    (ThemeStoreBase.maxFontSize - ThemeStoreBase.minFontSize)
                        .round(),
                value: store.fontSize,
                onChanged: store.setFontSize,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
