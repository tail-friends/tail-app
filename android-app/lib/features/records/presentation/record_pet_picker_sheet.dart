import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

/// Local Figma fixtures, not server pet IDs, species codes, or a pet catalog.
/// [allFriends] is a distinct UI choice; "7마리" is unverified design copy.
enum RecordPetPickerChoice {
  allFriends('전체 친구', '7마리'),
  ukki('욱이', '레오파드 게코', avatar: '욱'),
  chito('치토', '비어디드 드래곤', avatar: '치'),
  leo('레오', '크레스티드 게코', avatar: '레'),
  sera('세라', '볼 파이톤', avatar: '세'),
  toto('토토', '육지거북', avatar: '토');

  const RecordPetPickerChoice(this.label, this.description, {this.avatar});
  final String label;
  final String description;
  final String? avatar;
}

final _openSheets = Expando<bool>();

/// Debug-only selection result; null means cancellation (or duplicate entry).
/// Callers keep their previous value on null. No records are queried/filtered.
Future<RecordPetPickerChoice?> showRecordPetPickerPreviewSheet(
  BuildContext context, {
  RecordPetPickerChoice initialSelection = RecordPetPickerChoice.ukki,
}) async {
  if (!kDebugMode || !context.mounted) return null;
  final navigator = Navigator.of(context);
  if (_openSheets[navigator] == true) return null;
  _openSheets[navigator] = true;
  final route = ModalBottomSheetRoute<RecordPetPickerChoice>(
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    modalBarrierColor: const Color(0x332F6B57),
    barrierLabel: '친구 선택 취소',
    showDragHandle: false,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    builder: (sheetContext) => RecordPetPickerSheet(
      initialSelection: initialSelection,
      onResult: (choice) {
        if (ModalRoute.of(sheetContext)?.isCurrent != true) return;
        Navigator.of(sheetContext).pop(choice);
      },
    ),
  );
  try {
    return await navigator.push(route);
  } finally {
    // Hold the entry guard through the reverse animation as well as selection.
    await route.completed;
    _openSheets[navigator] = false;
  }
}

/// Independent Debug UI only. No dependency on the 08 / 08-1 screens.
class RecordPetPickerSheet extends StatefulWidget {
  const RecordPetPickerSheet({
    required this.onResult,
    this.initialSelection = RecordPetPickerChoice.ukki,
    super.key,
  });

  final RecordPetPickerChoice initialSelection;
  final ValueChanged<RecordPetPickerChoice?> onResult;

  @override
  State<RecordPetPickerSheet> createState() => _RecordPetPickerSheetState();
}

class _RecordPetPickerSheetState extends State<RecordPetPickerSheet> {
  static const _muted = Color(0xFF736E65);
  static const _divider = Color(0xFFE6E1D6);
  bool _finished = false;

  void _finish(RecordPetPickerChoice? choice) {
    if (_finished) return;
    _finished = true;
    widget.onResult(choice);
  }

  TextStyle _style(double size, double lineHeight, Color color) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: lineHeight / size,
        color: color,
        letterSpacing: size == 16
            ? -0.3
            : (size == 13 || size == 10 ? -0.1 : 0),
      );

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final scaler = MediaQuery.textScalerOf(context);
    final headerHeight = math.max(44.0, scaler.scale(22) + scaler.scale(14));
    final textHeight = scaler.scale(19) + scaler.scale(14);
    final bottom = math.max(35.0, MediaQuery.viewPaddingOf(context).bottom + 1);
    final groupHeight =
        2 +
        RecordPetPickerChoice.values.fold<double>(
          0,
          (height, choice) =>
              height +
              math.max(choice.avatar == null ? 0.0 : 36.0, textHeight) +
              22 +
              (choice == widget.initialSelection ? 2 : 0) +
              (choice.index > 0 && choice != widget.initialSelection ? 1 : 0),
        );
    final desiredHeight =
        11 + 4 + 16 + headerHeight + 16 + groupHeight + bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        return AppGlassSurface(
          key: const ValueKey('record_pet_picker_sheet'),
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
          child: SizedBox(
            height: math.min(desiredHeight, constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(25, 11, 25, bottom),
              child: Column(
                children: [
                  Container(
                    key: const ValueKey('record_pet_picker_grabber'),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    key: const ValueKey('record_pet_picker_header'),
                    constraints: BoxConstraints(minHeight: headerHeight),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  '친구 선택',
                                  style: _style(
                                    16,
                                    22,
                                    const Color(0xFF2B2A26),
                                  ),
                                ),
                              ),
                              Text(
                                '기록을 볼 친구를 골라 주세요',
                                style: _style(11, 14, _muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          button: true,
                          label: '친구 선택 닫기',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const ValueKey('record_pet_picker_close'),
                              onTap: () => _finish(null),
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
                                        child: SvgPicture.asset(
                                          'assets/icons/notification_time_close.svg',
                                          width: 16,
                                          height: 16,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('record_pet_picker_scroll'),
                      child: AppGlassSurface(
                        key: const ValueKey('record_pet_picker_options'),
                        borderRadius: BorderRadius.circular(22),
                        gradient: AppColors.glassSoftGradient,
                        padding: const EdgeInsets.all(1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final choice
                                in RecordPetPickerChoice.values) ...[
                              if (choice.index > 0 &&
                                  choice != widget.initialSelection)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: _divider,
                                ),
                              _option(choice),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _option(RecordPetPickerChoice choice) {
    final selected = choice == widget.initialSelection;
    return Semantics(
      key: ValueKey('record_pet_picker_option_${choice.name}'),
      button: true,
      selected: selected,
      onTap: () => _finish(choice),
      label: '${choice.label}, ${choice.description}',
      excludeSemantics: true,
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
              )
            : null,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            key: ValueKey('record_pet_picker_tap_${choice.name}'),
            borderRadius: BorderRadius.circular(22),
            onTap: () => _finish(choice),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    if (choice.avatar != null) ...[
                      Container(
                        key: ValueKey(
                          'record_pet_picker_avatar_${choice.name}',
                        ),
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: choice == RecordPetPickerChoice.toto
                              ? const Color(0xFF736E65)
                              : const Color(0xFF2F6B57),
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          choice.avatar!,
                          style: _style(10, 13, Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            choice.label,
                            style: _style(13, 19, const Color(0xFF2B2A26)),
                          ),
                          Text(
                            choice.description,
                            style: _style(11, 14, _muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SvgPicture.asset(
                      'assets/icons/record_pet_picker_${selected ? 'selected' : 'unselected'}.svg',
                      key: ValueKey(
                        'record_pet_picker_indicator_${choice.name}',
                      ),
                      width: 18,
                      height: 18,
                      excludeFromSemantics: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
