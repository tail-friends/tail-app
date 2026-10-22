import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_glass_surface.dart';

class AppRecordRow extends StatelessWidget {
  const AppRecordRow({
    required this.title,
    required this.meta,
    required this.trailing,
    this.icon,
    this.onTap,
    super.key,
  });

  final String title;
  final String meta;
  final String trailing;
  final Widget? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 34,
              child: AppGlassSurface(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Center(
                  child:
                      icon ??
                      ExcludeSemantics(
                        child: SvgPicture.asset(
                          'assets/icons/record_feed.svg',
                          width: 16,
                          height: 16,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyRegular.copyWith(
                      color: AppColors.textComponentPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionRegular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Text(
              trailing,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: '$title, $meta, $trailing',
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
