import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';

enum AppChipTone { success, warning, danger, accent, neutral }

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.tone = AppChipTone.neutral,
    super.key,
  });

  final String label;
  final AppChipTone tone;

  Color get _background => switch (tone) {
    AppChipTone.success => AppColors.successSoft,
    AppChipTone.warning => AppColors.warningSoft,
    AppChipTone.danger => AppColors.dangerSoft,
    AppChipTone.accent => AppColors.primarySoft,
    AppChipTone.neutral => AppColors.sunken,
  };

  Color get _foreground => switch (tone) {
    AppChipTone.success => AppColors.textSuccess,
    AppChipTone.warning => AppColors.textWarning,
    AppChipTone.danger => AppColors.textDanger,
    AppChipTone.accent => AppColors.textAccent,
    AppChipTone.neutral => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: AppTypography.captionRegular.copyWith(color: _foreground),
          ),
        ),
      ),
    );
  }
}
