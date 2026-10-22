import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_glass_surface.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.semanticHint,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final bool enabled;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? semanticHint;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? AppColors.textDanger
        : _focusNode.hasFocus
        ? AppColors.borderStrong
        : Colors.white;

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.label,
      hint: widget.semanticHint ?? widget.hintText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.isRequired) ...[
                const SizedBox(width: 3),
                Text(
                  '필수',
                  style: AppTypography.captionRegular.copyWith(
                    color: AppColors.textDanger,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.5,
            duration: const Duration(milliseconds: 150),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderColor: borderColor,
                    child: const SizedBox.expand(),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: widget.maxLines > 1 ? 84 : 48,
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLength: widget.maxLength,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    style: AppTypography.bodyRegular.copyWith(
                      color: AppColors.textComponentPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.x4,
                        vertical: widget.maxLines > 1 ? 14 : 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: AppSpacing.x1),
            Text(
              widget.errorText!,
              style: AppTypography.captionRegular.copyWith(
                color: AppColors.textDanger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
