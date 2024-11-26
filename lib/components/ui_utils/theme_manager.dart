import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static Future<ThemeMode> loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return ThemeMode
        .values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      fontFamily: 'JetBrainsMono',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'JetBrainsMono'),
        bodyMedium: TextStyle(fontFamily: 'JetBrainsMono'),
        titleLarge: TextStyle(fontFamily: 'JetBrainsMono'),
        titleMedium: TextStyle(fontFamily: 'JetBrainsMono'),
        titleSmall: TextStyle(fontFamily: 'JetBrainsMono'),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'JetBrainsMono',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'JetBrainsMono'),
        bodyMedium: TextStyle(fontFamily: 'JetBrainsMono'),
        titleLarge: TextStyle(fontFamily: 'JetBrainsMono'),
        titleMedium: TextStyle(fontFamily: 'JetBrainsMono'),
        titleSmall: TextStyle(fontFamily: 'JetBrainsMono'),
      ),
    );
  }

  static void showSettingsDialog(BuildContext context, ThemeMode currentMode,
      Function(ThemeMode) setThemeMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme Mode'),
              DropdownButton<ThemeMode>(
                value: currentMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    setThemeMode(newValue);
                    Navigator.of(context).pop();
                  }
                },
                items: ThemeMode.values.map((ThemeMode mode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Text(mode.toString().split('.').last),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
