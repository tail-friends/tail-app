import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const fontFamily = 'Gowun Dodum';

  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
  );
  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    height: 26 / 19,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
  );
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
  );
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
  static const bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const captionRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
  );
  static const numberLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w400,
  );
  static const wordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w400,
  );
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
  );
}
