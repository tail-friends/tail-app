import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

final _openSheets = Expando<bool>();

/// Returns a local preview selection only. No permission or scheduling service.
Future<TimeOfDay?> showNotificationTimePreviewSheet(
  BuildContext context, {
  TimeOfDay initialTime = const TimeOfDay(hour: 20, minute: 0),
}) async {
  if (!kDebugMode || !context.mounted) return null;
  assert(initialTime.minute % 5 == 0, 'Figma preview uses 5-minute options');
  final navigator = Navigator.of(context);
  if (_openSheets[navigator] == true) return null;
  _openSheets[navigator] = true;
  try {
    return await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x332F6B57),
      barrierLabel: '알림 시간 선택 취소',
      showDragHandle: false,
      builder: (_) => _NotificationTimeSheet(initialTime: initialTime),
    );
  } finally {
    _openSheets[navigator] = false;
  }
}

class _NotificationTimeSheet extends StatefulWidget {
  const _NotificationTimeSheet({required this.initialTime});
  final TimeOfDay initialTime;
  @override
  State<_NotificationTimeSheet> createState() => _NotificationTimeSheetState();
}

class _NotificationTimeSheetState extends State<_NotificationTimeSheet> {
  late int _period = widget.initialTime.hour >= 12 ? 1 : 0;
  late int _hour = (widget.initialTime.hour + 11) % 12;
  late int _minute = widget.initialTime.minute ~/ 5;
  bool _finished = false;

  void _finish(bool confirm) {
    if (_finished) return;
    _finished = true;
    final time = TimeOfDay(
      hour: (_hour + 1) % 12 + _period * 12,
      minute: _minute * 5,
    );
    Navigator.of(context).pop(confirm ? time : null);
  }

  @override
  Widget build(BuildContext context) {
    final itemExtent = math.max(
      39.0,
      MediaQuery.textScalerOf(context).scale(19) + 12,
    );
    return AppGlassSurface(
      key: const ValueKey('notification_time_sheet'),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      gradient: const LinearGradient(colors: [Colors.white, Colors.white]),
      borderColor: const Color(0xE6FFFFFF),
      blur: 12,
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1F1C1A),
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
      ],
      child: SingleChildScrollView(
        key: const ValueKey('notification_time_scroll'),
        padding: EdgeInsets.fromLTRB(
          25,
          11,
          25,
          math.max(35, MediaQuery.viewPaddingOf(context).bottom + 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                key: const ValueKey('notification_time_grabber'),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            '알림 시간',
                            style: AppTypography.titleLarge.copyWith(
                              fontFamily: 'Jua',
                              color: const Color(0xFF2B2A26),
                            ),
                          ),
                        ),
                        Text(
                          '급여 알림을 받을 시간',
                          style: AppTypography.captionRegular.copyWith(
                            fontFamily: 'Jua',
                            color: const Color(0xFF736E65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: '알림 시간 닫기',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('notification_time_close'),
                        onTap: () => _finish(false),
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
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: itemExtent * 7 + 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeWheel(
                    name: 'period',
                    label: '오전 또는 오후',
                    values: const ['오전', '오후'],
                    value: _period,
                    width: 80,
                    itemExtent: itemExtent,
                    onChanged: (v) => setState(() => _period = v),
                  ),
                  const SizedBox(width: 6),
                  _TimeWheel(
                    name: 'hour',
                    label: '시',
                    values: List.generate(12, (i) => '${i + 1}'),
                    value: _hour,
                    width: 70,
                    itemExtent: itemExtent,
                    onChanged: (v) => setState(() => _hour = v),
                  ),
                  const SizedBox(width: 6),
                  _TimeWheel(
                    name: 'minute',
                    label: '분',
                    values: List.generate(
                      12,
                      (i) => '${i * 5}'.padLeft(2, '0'),
                    ),
                    value: _minute,
                    width: 70,
                    itemExtent: itemExtent,
                    onChanged: (v) => setState(() => _minute = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              key: const ValueKey('notification_time_confirm'),
              label: '확인',
              minHeight: 48,
              backgroundColor: const Color(0xFF2F6B57),
              textStyle: AppTypography.titleMedium.copyWith(fontFamily: 'Jua'),
              onPressed: () => _finish(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeWheel extends StatefulWidget {
  const _TimeWheel({
    required this.name,
    required this.label,
    required this.values,
    required this.value,
    required this.width,
    required this.itemExtent,
    required this.onChanged,
  });
  final String name, label;
  final List<String> values;
  final int value;
  final double width, itemExtent;
  final ValueChanged<int> onChanged;
  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.value,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(int index) {
    index = index.clamp(0, widget.values.length - 1);
    _controller.jumpToItem(index);
    widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final canIncrease = widget.value < widget.values.length - 1;
    final canDecrease = widget.value > 0;
    return SizedBox(
      width: widget.width,
      child: Semantics(
        key: ValueKey('notification_time_${widget.name}'),
        label: widget.label,
        value: widget.values[widget.value],
        increasedValue: canIncrease ? widget.values[widget.value + 1] : null,
        decreasedValue: canDecrease ? widget.values[widget.value - 1] : null,
        onIncrease: canIncrease ? () => _choose(widget.value + 1) : null,
        onDecrease: canDecrease ? () => _choose(widget.value - 1) : null,
        excludeSemantics: true,
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _choose(widget.value + 1);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _choose(widget.value - 1);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _choose(
                widget.value +
                    ((details.localPosition.dy - constraints.maxHeight / 2) /
                            widget.itemExtent)
                        .round(),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      key: ValueKey('notification_time_${widget.name}_pill'),
                      height: widget.itemExtent + 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
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
                  ListWheelScrollView.useDelegate(
                    key: ValueKey('notification_time_${widget.name}_list'),
                    controller: _controller,
                    itemExtent: widget.itemExtent,
                    diameterRatio: 1000,
                    perspective: 0.0001,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: widget.onChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.values.length,
                      builder: (_, i) {
                        final distance = (i - widget.value).abs();
                        final opacity = switch (distance) {
                          0 => 1.0,
                          1 => .6,
                          2 => .35,
                          3 => .2,
                          _ => 0.0,
                        };
                        return Opacity(
                          opacity: opacity,
                          child: Center(
                            child: Text(
                              widget.values[i],
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
