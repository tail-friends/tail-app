import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';
import 'app_glass_surface.dart';

enum AppTab { habitat, records, pets, profile }

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentTab,
    required this.onTabSelected,
    this.labelStyle,
    super.key,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final TextStyle? labelStyle;

  static const _items = <AppTab, ({String label, String assetName})>{
    AppTab.habitat: (label: '사육장', assetName: 'home'),
    AppTab.records: (label: '기록', assetName: 'record'),
    AppTab.pets: (label: '내 아이들', assetName: 'pets'),
    AppTab.profile: (label: '마이', assetName: 'profile'),
  };

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 342, minHeight: 54),
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(AppRadius.full),
        blur: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143D3329),
            offset: Offset(0, 12),
            blurRadius: 16,
          ),
        ],
        child: Row(
          children: [
            for (final (index, tab) in AppTab.values.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _NavigationItem(
                  tab: tab,
                  label: _items[tab]!.label,
                  assetName: _items[tab]!.assetName,
                  selected: currentTab == tab,
                  onTap: () => onTabSelected(tab),
                  labelStyle: labelStyle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.tab,
    required this.label,
    required this.assetName,
    required this.selected,
    required this.onTap,
    required this.labelStyle,
  });

  final AppTab tab;
  final String label;
  final String assetName;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);
    return Semantics(
      key: ValueKey('app_bottom_navigation_${tab.name}_touch_target'),
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 38),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: radius,
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: SvgPicture.asset(
                        'assets/icons/nav_${assetName}_${selected ? 'active' : 'inactive'}.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: (labelStyle ?? AppTypography.captionRegular)
                          .copyWith(
                            fontSize: 10,
                            height: 13 / 10,
                            color: selected
                                ? AppColors.textComponentPrimary
                                : AppColors.textTertiary,
                          ),
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
