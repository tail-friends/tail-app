import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

/// Local form value, not a server model. A month-only value has no day.
@immutable
class HatchingDateSelection {
  const HatchingDateSelection({
    required this.year,
    required this.month,
    this.day,
  }) : assert(year >= 1900),
       assert(month >= 1 && month <= 12),
       assert(day == null || (day >= 1 && day <= 31));

  HatchingDateSelection.fromDate(DateTime date)
    : year = date.year,
      month = date.month,
      day = date.day;

  final int year;
  final int month;
  final int? day;

  /// The legacy DateTime picker must never receive a fabricated first day.
  DateTime? get exactDate => day == null ? null : DateTime(year, month, day!);

  String get label {
    final prefix =
        '${year.toString().padLeft(4, '0')}.'
        '${month.toString().padLeft(2, '0')}';
    return day == null
        ? '$prefix (일자 미상)'
        : '$prefix.${day.toString().padLeft(2, '0')}';
  }
}

Future<HatchingDateSelection?> showPetHatchingDateSheet({
  required BuildContext context,
  HatchingDateSelection? initialValue,
  DateTime? today,
}) => showModalBottomSheet<HatchingDateSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x332F6B57),
  barrierLabel: '해칭일 선택 취소',
  constraints: const BoxConstraints(maxWidth: double.infinity),
  builder: (_) =>
      PetHatchingDateSheet(initialValue: initialValue, today: today),
);

class PetHatchingDateSheet extends StatefulWidget {
  const PetHatchingDateSheet({this.initialValue, this.today, super.key});

  final HatchingDateSelection? initialValue;
  final DateTime? today;

  @override
  State<PetHatchingDateSheet> createState() => _PetHatchingDateSheetState();
}

class _PetHatchingDateSheetState extends State<PetHatchingDateSheet> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  static final _title = AppTypography.titleLarge.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _caption = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: _muted,
  );

  late final DateTime _today;
  late int _year;
  late int _month;
  late int _preferredDay;
  late bool _monthOnly;

  int get _lastMonth => _year == _today.year ? _today.month : 12;
  int get _lastDay {
    final calendarDays = DateTime(_year, _month + 1, 0).day;
    return _year == _today.year && _month == _today.month
        ? math.min(calendarDays, _today.day)
        : calendarDays;
  }

  int get _day => _preferredDay.clamp(1, _lastDay);

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    final initial = widget.initialValue;
    _year = (initial?.year ?? _today.year).clamp(1900, _today.year);
    _month = (initial?.month ?? _today.month).clamp(1, _lastMonth);
    _preferredDay = initial?.day ?? _today.day;
    _monthOnly = initial != null && initial.day == null;
  }

  void _selectYear(int value) => setState(() {
    _year = value;
    _month = _month.clamp(1, _lastMonth);
  });

  void _confirm() => Navigator.of(context).pop(
    HatchingDateSelection(
      year: _year,
      month: _month,
      day: _monthOnly ? null : _day,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final itemExtent = math.max(
      39.0,
      media.textScaler.scale(13) * 19 / 13 + 16,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(
          507.0,
          math.max(0.0, constraints.maxHeight - media.viewInsets.bottom),
        );
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: Semantics(
              label: '해칭일 선택',
              onDismiss: () => Navigator.of(context).pop(),
              child: AppGlassSurface(
                key: const ValueKey('pet_hatching_date_sheet'),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                blur: 12,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
                borderColor: AppColors.borderGlass,
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
                          key: const ValueKey('pet_hatching_grabber'),
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
                          key: const ValueKey('pet_hatching_scroll'),
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _picker(itemExtent),
                              const SizedBox(height: 7),
                              _unknownOption(),
                              const SizedBox(height: 7),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          25,
                          0,
                          25,
                          math.max(35.0, media.padding.bottom),
                        ),
                        child: AppButton(
                          key: const ValueKey('pet_hatching_confirm'),
                          label: '확인',
                          minHeight: 48,
                          backgroundColor: const Color(0xFF2F6B57),
                          foregroundColor: Colors.white,
                          textStyle: AppTypography.titleMedium.copyWith(
                            fontFamily: 'Jua',
                          ),
                          onPressed: _confirm,
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
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('해칭일', style: _title)),
            Text('정확하지 않아도 괜찮아요', style: _caption),
          ],
        ),
      ),
      Semantics(
        label: '해칭일 선택 닫기',
        button: true,
        excludeSemantics: true,
        onTap: () => Navigator.of(context).pop(),
        child: InkWell(
          key: const ValueKey('pet_hatching_close'),
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox.square(
            dimension: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox.square(
                dimension: 36,
                child: AppGlassSurface(
                  borderRadius: BorderRadius.circular(18),
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
          ),
        ),
      ),
    ],
  );

  Widget _picker(double itemExtent) => SizedBox(
    key: const ValueKey('pet_hatching_picker'),
    height: 275,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = math.min(1.0, (constraints.maxWidth - 12) / 270);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 110 * widthScale,
              child: _DateWheel(
                name: 'year',
                label: '연도',
                suffix: '년',
                first: 1900,
                last: _today.year,
                value: _year,
                itemExtent: itemExtent,
                onChanged: _selectYear,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 80 * widthScale,
              child: _DateWheel(
                name: 'month',
                label: '월',
                suffix: '월',
                first: 1,
                last: _lastMonth,
                value: _month,
                itemExtent: itemExtent,
                onChanged: (value) => setState(() => _month = value),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 80 * widthScale,
              child: _DateWheel(
                name: 'day',
                label: '일',
                suffix: '일',
                first: 1,
                last: _lastDay,
                value: _day,
                itemExtent: itemExtent,
                enabled: !_monthOnly,
                onChanged: (value) => setState(() => _preferredDay = value),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _unknownOption() => Semantics(
    label: '정확한 날짜를 몰라요 (월까지만)',
    checked: _monthOnly,
    excludeSemantics: true,
    onTap: () => setState(() => _monthOnly = !_monthOnly),
    child: InkWell(
      key: const ValueKey('pet_hatching_month_only'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _monthOnly = !_monthOnly),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            SvgPicture.asset(
              _monthOnly
                  ? 'assets/icons/character_generation_check_on.svg'
                  : 'assets/icons/hatching_date_unchecked.svg',
              width: 18,
              height: 18,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '정확한 날짜를 몰라요 (월까지만)',
                style: _caption.copyWith(color: const Color(0xFF6B675E)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Flat Figma wheel with a single adjustable accessibility target. Taps choose
/// a row; drags use Flutter's fixed-extent snapping without extra packages.
class _DateWheel extends StatefulWidget {
  const _DateWheel({
    required this.name,
    required this.label,
    required this.suffix,
    required this.first,
    required this.last,
    required this.value,
    required this.itemExtent,
    required this.onChanged,
    this.enabled = true,
  });

  final String name;
  final String label;
  final String suffix;
  final int first;
  final int last;
  final int value;
  final double itemExtent;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  State<_DateWheel> createState() => _DateWheelState();
}

class _DateWheelState extends State<_DateWheel> {
  late FixedExtentScrollController _controller;
  late int _reportedValue;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.value - widget.first,
    );
    _reportedValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _DateWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _reportedValue ||
        widget.first != oldWidget.first ||
        widget.last != oldWidget.last ||
        widget.enabled != oldWidget.enabled ||
        widget.itemExtent != oldWidget.itemExtent) {
      final previous = _controller;
      _reportedValue = widget.value;
      _controller = FixedExtentScrollController(
        initialItem: widget.value - widget.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previous.dispose();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(int value) {
    if (!widget.enabled) return;
    value = value.clamp(widget.first, widget.last);
    _reportedValue = value;
    _controller.jumpToItem(value - widget.first);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final text = '${widget.value}${widget.suffix}';
    final canIncrease = widget.enabled && widget.value < widget.last;
    final canDecrease = widget.enabled && widget.value > widget.first;
    final controller = _controller;
    return Semantics(
      key: ValueKey('pet_hatching_${widget.name}_wheel'),
      label: widget.label,
      value: widget.enabled ? text : '일자 미상',
      enabled: widget.enabled,
      increasedValue: canIncrease
          ? '${widget.value + 1}${widget.suffix}'
          : null,
      decreasedValue: canDecrease
          ? '${widget.value - 1}${widget.suffix}'
          : null,
      onIncrease: canIncrease ? () => _choose(widget.value + 1) : null,
      onDecrease: canDecrease ? () => _choose(widget.value - 1) : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.35,
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.enabled
                ? (details) {
                    final offset =
                        ((details.localPosition.dy -
                                    constraints.maxHeight / 2) /
                                widget.itemExtent)
                            .round();
                    _choose(widget.value + offset);
                  }
                : null,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    key: ValueKey('pet_hatching_${widget.name}_pill'),
                    height: math.max(41, widget.itemExtent + 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: const Color(0xE6E6E1D6)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F3D2E1F),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                        BoxShadow(
                          color: Color(0x1A3D2E1F),
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                KeyedSubtree(
                  key: ValueKey('pet_hatching_${widget.name}_list'),
                  child: ListWheelScrollView.useDelegate(
                    key: ObjectKey(controller),
                    controller: controller,
                    itemExtent: widget.itemExtent,
                    diameterRatio: 1000,
                    perspective: 0.0001,
                    physics: widget.enabled
                        ? const FixedExtentScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      final value = widget.first + index;
                      if (controller == _controller &&
                          widget.enabled &&
                          value != _reportedValue) {
                        _reportedValue = value;
                        widget.onChanged(value);
                      }
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.last - widget.first + 1,
                      builder: (context, index) {
                        final value = widget.first + index;
                        final distance = (value - widget.value).abs();
                        final opacity = switch (distance) {
                          0 => 1.0,
                          1 => 0.6,
                          2 => 0.35,
                          3 => 0.2,
                          _ => 0.0,
                        };
                        return Opacity(
                          opacity: opacity,
                          child: Center(
                            child: Text(
                              '$value${widget.suffix}',
                              style: AppTypography.bodyRegular.copyWith(
                                fontFamily: 'Jua',
                                color: distance == 0
                                    ? const Color(0xFF2B2A26)
                                    : const Color(0xFF6B675E),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
