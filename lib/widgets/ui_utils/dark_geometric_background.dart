import 'package:flutter/material.dart';
import '../../components/ui_utils/geometric_background.dart';
import '../../stores/theme_store.dart';

/// A dark-themed wrapper for the GeometricBackground component
/// Used to apply a consistent dark theme with geometric pattern
class DarkGeometricBackground extends StatelessWidget {
  final Widget child;

  const DarkGeometricBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!isDarkMode) {
      // If not in dark mode, just render the child directly
      return child;
    }

    return GeometricBackground(
      backgroundColor: AppColors.background,
      patternColor: AppColors.surface1,
      patternOpacity: 0.05,
      patternDensity: 20,
      child: child,
    );
  }
}
