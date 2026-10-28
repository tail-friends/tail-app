import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import 'record_sheet_controls.dart';
import 'shedding_record_sheet.dart';

/// UI only: no record is created, stored, transmitted or used in date math.
Future<void> showFeedingRecordSheet(
  BuildContext context, {
  bool designPreview = false,
}) {
  final navigator = Navigator.of(context);
  late final _RecordSheetRoute route;
  route = _RecordSheetRoute(
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    builder: (_) => FeedingRecordSheet(
      designPreview: designPreview,
      onSheddingChanged: route.setShedding,
    ),
  );
  return navigator.push<void>(route);
}

// One modal and one background throughout tab changes. Only its scrim changes
// from the feeding reference's 18% to the shedding reference's 20%.
class _RecordSheetRoute extends ModalBottomSheetRoute<void> {
  _RecordSheetRoute({required super.builder, required super.capturedThemes})
    : super(
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierLabel: '기록 추가 미리보기 닫기',
        constraints: const BoxConstraints(maxWidth: double.infinity),
      );

  bool _shedding = false;

  @override
  Color get barrierColor => Color(_shedding ? 0x332F6B57 : 0x2E2F6B57);

  void setShedding(bool value) {
    if (_shedding == value) return;
    _shedding = value;
    changedInternalState();
  }
}

class FeedingRecordSheet extends StatefulWidget {
  const FeedingRecordSheet({
    this.designPreview = false,
    this.onSheddingChanged,
    super.key,
  });

  /// Figma sample memo, pet name and date are allowed only in Debug previews.
  final bool designPreview;
  final ValueChanged<bool>? onSheddingChanged;

  @override
  State<FeedingRecordSheet> createState() => _FeedingRecordSheetState();
}

class _FeedingRecordSheetState extends State<FeedingRecordSheet> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _green = Color(0xFF2F6B57);
  static const _border = Color(0xFFE6E1D6);
  static const _selectedBorder = Color(0xE6E6E1D6);
  static const _selectedShadow = [
    BoxShadow(color: Color(0x0F3D2E1F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x1A3D2E1F), offset: Offset(0, 2), blurRadius: 8),
  ];
  static final _title = AppTypography.titleLarge.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _body = AppTypography.bodyRegular.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _label = AppTypography.labelMedium.copyWith(
    fontFamily: 'Jua',
    color: _secondary,
  );
  static final _caption = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: _muted,
  );

  // Local UI choices only, not server-approved food IDs or API enum values.
  static const _foods = ['귀뚜라미', '밀웜', '듀비아', '슈퍼웜'];
  late final TextEditingController _memo;
  int _food = 0;
  int _quantity = 5;
  bool _didNotEat = false;
  bool _showShedding = false;

  bool get _isDesignPreview => kDebugMode && widget.designPreview;

  @override
  void initState() {
    super.initState();
    _memo = TextEditingController(text: _isDesignPreview ? '잘 받아먹음' : '');
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _notice(String message) {
    FocusScope.of(context).unfocus();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('기록 추가 미리보기'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _selectShedding(bool selected) {
    FocusScope.of(context).unfocus();
    widget.onSheddingChanged?.call(selected);
    setState(() => _showShedding = selected);
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _showShedding ? 1 : 0,
    alignment: Alignment.bottomCenter,
    children: [
      _feedingBody(context),
      SheddingRecordSheet(
        designPreview: widget.designPreview,
        onFeedingSelected: () => _selectShedding(false),
      ),
    ],
  );

  Widget _feedingBody(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(
          0.0,
          constraints.maxHeight - media.viewInsets.bottom,
        );
        // Figma is 390×844 with a 551px sheet beginning at y=293. Smaller
        // screens and keyboards constrain the viewport, not the form fields.
        final height = math.min(media.size.height * 551 / 844, available);
        final bottom = media.viewInsets.bottom > 0
            ? 12.0
            : math.max(35.0, media.padding.bottom);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: Semantics(
              label: '급여 기록 UI 미리보기',
              onDismiss: () => Navigator.of(context).pop(),
              child: AppGlassSurface(
                key: const ValueKey('feeding_record_sheet'),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x143D3329),
                    offset: Offset(0, 12),
                    blurRadius: 32,
                  ),
                ],
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 13),
                      Center(
                        child: Container(
                          key: const ValueKey('feeding_grabber'),
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: _header(),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('feeding_scroll'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _recordTypes(),
                              const SizedBox(height: 20),
                              _foodChoices(),
                              const SizedBox(height: 13),
                              _quantityControl(),
                              const SizedBox(height: 20),
                              _refusedControl(),
                              const SizedBox(height: 20),
                              AppTextField(
                                key: const ValueKey('feeding_memo'),
                                label: '메모',
                                controller: _memo,
                                hintText: '메모를 입력해 주세요',
                                labelStyle: _label,
                                textStyle: _body,
                                textInputAction: TextInputAction.done,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(25, 20, 25, bottom),
                        child: AppButton(
                          key: const ValueKey('feeding_save'),
                          label: '저장',
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          minHeight: 48,
                          textStyle: AppTypography.titleMedium.copyWith(
                            fontFamily: 'Jua',
                          ),
                          onPressed: () =>
                              _notice('UI 미리보기입니다. 실제 기록은 저장되지 않았습니다.'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() => Row(
    key: const ValueKey('feeding_header'),
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('기록 추가', style: _title)),
            Text(
              _isDesignPreview ? '욱이 · 10월 20일' : '급여 기록 미리보기',
              style: _caption,
            ),
          ],
        ),
      ),
      RecordTouchTarget(
        key: const ValueKey('feeding_close'),
        label: '닫기',
        alignment: Alignment.centerRight,
        onTap: () => Navigator.of(context).pop(),
        child: AppGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox.square(
            dimension: 36,
            child: Center(
              child: SizedBox.square(
                dimension: 16,
                child: SvgPicture.asset(
                  'assets/icons/species_picker_close.svg',
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _recordTypes() => RecordTypeTabs(
    prefix: 'feeding',
    selectedIndex: 0,
    onSelected: (index) {
      if (index == 1) _selectShedding(true);
      if (index == 2) _notice('체중 기록 화면은 후속 구현 예정입니다.');
    },
  );

  Widget _foodChoices() => Column(
    key: const ValueKey('feeding_food_choices'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('먹이', style: _caption.copyWith(color: _secondary)),
      const SizedBox(height: 1),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (index, food) in _foods.indexed)
            RecordTouchTarget(
              key: ValueKey('feeding_food_$index'),
              label: food,
              selected: _food == index,
              onTap: () => setState(() => _food = index),
              child: AppGlassSurface(
                key: ValueKey('feeding_food_${index}_surface'),
                borderRadius: BorderRadius.circular(AppRadius.full),
                gradient: _food == index
                    ? const LinearGradient(colors: [Colors.white, Colors.white])
                    : AppColors.glassSoftGradient,
                borderColor: _food == index ? _selectedBorder : Colors.white,
                boxShadow: _food == index ? _selectedShadow : const [],
                padding: EdgeInsets.symmetric(
                  horizontal: _food == index ? 13 : 15,
                  vertical: 7,
                ),
                child: Text(
                  food,
                  style: _label.copyWith(
                    color: _food == index ? _ink : _secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _quantityControl() => AppGlassSurface(
    key: const ValueKey('feeding_quantity'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.fromLTRB(19, 2, 4, 2),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text('수량', style: _body),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepperButton(
              'decrease',
              '수량 줄이기',
              'feeding_minus.svg',
              () => setState(() => _quantity = math.max(0, _quantity - 1)),
            ),
            const SizedBox(width: 7),
            Semantics(
              label: '수량 $_quantity마리',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_quantity',
                    key: const ValueKey('feeding_quantity_value'),
                    style: _title,
                  ),
                  const SizedBox(width: 2),
                  Text('마리', style: _label),
                ],
              ),
            ),
            const SizedBox(width: 7),
            _stepperButton(
              'increase',
              '수량 늘리기',
              'feeding_plus.svg',
              () => setState(() => _quantity++),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _stepperButton(
    String id,
    String label,
    String asset,
    VoidCallback onTap,
  ) => RecordTouchTarget(
    key: ValueKey('feeding_$id'),
    label: label,
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset('assets/icons/$asset'),
    ),
  );

  Widget _refusedControl() => RecordTouchTarget(
    key: const ValueKey('feeding_not_eaten'),
    label: '안 먹음, 체크하면 다음 급여일 계산에서 빠져요',
    toggled: _didNotEat,
    onTap: () => setState(() => _didNotEat = !_didNotEat),
    child: AppGlassSurface(
      key: const ValueKey('feeding_not_eaten_surface'),
      borderRadius: BorderRadius.circular(22),
      gradient: AppColors.glassSoftGradient,
      padding: const EdgeInsets.fromLTRB(19, 13, 13, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('안 먹음', style: _body),
                Text('체크하면 다음 급여일 계산에서 빠져요', style: _caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_didNotEat)
            // Original 3x Figma export preserves the SVG's unsupported filter.
            Image.asset(
              'assets/images/feeding_switch_on.png',
              width: 40,
              height: 24,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            )
          else
            SvgPicture.asset('assets/icons/feeding_switch_off.svg'),
        ],
      ),
    ),
  );
}
