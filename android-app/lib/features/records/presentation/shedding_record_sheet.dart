import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import 'record_sheet_controls.dart';

typedef SheddingDateTimePicker =
    Future<DateTime?> Function(BuildContext context, DateTime current);

/// Local form state only. This sheet never produces or stores a record.
class SheddingRecordSheet extends StatefulWidget {
  const SheddingRecordSheet({
    required this.onFeedingSelected,
    this.designPreview = false,
    this.dateTimePicker,
    super.key,
  });

  final VoidCallback onFeedingSelected;
  final bool designPreview;
  final SheddingDateTimePicker? dateTimePicker;

  @override
  State<SheddingRecordSheet> createState() => _SheddingRecordSheetState();
}

class _SheddingRecordSheetState extends State<SheddingRecordSheet> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _statuses = ['완전 탈피', '부분 탈피', '블루 단계'];
  static const _parts = ['발가락', '꼬리 끝', '눈', '없음'];
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
  late final TextEditingController _memo;
  late DateTime _date;
  late final Set<int> _retained;
  int? _status;

  bool get _isDesignPreview => kDebugMode && widget.designPreview;

  @override
  void initState() {
    super.initState();
    _status = _isDesignPreview ? 0 : null;
    _date = _isDesignPreview ? DateTime(2024, 10, 20, 9, 12) : DateTime.now();
    _retained = _isDesignPreview ? {0, 1} : {};
    _memo = TextEditingController(
      text: _isDesignPreview ? '발가락 허물은 미온수로 불려서 제거' : '',
    );
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
      builder: (context) => AlertDialog(
        title: const Text('기록 추가 미리보기'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime current,
  ) async {
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      // Picker navigation bounds only, not an API or business validation rule.
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (day == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _changeDate() async {
    FocusScope.of(context).unfocus();
    final result = await (widget.dateTimePicker ?? _pickDateTime)(
      context,
      _date,
    );
    if (!mounted || result == null) return;
    setState(() => _date = result);
  }

  String get _dateLabel {
    final time = TimeOfDay.fromDateTime(_date);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${_date.month}월 ${_date.day}일 ${time.period == DayPeriod.am ? '오전' : '오후'} $hour:${time.minute.toString().padLeft(2, '0')}';
  }

  void _togglePart(int index) => setState(() {
    if (_retained.remove(index)) return;
    if (index == 3) {
      _retained.clear();
    } else {
      _retained.remove(3);
    }
    _retained.add(index);
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(
          0.0,
          constraints.maxHeight - media.viewInsets.bottom,
        );
        final height = math.min(media.size.height * 560 / 844, available);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: Semantics(
              label: '탈피 기록 UI 미리보기',
              onDismiss: () => Navigator.of(context).pop(),
              child: AppGlassSurface(
                key: const ValueKey('shedding_record_sheet'),
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
                          key: const ValueKey('shedding_grabber'),
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
                          key: const ValueKey('shedding_scroll'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RecordTypeTabs(
                                prefix: 'shedding',
                                selectedIndex: 1,
                                onSelected: (index) {
                                  if (index == 0) {
                                    FocusScope.of(context).unfocus();
                                    widget.onFeedingSelected();
                                  }
                                  if (index == 2) {
                                    _notice('체중 기록 화면은 후속 구현 예정입니다.');
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              _statusChoices(),
                              const SizedBox(height: 20),
                              _retainedChoices(),
                              const SizedBox(height: 14),
                              _dateRow(),
                              const SizedBox(height: 20),
                              AppTextField(
                                key: const ValueKey('shedding_memo'),
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
                        padding: EdgeInsets.fromLTRB(
                          25,
                          20,
                          25,
                          media.viewInsets.bottom > 0
                              ? 12
                              : math.max(35.0, media.padding.bottom),
                        ),
                        child: AppButton(
                          key: const ValueKey('shedding_save'),
                          label: '저장',
                          minHeight: 48,
                          backgroundColor: const Color(0xFF2F6B57),
                          foregroundColor: Colors.white,
                          textStyle: AppTypography.titleMedium.copyWith(
                            fontFamily: 'Jua',
                          ),
                          onPressed: () =>
                              _notice('UI 미리보기입니다. 실제 탈피 기록은 저장되지 않았습니다.'),
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
    key: const ValueKey('shedding_header'),
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('기록 추가', style: _title)),
            Text(
              _isDesignPreview
                  ? '욱이 · ${_date.month}월 ${_date.day}일'
                  : '탈피 기록 미리보기',
              style: _caption,
            ),
          ],
        ),
      ),
      RecordTouchTarget(
        key: const ValueKey('shedding_close'),
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

  Widget _statusChoices() => Column(
    key: const ValueKey('shedding_status_choices'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('탈피 상태', style: _caption.copyWith(color: _secondary)),
      const SizedBox(height: 8),
      AppGlassSurface(
        key: const ValueKey('shedding_status_segment'),
        borderRadius: BorderRadius.circular(AppRadius.full),
        gradient: AppColors.glassSoftGradient,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, label) in _statuses.indexed)
                Expanded(
                  flex: _status == index ? 112 : 110,
                  child: RecordTouchTarget(
                    key: ValueKey('shedding_status_$index'),
                    label: label,
                    selected: _status == index,
                    alignment: Alignment.topCenter,
                    onTap: () => setState(() => _status = index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AppGlassSurface(
                        key: ValueKey('shedding_status_${index}_surface'),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        gradient: LinearGradient(
                          colors: _status == index
                              ? [Colors.white, Colors.white]
                              : [Colors.transparent, Colors.transparent],
                        ),
                        borderColor: _status == index
                            ? RecordTypeTabs.selectedBorder
                            : Colors.transparent,
                        boxShadow: _status == index
                            ? RecordTypeTabs.selectedShadow
                            : const [],
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: _status == index ? 9 : 8,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: _status == index ? _body : _caption,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _retainedChoices() => Column(
    key: const ValueKey('shedding_retained_choices'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Figma shows this section even with complete shedding selected.
      Text('남은 허물 확인 (부분 탈피 시)', style: _caption.copyWith(color: _secondary)),
      const SizedBox(height: 2),
      Wrap(
        runSpacing: 8,
        children: [
          for (final (index, label) in _parts.indexed)
            Padding(
              padding: EdgeInsets.only(
                right: index == 3
                    ? 0
                    : index == 2
                    ? 4
                    : 8,
              ),
              child: RecordTouchTarget(
                key: ValueKey('shedding_part_$index'),
                label: label,
                selected: _retained.contains(index),
                alignment: Alignment.centerLeft,
                onTap: () => _togglePart(index),
                child: AppGlassSurface(
                  key: ValueKey('shedding_part_${index}_surface'),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  gradient: _retained.contains(index)
                      ? const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        )
                      : AppColors.glassStrongGradient,
                  borderColor: _retained.contains(index)
                      ? RecordTypeTabs.selectedBorder
                      : Colors.white,
                  boxShadow: _retained.contains(index)
                      ? RecordTypeTabs.selectedShadow
                      : const [],
                  padding: EdgeInsets.symmetric(
                    horizontal: _retained.contains(index) ? 13 : 15,
                    vertical: 8,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: [31.0, 33.0, 10.0, 20.0][index],
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: _label.copyWith(
                        color: _retained.contains(index) ? _ink : _secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _dateRow() => RecordTouchTarget(
    key: const ValueKey('shedding_date'),
    label: '날짜, $_dateLabel, 변경',
    onTap: _changeDate,
    child: AppGlassSurface(
      key: const ValueKey('shedding_date_surface'),
      borderRadius: BorderRadius.circular(22),
      gradient: AppColors.glassSoftGradient,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(
        children: [
          Text('날짜', style: _body.copyWith(color: _secondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _dateLabel,
                    key: const ValueKey('shedding_date_value'),
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
