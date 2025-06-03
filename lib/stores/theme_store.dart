import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Include the generated file
part 'theme_store.g.dart';

// This is the class used by rest of the codebase
class ThemeStore = ThemeStoreBase with _$ThemeStore;

// The store class
abstract class ThemeStoreBase with Store {
  // Font size constraints
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double fontSizeStep = 2.0;

  // Observable for theme mode
  @observable
  ThemeMode themeMode = ThemeMode.system;

  // Observable for font size
  @observable
  double fontSize = 16.0;

  // Constructor initializes from saved preferences
  ThemeStoreBase() {
    _loadPreferences();
  }

  // Action to set theme mode
  @action
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  // Action to set font size
  @action
  Future<void> setFontSize(double size) async {
    if (size >= minFontSize && size <= maxFontSize) {
      fontSize = size;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSize', size);
    }
  }

  // Action to increase font size
  @action
  Future<void> increaseFontSize() async {
    await setFontSize(fontSize + fontSizeStep);
  }

  // Action to decrease font size
  @action
  Future<void> decreaseFontSize() async {
    await setFontSize(fontSize - fontSizeStep);
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final savedThemeModeIndex = prefs.getInt('themeMode');
    if (savedThemeModeIndex != null &&
        savedThemeModeIndex >= 0 &&
        savedThemeModeIndex < ThemeMode.values.length) {
      themeMode = ThemeMode.values[savedThemeModeIndex];
    }

    // Load font size
    final savedFontSize = prefs.getDouble('fontSize');
    if (savedFontSize != null &&
        savedFontSize >= minFontSize &&
        savedFontSize <= maxFontSize) {
      fontSize = savedFontSize;
    }
  }

  // Get current theme data
  ThemeData getCurrentTheme() {
    return themeMode == ThemeMode.light
        ? AppColors.getLightTheme(fontSize)
        : AppColors.getDarkTheme(fontSize);
  }

  // Show settings dialog
  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Theme Mode', textAlign: TextAlign.center),
              DropdownButton<ThemeMode>(
                value: themeMode,
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
              const SizedBox(height: 16),
              const Text('Font Size', textAlign: TextAlign.center),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () async {
                      await decreaseFontSize();
                    },
                  ),
                  Text(fontSize.toStringAsFixed(1)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      await increaseFontSize();
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper class for app colors
class AppColors {
  // Background color - Darker than current Tokyo Night
  static const Color background = Color(0xFF121214);

  // Message bubbles
  static const Color authorBubble = Color(0xFF1E1E24);
  static const Color senderBubble = Color(0xFF2D2D3A);

  // Modern dark UI palette
  static const Color surface0 = Color(0xFF17171B);
  static const Color surface1 = Color(0xFF1E1E24);
  static const Color surface2 = Color(0xFF2D2D3A);
  static const Color blue = Color(0xFF5B9BF8);
  static const Color lavender = Color(0xFF9D7CD8);
  static const Color sapphire = Color(0xFF7DCFFF);
  static const Color sky = Color(0xFF7DCFFF);
  static const Color teal = Color(0xFF4DD0E1);
  static const Color green = Color(0xFF7AE582);
  static const Color yellow = Color(0xFFFFD166);
  static const Color peach = Color(0xFFFF9E64);
  static const Color maroon = Color(0xFFF76686);
  static const Color red = Color(0xFFF76686);
  static const Color mauve = Color(0xFFBB9AF7);
  static const Color pink = Color(0xFFF76686);
  static const Color flamingo = Color(0xFFF76686);
  static const Color rosewater = Color(0xFFF76686);
  static const Color text = Color(0xFFECECF4);
  static const Color subtext1 = Color(0xFFABABBC);

  // Video player specific colors
  static const Color videoOverlay = Color(0x42000000);
  static const Color videoControls = text;

  // Light theme with custom font size
  static ThemeData getLightTheme(double fontSize) {
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
        surfaceTint: Colors.white,
        onSurfaceVariant: Colors.black87,
        error: Color(0xFFCC3A30),
        onError: Colors.white,
      ),
      canvasColor: Colors.white,
      cardColor: Colors.white,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4A90A4),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'JetBrains Mono Nerd Font',
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.black87, fontSize: fontSize + 8),
        displayMedium: TextStyle(color: Colors.black87, fontSize: fontSize + 6),
        displaySmall: TextStyle(color: Colors.black87, fontSize: fontSize + 4),
        headlineLarge: TextStyle(color: Colors.black87, fontSize: fontSize + 3),
        headlineMedium:
            TextStyle(color: Colors.black87, fontSize: fontSize + 2),
        headlineSmall: TextStyle(color: Colors.black87, fontSize: fontSize + 1),
        titleLarge: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
          fontSize: fontSize + 2,
        ),
        titleMedium: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          fontSize: fontSize + 1,
        ),
        titleSmall: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          fontSize: fontSize,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          fontSize: fontSize,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: Colors.black87,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          fontSize: fontSize - 1,
        ),
        bodySmall: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: Colors.black54,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          fontSize: fontSize - 2,
        ),
        labelLarge: TextStyle(color: Colors.black87, fontSize: fontSize),
        labelMedium: TextStyle(color: Colors.black87, fontSize: fontSize - 1),
        labelSmall: TextStyle(color: Colors.black87, fontSize: fontSize - 2),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF4A90A4),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      dividerColor: Colors.grey[300],
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[100],
        filled: true,
        labelStyle: TextStyle(color: Colors.black87, fontSize: fontSize - 1),
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: fontSize - 1),
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

  // Dark theme with custom font size
  static ThemeData getDarkTheme(double fontSize) {
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
        surface: AppColors.surface0,
        onSurface: AppColors.text,
        surfaceTint: AppColors.background,
        onSurfaceVariant: AppColors.text,
        error: AppColors.red,
        onError: Colors.white,
        // Removed deprecated 'background' property as it's already defined as 'surface' above
        shadow: Colors.black,
      ),
      canvasColor: AppColors.background,
      cardColor: AppColors.surface0,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withValues(alpha: 60),
        elevation: 8.0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface0,
        foregroundColor: AppColors.text,
        iconTheme: IconThemeData(color: AppColors.text),
        elevation: 4.0,
        shadowColor: Colors.black.withValues(alpha: 60),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontFamily: 'JetBrains Mono Nerd Font',
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.text, fontSize: fontSize + 8),
        displayMedium: TextStyle(color: AppColors.text, fontSize: fontSize + 6),
        displaySmall: TextStyle(color: AppColors.text, fontSize: fontSize + 4),
        headlineLarge: TextStyle(color: AppColors.text, fontSize: fontSize + 3),
        headlineMedium:
            TextStyle(color: AppColors.text, fontSize: fontSize + 2),
        headlineSmall: TextStyle(color: AppColors.text, fontSize: fontSize + 1),
        titleLarge: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
          fontSize: fontSize + 2,
        ),
        titleMedium: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          fontSize: fontSize + 1,
        ),
        titleSmall: TextStyle(
          fontFamily: 'JetBrains Mono Nerd Font',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          fontSize: fontSize,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'CaskaydiaCoveNerdFontMono',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          fontSize: fontSize,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'CaskaydiaCoveNerdFontMono',
          color: AppColors.text,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          fontSize: fontSize - 1,
        ),
        bodySmall: TextStyle(
          fontFamily: 'CaskaydiaCoveNerdFontMono',
          color: AppColors.subtext1,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w300,
          fontSize: fontSize - 2,
        ),
        labelLarge: TextStyle(color: AppColors.text, fontSize: fontSize),
        labelMedium: TextStyle(color: AppColors.text, fontSize: fontSize - 1),
        labelSmall: TextStyle(color: AppColors.text, fontSize: fontSize - 2),
      ),
      iconTheme: IconThemeData(
        color: AppColors.text,
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: AppColors.surface0,
        surfaceTintColor: AppColors.surface0,
      ),
      dividerColor: AppColors.surface2,
      cardTheme: CardThemeData(
        color: AppColors.surface0,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 102),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.surface1,
        filled: true,
        labelStyle: TextStyle(color: AppColors.text, fontSize: fontSize - 1),
        hintStyle: TextStyle(color: AppColors.subtext1, fontSize: fontSize - 1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surface2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surface2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.text,
        iconColor: AppColors.blue,
        tileColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
