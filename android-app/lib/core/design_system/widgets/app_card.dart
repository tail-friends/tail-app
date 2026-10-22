import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import 'app_glass_surface.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    final surface = AppGlassSurface(
      borderRadius: radius,
      padding: padding,
      gradient: AppColors.glassSoftGradient,
      boxShadow: const [
        BoxShadow(
          color: Color(0x143D3329),
          offset: Offset(0, 12),
          blurRadius: 32,
        ),
      ],
      child: child,
    );

    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(borderRadius: radius, onTap: onTap, child: surface),
      ),
    );
  }
}
