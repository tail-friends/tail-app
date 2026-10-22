import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    required this.child,
    required this.borderRadius,
    this.padding,
    this.blur = 18,
    this.gradient = AppColors.glassStrongGradient,
    this.boxShadow = const [],
    this.borderColor = Colors.white,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Gradient gradient;
  final List<BoxShadow> boxShadow;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor),
            ),
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}
