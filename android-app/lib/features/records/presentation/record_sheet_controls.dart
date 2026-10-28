import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

/// Shared only by the feeding and shedding UI sheets.
class RecordTypeTabs extends StatelessWidget {
  const RecordTypeTabs({
    required this.prefix,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final String prefix;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const selectedBorder = Color(0xE6E6E1D6);
  static const selectedShadow = [
    BoxShadow(color: Color(0x0F3D2E1F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x1A3D2E1F), offset: Offset(0, 2), blurRadius: 8),
  ];

  @override
  Widget build(BuildContext context) => AppGlassSurface(
    key: ValueKey('${prefix}_record_types'),
    borderRadius: BorderRadius.circular(AppRadius.full),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, label) in const ['급여', '탈피', '체중'].indexed)
            Expanded(
              flex: selectedIndex == index ? 112 : 110,
              child: RecordTouchTarget(
                key: ValueKey('${prefix}_type_$index'),
                label: label,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: AppGlassSurface(
                    key: ValueKey('${prefix}_type_${index}_surface'),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    gradient: selectedIndex == index
                        ? const LinearGradient(
                            colors: [Colors.white, Colors.white],
                          )
                        : const LinearGradient(
                            colors: [Colors.transparent, Colors.transparent],
                          ),
                    borderColor: selectedIndex == index
                        ? selectedBorder
                        : Colors.transparent,
                    boxShadow: selectedIndex == index
                        ? selectedShadow
                        : const [],
                    padding: EdgeInsets.symmetric(
                      vertical: selectedIndex == index ? 10 : 9,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/${index == 2 ? 'feeding_weight' : '${selectedIndex == 1 ? 'shedding' : 'feeding'}_${index == 0 ? 'feed' : 'shed'}'}.svg',
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelMedium.copyWith(
                              fontFamily: 'Jua',
                              color: selectedIndex == index
                                  ? const Color(0xFF2B2A26)
                                  : const Color(0xFF6B675E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class RecordTouchTarget extends StatelessWidget {
  const RecordTouchTarget({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected,
    this.toggled,
    this.alignment = Alignment.center,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool? selected;
  final bool? toggled;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: toggled == null,
    selected: selected,
    toggled: toggled,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          alignment: alignment,
          child: child,
        ),
      ),
    ),
  );
}
