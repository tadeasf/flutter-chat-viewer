import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  // Add background color
  static const Color background = Color(0xFF1E1E2E);

  // Video player specific colors
  static const Color videoOverlay = Color(0x42000000);
  static const Color videoControls = text;

  // Darker and less vibrant Catppuccin Mocha inspired colors
  static const Color base = Color(0xFF0D0D0D);
  static const Color surface0 = Color(0xFF1A1A1A);
  static const Color surface1 = Color(0xFF262626);
  static const Color surface2 = Color(0xFF333333);
  static const Color blue = Color(0xFF4A90A4);
  static const Color lavender = Color(0xFF6A6A75);
  static const Color sapphire = Color(0xFF005B99);
  static const Color sky = Color(0xFF4A90A4);
  static const Color teal = Color(0xFF3A8C7E);
  static const Color green = Color(0xFF2A8C59);
  static const Color yellow = Color(0xFFCCAA00);
  static const Color peach = Color(0xFFCC7A00);
  static const Color maroon = Color(0xFFCC3A30);
  static const Color red = Color(0xFFCC2D55);
  static const Color mauve = Color(0xFF8A52CC);
  static const Color pink = Color(0xFFCC2D55);
  static const Color flamingo = Color(0xFFCC3A30);
  static const Color rosewater = Color(0xFFCC2D55);
  static const Color text = Color(0xFFE5E5EA);
  static const Color subtext1 = Color(0xFF8E8E93);
}

class ThemeManager {
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double fontSizeStep = 2.0;
  static double _fontSize = 16.0; // Default size

  static double get fontSize => _fontSize;

  static Future<void> initFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
  }

  static Future<void> setFontSize(double size) async {
    if (size >= minFontSize && size <= maxFontSize) {
      _fontSize = size;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSize', size);
    }
  }

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
        bodyLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        titleLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        titleMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        titleSmall: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'JetBrainsMono',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        titleLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        titleMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        titleSmall: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
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
