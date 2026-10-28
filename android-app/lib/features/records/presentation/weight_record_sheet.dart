import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import 'record_sheet_controls.dart';

/// UI-only input. No numeric conversion, previous-record lookup or persistence.
class WeightRecordSheet extends StatefulWidget {
  const WeightRecordSheet({
    required this.onRecordTypeSelected,
    this.designPreview = false,
    this.dateTimePicker,
    super.key,
  });

  final ValueChanged<int> onRecordTypeSelected;
  final bool designPreview;
  final RecordDateTimePicker? dateTimePicker;

  @override
  State<WeightRecordSheet> createState() => _WeightRecordSheetState();
}

class _WeightRecordSheetState extends State<WeightRecordSheet> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
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
    color: const Color(0xFF736E65),
  );
  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    '⌫',
  ];
  late String _input;
  late DateTime _date;
  bool _edited = false;

  bool get _isDesignPreview => kDebugMode && widget.designPreview;

  @override
  void initState() {
    super.initState();
    _input = _isDesignPreview ? '53.4' : '';
    _date = _isDesignPreview ? DateTime(2024, 10, 20, 9, 12) : DateTime.now();
  }

  void _press(String key) {
    final String next;
    if (key == '⌫') {
      if (_input.isEmpty) return;
      next = _input.substring(0, _input.length - 1);
    } else if (key == '.') {
      if (_input.contains('.')) return;
      next = _input.isEmpty ? '0.' : '$_input.';
    } else {
      next = _input == '0' ? key : '$_input$key';
    }
    setState(() {
      _input = next;
      _edited = true;
    });
  }

  Future<void> _changeDate() async {
    final result = await (widget.dateTimePicker ?? pickRecordDateTime)(
      context,
      _date,
    );
    if (!mounted || result == null) return;
    setState(() => _date = result);
  }

  Future<void> _saveNotice() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('기록 추가 미리보기'),
      content: const Text('UI 미리보기입니다. 실제 체중 기록은 저장되지 않았습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(
          0.0,
          constraints.maxHeight - media.viewInsets.bottom,
        );
        final height = math.min(media.size.height * 671 / 844, available);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: Semantics(
              label: '체중 기록 UI 미리보기',
              onDismiss: () => Navigator.of(context).pop(),
              child: AppGlassSurface(
                key: const ValueKey('weight_record_sheet'),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
                borderColor: AppColors.borderGlass,
                blur: 12,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D1F1C1A),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 11),
                      Center(
                        child: Container(
                          key: const ValueKey('weight_grabber'),
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E1D6),
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
                          key: const ValueKey('weight_scroll'),
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RecordTypeTabs(
                                prefix: 'weight',
                                selectedIndex: 2,
                                onSelected: widget.onRecordTypeSelected,
                              ),
                              const SizedBox(height: 20),
                              _display(),
                              const SizedBox(height: 20),
                              _keypad(),
                              const SizedBox(height: 20),
                              _dateRow(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          25,
                          20,
                          25,
                          media.viewInsets.bottom > 0
                              ? 12
                              : math.max(35.0, media.padding.bottom),
                        ),
                        child: AppButton(
                          key: const ValueKey('weight_save'),
                          label: '저장',
                          minHeight: 48,
                          backgroundColor: const Color(0xFF2F6B57),
                          foregroundColor: Colors.white,
                          textStyle: AppTypography.titleMedium.copyWith(
                            fontFamily: 'Jua',
                          ),
                          onPressed: _saveNotice,
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
    key: const ValueKey('weight_header'),
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('기록 추가', style: _title)),
            Text(
              _isDesignPreview
                  ? '욱이 · ${_date.month}월 ${_date.day}일'
                  : '체중 기록 미리보기',
              style: _caption,
            ),
          ],
        ),
      ),
      RecordTouchTarget(
        key: const ValueKey('weight_close'),
        label: '닫기',
        alignment: Alignment.centerRight,
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox.square(
          dimension: 36,
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Center(
              child: SizedBox.square(
                dimension: 16,
                child: FittedBox(
                  child: SvgPicture.asset(
                    'assets/icons/species_picker_close.svg',
                    width: 24,
                    height: 24,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _display() {
    final showComparison = _isDesignPreview && !_edited;
    return AppGlassSurface(
      key: const ValueKey('weight_display'),
      borderRadius: BorderRadius.circular(22),
      gradient: AppColors.glassSoftGradient,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      child: Column(
        children: [
          Semantics(
            label: '체중, 단위 그램(g)',
            value: _input.isEmpty ? '미입력' : _input,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey('weight_number_scroll'),
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _input.isEmpty ? '—' : _input,
                      key: const ValueKey('weight_value'),
                      style: const TextStyle(
                        fontFamily: 'Jua',
                        fontSize: 40,
                        height: 46 / 40,
                        letterSpacing: -1.2,
                        color: _ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Figma's unit begins 23px below the 46px number line. A
                // scroll viewport does not expose its text child's baseline.
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.textScalerOf(context).scale(40) * 23 / 40,
                  ),
                  child: Text(
                    'g',
                    key: const ValueKey('weight_unit'),
                    style: _label,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showComparison
                ? '지난 측정보다 +1.4g · 10월 13일 52.0g'
                : _input.isEmpty
                ? '체중을 입력해 주세요'
                : '',
            textAlign: TextAlign.center,
            style: _caption.copyWith(
              color: showComparison ? const Color(0xFF336B41) : _secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypad() => Column(
    key: const ValueKey('weight_keypad'),
    children: [
      for (var row = 0; row < 4; row++) ...[
        if (row > 0) const SizedBox(height: 6),
        Row(
          children: [
            for (var column = 0; column < 3; column++) ...[
              if (column > 0) const SizedBox(width: 6),
              Expanded(
                child: RecordTouchTarget(
                  key: ValueKey('weight_key_${row * 3 + column}'),
                  label: switch (_keys[row * 3 + column]) {
                    '.' => '소수점',
                    '⌫' => '마지막 숫자 지우기',
                    final key => key,
                  },
                  onTap: () => _press(_keys[row * 3 + column]),
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    gradient: AppColors.glassSoftGradient,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        _keys[row * 3 + column],
                        style: const TextStyle(
                          fontFamily: 'Jua',
                          fontSize: 18,
                          height: 24 / 18,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ],
  );

  Widget _dateRow() => RecordTouchTarget(
    key: const ValueKey('weight_date'),
    label: '측정 시각, ${formatRecordDateTime(_date)}, 변경',
    onTap: _changeDate,
    child: AppGlassSurface(
      key: const ValueKey('weight_date_surface'),
      borderRadius: BorderRadius.circular(22),
      gradient: AppColors.glassSoftGradient,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(
        children: [
          Text('측정 시각', style: _body.copyWith(color: _secondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    formatRecordDateTime(_date),
                    key: const ValueKey('weight_date_value'),
                    textAlign: TextAlign.right,
                    style: _body,
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  'assets/icons/home_metric_chevron_right.svg',
                  width: 14,
                  height: 14,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
