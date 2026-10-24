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
    this.showCounter = false,
    this.maxLines = 1,
    this.minHeight,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.semanticHint,
    this.textStyle,
    this.labelStyle,
    this.requiredStyle,
    this.counterStyle,
    this.contentPadding,
    this.suffixText,
    this.suffixStyle,
    super.key,
  }) : assert(!showCounter || maxLength != null);

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final bool enabled;
  final int? maxLength;
  final bool showCounter;
  final int maxLines;
  final double? minHeight;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? semanticHint;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? requiredStyle;
  final TextStyle? counterStyle;
  final EdgeInsetsGeometry? contentPadding;
  final String? suffixText;
  final TextStyle? suffixStyle;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  late int _currentLength;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _currentLength = widget.controller?.text.characters.length ?? 0;
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.removeListener(_handleControllerChanged);
    widget.controller?.addListener(_handleControllerChanged);
    _currentLength = widget.controller?.text.characters.length ?? 0;
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  void _handleControllerChanged() {
    final length = widget.controller?.text.characters.length ?? 0;
    if (length != _currentLength) setState(() => _currentLength = length);
  }

  void _handleChanged(String value) {
    if (widget.controller == null) {
      setState(() => _currentLength = value.characters.length);
    }
    widget.onChanged?.call(value);
  }

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
                style:
                    widget.labelStyle ??
                    AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (widget.isRequired) ...[
                const SizedBox(width: 3),
                Text(
                  '필수',
                  style:
                      widget.requiredStyle ??
                      AppTypography.captionRegular.copyWith(
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
                    minHeight:
                        widget.minHeight ?? (widget.maxLines > 1 ? 84 : 48),
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLength: widget.maxLength,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    onChanged: _handleChanged,
                    style:
                        widget.textStyle ??
                        AppTypography.bodyRegular.copyWith(
                          color: AppColors.textComponentPrimary,
                        ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      counterText: '',
                      contentPadding:
                          widget.contentPadding ??
                          EdgeInsets.symmetric(
                            horizontal: AppSpacing.x4,
                            vertical: widget.maxLines > 1 ? 14 : 12,
                          ),
                      suffixText: widget.suffixText,
                      suffixStyle: widget.suffixStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.errorText != null || widget.showCounter) ...[
            const SizedBox(height: AppSpacing.x1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: widget.errorText == null
                      ? const SizedBox.shrink()
                      : Text(
                          widget.errorText!,
                          style: AppTypography.captionRegular.copyWith(
                            color: AppColors.textDanger,
                          ),
                        ),
                ),
                if (widget.showCounter)
                  Semantics(
                    label: '$_currentLength자 / 최대 ${widget.maxLength}자',
                    child: Text(
                      '$_currentLength/${widget.maxLength}',
                      style:
                          widget.counterStyle ??
                          AppTypography.captionRegular.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
