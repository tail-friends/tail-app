import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';
import 'app_glass_surface.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);
    final foreground = variant == AppButtonVariant.primary
        ? AppColors.textOnPrimary
        : AppColors.textComponentPrimary;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Center(
        child: isLoading
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(color: foreground),
              ),
      ),
    );

    final decorated = switch (variant) {
      AppButtonVariant.primary => DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E14120F),
              offset: Offset(0, 8),
              blurRadius: 10,
            ),
          ],
        ),
        child: content,
      ),
      AppButtonVariant.secondary => AppGlassSurface(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x143D3329),
            offset: Offset(0, 12),
            blurRadius: 16,
          ),
        ],
        child: content,
      ),
      AppButtonVariant.ghost => AppGlassSurface(
        borderRadius: radius,
        gradient: AppColors.ghostGradient,
        child: content,
      ),
    };

    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: isLoading ? '$label, 처리 중' : label,
      child: AnimatedOpacity(
        opacity: _enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: _enabled ? onPressed : null,
            child: decorated,
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
