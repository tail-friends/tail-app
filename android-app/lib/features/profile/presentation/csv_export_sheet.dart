import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

const csvExportPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 표시된 날짜와 기록 수(214개 · 7마리)는 예시이며, 실제 CSV 파일 생성이나 사용자 데이터 조회는 실행되지 않습니다.';
final _openSheets = Expando<bool>();

/// Opens a local design fixture; never returns records or writes files.
Future<void> showCsvExportPreviewSheet(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_openSheets[navigator] == true) return;
  _openSheets[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(csvExportPreviewNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('미리보기 열기'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted || !navigator.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x332F6B57),
      barrierLabel: 'CSV 내보내기 닫기',
      showDragHandle: false,
      builder: (_) => const _CsvExportSheet(),
    );
  } finally {
    _openSheets[navigator] = false;
  }
}

class _CsvExportSheet extends StatefulWidget {
  const _CsvExportSheet();
  @override
  State<_CsvExportSheet> createState() => _CsvExportSheetState();
}

class _CsvExportSheetState extends State<_CsvExportSheet> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  static const _periods = ['최근 1개월', '3개월', '올해', '직접 선택'];
  static const _types = ['급여·탈피·체중', '청소·배변·메모', '온습도'];
  final _enabled = [true, true, false];
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  int _period = 1;
  DateTime _start = DateTime(2026, 7, 21);
  DateTime _end = DateTime(2026, 10, 20);
  bool _dateOpen = false;
  bool _closing = false;

  String _dateLabel(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.pop(context);
  }

  void _selectPeriod(int index) {
    setState(() {
      _period = index;
      // Fixed preview intervals anchored to Figma's example, never today's date.
      if (index < 3) {
        _end = DateTime(2026, 10, 20);
        _start = [
          DateTime(2026, 9, 20),
          DateTime(2026, 7, 21),
          DateTime(2026, 1, 1),
        ][index];
      }
    });
  }

  Future<void> _chooseDate(bool start) async {
    if (_dateOpen || _closing || !mounted) return;
    _dateOpen = true;
    try {
      final date = await showDatePicker(
        context: context,
        initialDate: start ? _start : _end,
        firstDate: start ? DateTime(1900) : _start,
        lastDate: start ? _end : DateTime(2100, 12, 31),
        currentDate: DateTime(2026, 10, 20),
        helpText: start ? '시작 날짜 선택' : '종료 날짜 선택',
        cancelText: '취소',
        confirmText: '확인',
      );
      if (date == null || !mounted || _closing) return;
      if (start ? date.isAfter(_end) : date.isBefore(_start)) return;
      setState(() {
        _period = 3;
        if (start) {
          _start = date;
        } else {
          _end = date;
        }
      });
    } finally {
      _dateOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final height = math.min(
        constraints.maxHeight,
        532.0 + math.max(0.0, scale - 1) * 300,
      );
      return AppGlassSurface(
        key: const ValueKey('csv_export_sheet'),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143D3329),
            offset: Offset(0, 12),
            blurRadius: 32,
          ),
        ],
        child: SizedBox(
          height: height,
          child: ScaffoldMessenger(
            key: _messenger,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SingleChildScrollView(
                key: const ValueKey('csv_export_scroll'),
                padding: EdgeInsets.fromLTRB(
                  25,
                  11,
                  25,
                  math.max(35, MediaQuery.viewPaddingOf(context).bottom + 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        key: const ValueKey('csv_export_grabber'),
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CSV로 내보내기',
                                style: AppTypography.titleLarge.copyWith(
                                  fontFamily: 'Jua',
                                  height: 23 / 16,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '선택한 기간의 모든 기록',
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  height: 16 / 11,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'CSV 내보내기 닫기',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const ValueKey('csv_export_close'),
                              onTap: _close,
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox.square(
                                dimension: 44,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: AppGlassSurface(
                                    borderRadius: BorderRadius.circular(999),
                                    child: SizedBox.square(
                                      dimension: 36,
                                      child: Center(
                                        child: SizedBox.square(
                                          dimension: 16,
                                          child: SvgPicture.asset(
                                            'assets/icons/notification_time_close.svg',
                                            excludeFromSemantics: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (var i = 0; i < 4; i++) _pill(i)],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _date(true)),
                        const SizedBox(width: 8),
                        Expanded(child: _date(false)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE6E1D6),
                        ),
                      _toggle(i),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      '기록 214개 · 7마리',
                      style: AppTypography.captionRegular.copyWith(
                        fontFamily: 'Jua',
                        height: 16 / 11,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      key: const ValueKey('csv_export_export'),
                      label: '내보내기',
                      backgroundColor: const Color(0xFF2F6B57),
                      foregroundColor: Colors.white,
                      textStyle: AppTypography.titleMedium.copyWith(
                        fontFamily: 'Jua',
                      ),
                      onPressed: () {
                        _messenger.currentState
                          ?..removeCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                '디자인 미리보기입니다. 실제 CSV 파일은 생성되지 않습니다.',
                              ),
                            ),
                          );
                      },
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

  Widget _pill(int index) {
    final selected = _period == index;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      child: Text(
        _periods[index],
        style: AppTypography.labelMedium.copyWith(
          fontFamily: 'Jua',
          height: 17 / 12,
          color: selected ? Colors.white : const Color(0xFF6B675E),
        ),
      ),
    );
    return Semantics(
      key: ValueKey('csv_export_period_$index'),
      button: true,
      selected: selected,
      label: _periods[index],
      excludeSemantics: true,
      onTap: () => _selectPeriod(index),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPeriod(index),
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              alignment: Alignment.topCenter,
              child: selected
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F6B57),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xE6E6E1D6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A3D2E1F),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: content,
                    )
                  : AppGlassSurface(
                      borderRadius: BorderRadius.circular(999),
                      child: content,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _date(bool start) => Semantics(
    button: true,
    label: start ? '시작 날짜' : '종료 날짜',
    value: _dateLabel(start ? _start : _end),
    excludeSemantics: true,
    onTap: () => _chooseDate(start),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('csv_export_${start ? 'start' : 'end'}'),
        onTap: () => _chooseDate(start),
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(14),
        child: AppGlassSurface(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                start ? '시작' : '종료',
                style: AppTypography.captionRegular.copyWith(
                  fontFamily: 'Jua',
                  height: 16 / 11,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dateLabel(start ? _start : _end),
                style: AppTypography.bodyRegular.copyWith(
                  fontFamily: 'Jua',
                  height: 18 / 13,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _toggle(int index) => Semantics(
    key: ValueKey('csv_export_toggle_$index'),
    label: _types[index],
    toggled: _enabled[index],
    enabled: true,
    excludeSemantics: true,
    onTap: () => setState(() => _enabled[index] = !_enabled[index]),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        excludeFromSemantics: true,
        onTap: () => setState(() => _enabled[index] = !_enabled[index]),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _types[index],
                  style: AppTypography.bodyRegular.copyWith(
                    fontFamily: 'Jua',
                    height: 18 / 13,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                key: ValueKey('csv_export_switch_$index'),
                width: 40,
                height: 24,
                child: _enabled[index]
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -24,
                            top: -14,
                            width: 88,
                            height: 72,
                            child: Image.asset(
                              'assets/images/csv_export_switch_on.png',
                              excludeFromSemantics: true,
                            ),
                          ),
                        ],
                      )
                    : Image.asset(
                        'assets/images/csv_export_switch_off.png',
                        excludeFromSemantics: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
