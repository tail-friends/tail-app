import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF4F2EE);
  static const surface = Color(0xFFFBFAF8);
  static const sunken = Color(0xFFECE9E3);
  static const primaryBackground = Color(0xFF1E1C1A);
  static const primarySoft = Color(0xFFEFE9DF);
  static const infoSoft = Color(0xFFE7ECEE);
  static const glass = Color(0x8CFFFFFF);
  static const glassStrong = Color(0xBFFFFFFF);

  static const textPrimary = Color(0xFF1E1C1A);
  static const textComponentPrimary = Color(0xFF3B3631);
  static const textSecondary = Color(0xFF8C857A);
  static const textTertiary = Color(0xFFABA498);
  static const textOnPrimary = Color(0xFFFBFAF8);
  static const textAccent = Color(0xFF8C7656);
  static const textSuccess = Color(0xFF66705A);
  static const textWarning = Color(0xFF93733D);
  static const textDanger = Color(0xFFB0705F);

  static const successSoft = Color(0xFFE8EAE3);
  static const warningSoft = Color(0xFFF4ECDD);
  static const dangerSoft = Color(0xFFF3E4DF);
  static const borderDefault = Color(0xFFDEDAD2);
  static const borderStrong = Color(0xFFABA498);
  static const borderGlass = Color(0xE6FFFFFF);
  static const iconPrimary = Color(0xFF34312D);
  static const iconMuted = Color(0xFFABA498);
  static const iconAccent = Color(0xFFB8A07A);

  static const socialApple = Color(0xFF3B3631);
  static const socialKakao = Color(0xFFFEE500);
  static const socialGoogle = Color(0xFFFFFFFF);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E5851), Color(0xFF403B36)],
  );

  static const glassStrongGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF0FFFFFF), Color(0xA3FFFFFF)],
  );

  static const glassSoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xC7FFFFFF), Color(0x66FFFFFF)],
  );

  static const ghostGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xB3FFFFFF), Color(0x59FFFFFF)],
  );

  static const mistScreenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.45, 0.8, 1],
    colors: [
      Color(0xFFF8F5F0),
      Color(0xFFF0EBE3),
      Color(0xFFE9E2D8),
      Color(0xFFE2DACE),
    ],
  );
}
