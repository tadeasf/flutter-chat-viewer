import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that renders a subtle geometric pattern background
class GeometricBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color patternColor;
  final double patternOpacity;
  final int patternDensity;

  const GeometricBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF0A1929),
    this.patternColor = const Color(0xFF132F4C),
    this.patternOpacity = 0.2,
    this.patternDensity = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base color layer
        Container(
          decoration: BoxDecoration(
            // Create a gradient background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                Color.lerp(backgroundColor, patternColor, 0.15) ??
                    backgroundColor,
              ],
            ),
          ),
        ),

        // Geometric pattern layer
        CustomPaint(
          painter: GeometricPatternPainter(
            patternColor:
                patternColor.withAlpha((255 * patternOpacity).round()),
            density: patternDensity,
          ),
          size: Size.infinite,
        ),

        // Subtle vignette effect
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                backgroundColor.withAlpha(51), // 0.2 alpha (51/255)
              ],
              stops: const [0.6, 1.0],
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

/// Custom painter for drawing geometric patterns
class GeometricPatternPainter extends CustomPainter {
  final Color patternColor;
  final int density;
  final math.Random random =
      math.Random(42); // Fixed seed for consistent pattern

  GeometricPatternPainter({
    required this.patternColor,
    required this.density,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double cellWidth = size.width / density;
    final double cellHeight = size.height / density;

    // Draw subtle dot grid
    for (int i = 0; i <= density; i++) {
      for (int j = 0; j <= density; j++) {
        final double x = cellWidth * i;
        final double y = cellHeight * j;

        // Small dots at grid intersections
        canvas.drawCircle(Offset(x, y), 1.0, paint..style = PaintingStyle.fill);

        // Randomly draw connecting lines with varying transparency
        if (random.nextDouble() < 0.15) {
          final nextX = x + cellWidth;
          final nextY = y + cellHeight;

          // Horizontal lines
          if (i < density && random.nextBool()) {
            canvas.drawLine(
                Offset(x, y),
                Offset(nextX, y),
                paint
                  ..style = PaintingStyle.stroke
                  ..color = patternColor.withAlpha(
                      (26 + random.nextDouble() * 38)
                          .round())); // 0.1-0.25 alpha
          }

          // Vertical lines
          if (j < density && random.nextBool()) {
            canvas.drawLine(
                Offset(x, y),
                Offset(x, nextY),
                paint
                  ..style = PaintingStyle.stroke
                  ..color = patternColor.withAlpha(
                      (26 + random.nextDouble() * 38)
                          .round())); // 0.1-0.25 alpha
          }

          // Diagonal lines (rarer)
          if (i < density && j < density && random.nextDouble() < 0.1) {
            canvas.drawLine(
                Offset(x, y),
                Offset(nextX, nextY),
                paint
                  ..style = PaintingStyle.stroke
                  ..color = patternColor.withAlpha(
                      (13 + random.nextDouble() * 25)
                          .round())); // 0.05-0.15 alpha
          }
        }

        // Occasional subtle geometric shapes
        if (random.nextDouble() < 0.03) {
          final double size = 4 + random.nextDouble() * 12;

          // Draw a subtle square
          canvas.drawRect(
              Rect.fromCenter(center: Offset(x, y), width: size, height: size),
              paint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5
                ..color = patternColor.withAlpha(20)); // 0.08 alpha
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
