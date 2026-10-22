import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum AppSocialProvider { apple, kakao, google }

class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    required this.provider,
    required this.onPressed,
    super.key,
  });

  final AppSocialProvider provider;
  final VoidCallback? onPressed;

  String get _label => switch (provider) {
    AppSocialProvider.apple => 'Apple로 계속하기',
    AppSocialProvider.kakao => '카카오로 계속하기',
    AppSocialProvider.google => 'Google로 계속하기',
  };

  String get _asset => switch (provider) {
    AppSocialProvider.apple => 'assets/icons/social_apple.svg',
    AppSocialProvider.kakao => 'assets/icons/social_kakao.svg',
    AppSocialProvider.google => 'assets/icons/social_google.svg',
  };

  Color get _background => switch (provider) {
    AppSocialProvider.apple => AppColors.socialApple,
    AppSocialProvider.kakao => AppColors.socialKakao,
    AppSocialProvider.google => AppColors.socialGoogle,
  };

  Color get _foreground => provider == AppSocialProvider.apple
      ? Colors.white
      : AppColors.textComponentPrimary;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: _label,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.4 : 1,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: _background,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: provider == AppSocialProvider.google
                ? const BorderSide(color: AppColors.borderDefault)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x4,
                  vertical: AppSpacing.x3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: SvgPicture.asset(_asset, width: 18, height: 18),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Flexible(
                      child: Text(
                        _label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: _foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
