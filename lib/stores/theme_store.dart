import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_store.g.dart';

class ThemeStore = ThemeStoreBase with _$ThemeStore;

/// Appearance settings, kept in SharedPreferences.
abstract class ThemeStoreBase with Store {
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;

  ThemeStoreBase() {
    _load();
  }

  @observable
  ThemeMode themeMode = ThemeMode.system;

  /// Size of message text.
  @observable
  double fontSize = 15.0;

  @action
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    (await SharedPreferences.getInstance()).setInt('themeMode', mode.index);
  }

  @action
  Future<void> setFontSize(double size) async {
    fontSize = size.clamp(minFontSize, maxFontSize);
    (await SharedPreferences.getInstance()).setDouble('fontSize', fontSize);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getInt('themeMode');
    final size = prefs.getDouble('fontSize');
    runInAction(() {
      if (mode != null && mode >= 0 && mode < ThemeMode.values.length) {
        themeMode = ThemeMode.values[mode];
      }
      if (size != null) fontSize = size.clamp(minFontSize, maxFontSize);
    });
  }
}
