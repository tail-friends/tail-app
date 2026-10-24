import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';

void main() {
  final tokenFile = File('../shared/design-tokens.json');
  final document =
      jsonDecode(tokenFile.readAsStringSync()) as Map<String, dynamic>;

  dynamic nodeAt(String path) {
    dynamic node = document;
    for (final segment in path.split('.')) {
      node = (node as Map<String, dynamic>)[segment];
    }
    return node;
  }

  dynamic resolvedValue(String path) {
    final node = nodeAt(path) as Map<String, dynamic>;
    final value = node[r'$value'];
    if (value is String && value.startsWith('{') && value.endsWith('}')) {
      return resolvedValue(value.substring(1, value.length - 1));
    }
    return value;
  }

  int colorValue(String path) {
    final hex = (resolvedValue(path) as String).substring(1);
    if (hex.length == 6) return int.parse('FF$hex', radix: 16);
    final rgb = hex.substring(0, 6);
    final alpha = hex.substring(6, 8);
    return int.parse('$alpha$rgb', radix: 16);
  }

  double dimensionValue(String path) {
    final value = resolvedValue(path) as Map<String, dynamic>;
    expect(value['unit'], 'px', reason: path);
    return (value['value'] as num).toDouble();
  }

  group('shared/design-tokens.json ↔ Flutter', () {
    test('semantic과 component 색상이 AppColors와 일치한다', () {
      final colors = <String, Color>{
        'tail.color.bg.canvas': AppColors.canvas,
        'tail.color.bg.surface': AppColors.surface,
        'tail.color.bg.sunken': AppColors.sunken,
        'tail.color.bg.primary': AppColors.primaryBackground,
        'tail.color.bg.primary-soft': AppColors.primarySoft,
        'tail.color.bg.success-soft': AppColors.successSoft,
        'tail.color.bg.warning-soft': AppColors.warningSoft,
        'tail.color.bg.danger-soft': AppColors.dangerSoft,
        'tail.color.bg.info-soft': AppColors.infoSoft,
        'tail.color.bg.glass': AppColors.glass,
        'tail.color.bg.glass-strong': AppColors.glassStrong,
        'tail.color.text.primary': AppColors.textPrimary,
        'tail.color.text.secondary': AppColors.textSecondary,
        'tail.color.text.tertiary': AppColors.textTertiary,
        'tail.color.text.on-primary': AppColors.textOnPrimary,
        'tail.color.text.accent': AppColors.textAccent,
        'tail.color.text.success': AppColors.textSuccess,
        'tail.color.text.warning': AppColors.textWarning,
        'tail.color.text.danger': AppColors.textDanger,
        'tail.color.border.default': AppColors.borderDefault,
        'tail.color.border.strong': AppColors.borderStrong,
        'tail.color.border.glass': AppColors.borderGlass,
        'tail.color.icon.primary': AppColors.iconPrimary,
        'tail.color.icon.muted': AppColors.iconMuted,
        'tail.color.icon.accent': AppColors.iconAccent,
        'tail.component.color.textPrimary': AppColors.textComponentPrimary,
        'tail.component.color.primaryGradientStart':
            AppColors.primaryGradient.colors.first,
        'tail.component.color.primaryGradientEnd':
            AppColors.primaryGradient.colors.last,
        'tail.component.color.glassStrongStart':
            AppColors.glassStrongGradient.colors.first,
        'tail.component.color.glassStrongEnd':
            AppColors.glassStrongGradient.colors.last,
        'tail.component.color.glassSoftStart':
            AppColors.glassSoftGradient.colors.first,
        'tail.component.color.glassSoftEnd':
            AppColors.glassSoftGradient.colors.last,
        'tail.component.color.ghostStart': AppColors.ghostGradient.colors.first,
        'tail.component.color.ghostEnd': AppColors.ghostGradient.colors.last,
        'tail.component.color.mistTop': AppColors.mistScreenGradient.colors[0],
        'tail.component.color.mistUpper':
            AppColors.mistScreenGradient.colors[1],
        'tail.component.color.mistLower':
            AppColors.mistScreenGradient.colors[2],
        'tail.component.color.mistBottom':
            AppColors.mistScreenGradient.colors[3],
        'tail.component.color.socialApple': AppColors.socialApple,
        'tail.component.color.socialKakao': AppColors.socialKakao,
        'tail.component.color.socialGoogle': AppColors.socialGoogle,
      };

      for (final entry in colors.entries) {
        expect(
          entry.value.toARGB32(),
          colorValue(entry.key),
          reason: entry.key,
        );
      }
    });

    test('spacing과 radius가 Flutter 상수와 일치한다', () {
      final dimensions = <String, double>{
        'tail.dimension.space.4': AppSpacing.x1,
        'tail.dimension.space.8': AppSpacing.x2,
        'tail.dimension.space.12': AppSpacing.x3,
        'tail.dimension.space.16': AppSpacing.x4,
        'tail.dimension.space.20': AppSpacing.x5,
        'tail.dimension.space.24': AppSpacing.x6,
        'tail.dimension.space.32': AppSpacing.x8,
        'tail.dimension.space.40': AppSpacing.x10,
        'tail.dimension.radius.sm': AppRadius.sm,
        'tail.dimension.radius.md': AppRadius.md,
        'tail.dimension.radius.lg': AppRadius.lg,
        'tail.dimension.radius.xl': AppRadius.xl,
        'tail.dimension.radius.full': AppRadius.full,
      };

      for (final entry in dimensions.entries) {
        expect(dimensionValue(entry.key), entry.value, reason: entry.key);
      }
    });

    test('typography가 Flutter TextStyle과 일치한다', () {
      final styles = <String, TextStyle>{
        'displayLarge': AppTypography.displayLarge,
        'displayMedium': AppTypography.displayMedium,
        'titleLarge': AppTypography.titleLarge,
        'titleMedium': AppTypography.titleMedium,
        'bodyStrong': AppTypography.bodyStrong,
        'bodyRegular': AppTypography.bodyRegular,
        'labelMedium': AppTypography.labelMedium,
        'captionRegular': AppTypography.captionRegular,
        'numberLarge': AppTypography.numberLarge,
        'wordmark': AppTypography.wordmark,
        'overline': AppTypography.overline,
      };

      expect(
        resolvedValue('tail.typography.fontFamily'),
        AppTypography.fontFamily,
      );
      for (final entry in styles.entries) {
        final token =
            resolvedValue('tail.typography.${entry.key}')
                as Map<String, dynamic>;
        final style = entry.value;
        expect(token['fontFamily'], style.fontFamily, reason: entry.key);
        expect(token['fontWeight'], style.fontWeight?.value, reason: entry.key);
        expect(
          (token['fontSize'] as Map<String, dynamic>)['value'],
          style.fontSize,
          reason: entry.key,
        );
        expect(
          (token['lineHeight'] as Map<String, dynamic>)['value'],
          closeTo(style.fontSize! * style.height!, 0.001),
          reason: entry.key,
        );
      }
    });
  });
}
