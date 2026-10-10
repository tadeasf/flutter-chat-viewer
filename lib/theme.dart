import 'package:flutter/material.dart';

/// Spacing scale (logical pixels).
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Corner radii.
abstract final class Radii {
  static const s = 6.0;
  static const m = 10.0;
  static const bubble = 18.0;
}

const _seed = Color(0xFF2E6F76);
const sansFamily = 'IBM Plex Sans';
const monoFamily = 'IBM Plex Mono';

/// Width below which only one pane is shown.
const twoPaneBreakpoint = 720.0;
const sidebarWidth = 320.0;
const maxBubbleWidth = 520.0;

/// Colours that Material's scheme has no role for.
@immutable
class ChatColors extends ThemeExtension<ChatColors> {
  final Color mine;
  final Color onMine;
  final Color theirs;
  final Color onTheirs;
  final Color highlight;

  const ChatColors({
    required this.mine,
    required this.onMine,
    required this.theirs,
    required this.onTheirs,
    required this.highlight,
  });

  static ChatColors of(BuildContext context) =>
      Theme.of(context).extension<ChatColors>()!;

  @override
  ChatColors copyWith() => this;

  @override
  ChatColors lerp(ChatColors? other, double t) {
    if (other == null) return this;
    return ChatColors(
      mine: Color.lerp(mine, other.mine, t)!,
      onMine: Color.lerp(onMine, other.onMine, t)!,
      theirs: Color.lerp(theirs, other.theirs, t)!,
      onTheirs: Color.lerp(onTheirs, other.onTheirs, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

/// Monospaced style for dates, counts and durations.
TextStyle monoStyle(BuildContext context, {double size = 11, Color? color}) =>
    TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final dark = brightness == Brightness.dark;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: sansFamily,
    visualDensity: VisualDensity.compact,
  );

  // IBM Plex Sans is a variable font: weights are applied as variations.
  TextStyle? w(TextStyle? s, int weight) => s?.copyWith(
        fontWeight: FontWeight.values[weight ~/ 100 - 1],
        fontVariations: [FontVariation.weight(weight.toDouble())],
      );
  final t = base.textTheme;
  final textTheme = t.copyWith(
    titleLarge: w(t.titleLarge?.copyWith(fontSize: 20), 600),
    titleMedium: w(t.titleMedium?.copyWith(fontSize: 16), 600),
    titleSmall: w(t.titleSmall?.copyWith(fontSize: 14), 500),
    bodyLarge: w(t.bodyLarge?.copyWith(fontSize: 15, height: 1.4), 400),
    bodyMedium: w(t.bodyMedium?.copyWith(fontSize: 14, height: 1.4), 400),
    bodySmall: w(t.bodySmall?.copyWith(fontSize: 12), 400),
    labelLarge: w(t.labelLarge?.copyWith(fontSize: 14), 500),
    labelMedium: w(t.labelMedium?.copyWith(fontSize: 12), 500),
    labelSmall: w(t.labelSmall?.copyWith(fontSize: 11), 500),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(true),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(4),
      thumbColor: WidgetStatePropertyAll(scheme.outline.withAlpha(140)),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(Radii.s),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Space.m, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.m))),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.m)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.bubble)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
    extensions: [
      ChatColors(
        mine: dark ? const Color(0xFF1F5A60) : scheme.primary,
        onMine: dark ? const Color(0xFFDFF7FA) : scheme.onPrimary,
        theirs: scheme.surfaceContainerHigh,
        onTheirs: scheme.onSurface,
        highlight: dark ? const Color(0xFF6B5300) : const Color(0xFFFFE08A),
      ),
    ],
  );
}
