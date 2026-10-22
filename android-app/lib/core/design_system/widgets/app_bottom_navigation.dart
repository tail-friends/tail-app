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
    super.key,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143D3329),
            offset: Offset(0, 12),
            blurRadius: 16,
          ),
        ],
        child: Row(
          children: AppTab.values
              .map(
                (tab) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: tab == AppTab.profile ? 0 : 8,
                    ),
                    child: _NavigationItem(
                      tab: tab,
                      label: _items[tab]!.label,
                      assetName: _items[tab]!.assetName,
                      selected: currentTab == tab,
                      onTap: () => onTabSelected(tab),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
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
  });

  final AppTab tab;
  final String label;
  final String assetName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: radius,
        elevation: selected ? 2 : 0,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
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
                    style: AppTypography.captionRegular.copyWith(
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
    );
  }
}
