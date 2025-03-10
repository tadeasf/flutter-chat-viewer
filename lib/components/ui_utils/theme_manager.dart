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
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'JetBrainsMono',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A90A4),
        onPrimary: Colors.white,
        secondary: Color(0xFF3A8C7E),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: Colors.white,
        onBackground: Colors.black87,
        error: Color(0xFFCC3A30),
        onError: Colors.white,
      ),
      canvasColor: Colors.white,
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4A90A4),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black87),
        displayMedium: TextStyle(color: Colors.black87),
        displaySmall: TextStyle(color: Colors.black87),
        headlineLarge: TextStyle(color: Colors.black87),
        headlineMedium: TextStyle(color: Colors.black87),
        headlineSmall: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        titleSmall: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        bodySmall: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: Colors.black54,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        labelLarge: TextStyle(color: Colors.black87),
        labelMedium: TextStyle(color: Colors.black87),
        labelSmall: TextStyle(color: Colors.black87),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF4A90A4),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      dividerColor: Colors.grey[300],
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[100],
        filled: true,
        labelStyle: const TextStyle(color: Colors.black87),
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A90A4), width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.black87,
        iconColor: Color(0xFF4A90A4),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'JetBrainsMono',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        secondary: AppColors.mauve,
        onSecondary: Colors.white,
        surface: const Color(0xFF202020),
        onSurface: AppColors.text,
        background: AppColors.background,
        onBackground: AppColors.text,
        error: AppColors.red,
        onError: Colors.white,
      ),
      canvasColor: AppColors.background,
      cardColor: const Color(0xFF252525),
      dialogBackgroundColor: AppColors.surface1,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF181818),
        foregroundColor: AppColors.text,
        iconTheme: IconThemeData(color: AppColors.text),
        elevation: 4.0,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontFamily: 'CaskaydiaCove Nerd Font',
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.text),
        displayMedium: TextStyle(color: AppColors.text),
        displaySmall: TextStyle(color: AppColors.text),
        headlineLarge: TextStyle(color: AppColors.text),
        headlineMedium: TextStyle(color: AppColors.text),
        headlineSmall: TextStyle(color: AppColors.text),
        titleLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        titleSmall: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        bodySmall: TextStyle(
          fontFamily: 'CaskaydiaCove Nerd Font',
          color: AppColors.subtext1,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        labelLarge: TextStyle(color: AppColors.text),
        labelMedium: TextStyle(color: AppColors.text),
        labelSmall: TextStyle(color: AppColors.text),
      ),
      iconTheme: IconThemeData(
        color: AppColors.text,
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: const Color(0xFF181818),
        surfaceTintColor: const Color(0xFF181818),
      ),
      dividerColor: AppColors.surface2,
      cardTheme: CardTheme(
        color: const Color(0xFF252525),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF222222),
        filled: true,
        labelStyle: TextStyle(color: AppColors.text),
        hintStyle: TextStyle(color: AppColors.subtext1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.surface2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.surface2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.text,
        iconColor: AppColors.blue,
        tileColor: const Color(0xFF222222),
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
