import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';
import 'app_glass_surface.dart';

class AppSpeechBubble extends StatelessWidget {
  const AppSpeechBubble({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(AppRadius.full),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143D3329),
            offset: Offset(0, 12),
            blurRadius: 32,
          ),
        ],
        child: Text(
          message,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textComponentPrimary,
          ),
        ),
      ),
    );
  }
}
