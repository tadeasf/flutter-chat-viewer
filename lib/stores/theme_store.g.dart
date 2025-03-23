// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ThemeStore on ThemeStoreBase, Store {
  late final _$themeModeAtom =
      Atom(name: 'ThemeStoreBase.themeMode', context: context);

  @override
  ThemeMode get themeMode {
    _$themeModeAtom.reportRead();
    return super.themeMode;
  }

  @override
  set themeMode(ThemeMode value) {
    _$themeModeAtom.reportWrite(value, super.themeMode, () {
      super.themeMode = value;
    });
  }

  late final _$fontSizeAtom =
      Atom(name: 'ThemeStoreBase.fontSize', context: context);

  @override
  double get fontSize {
    _$fontSizeAtom.reportRead();
    return super.fontSize;
  }

  @override
  set fontSize(double value) {
    _$fontSizeAtom.reportWrite(value, super.fontSize, () {
      super.fontSize = value;
    });
  }

  late final _$setThemeModeAsyncAction =
      AsyncAction('ThemeStoreBase.setThemeMode', context: context);

  @override
  Future<void> setThemeMode(ThemeMode mode) {
    return _$setThemeModeAsyncAction.run(() => super.setThemeMode(mode));
  }

  late final _$setFontSizeAsyncAction =
      AsyncAction('ThemeStoreBase.setFontSize', context: context);

  @override
  Future<void> setFontSize(double size) {
    return _$setFontSizeAsyncAction.run(() => super.setFontSize(size));
  }

  late final _$increaseFontSizeAsyncAction =
      AsyncAction('ThemeStoreBase.increaseFontSize', context: context);

  @override
  Future<void> increaseFontSize() {
    return _$increaseFontSizeAsyncAction.run(() => super.increaseFontSize());
  }

  late final _$decreaseFontSizeAsyncAction =
      AsyncAction('ThemeStoreBase.decreaseFontSize', context: context);

  @override
  Future<void> decreaseFontSize() {
    return _$decreaseFontSizeAsyncAction.run(() => super.decreaseFontSize());
  }

  @override
  String toString() {
    return '''
themeMode: ${themeMode},
fontSize: ${fontSize}
    ''';
  }
}
