import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

/// Presentation only. No received notifications, permissions or storage yet.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key}) : _designPreview = false;

  /// Figma sample notifications are never displayed outside Debug previews.
  const NotificationScreen.preview({super.key}) : _designPreview = true;

  final bool _designPreview;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _background = Color(0xFFFAF7F0);
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _green = Color(0xFF2F6B57);
  static final _titleStyle = AppTypography.titleMedium.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _bodyStyle = AppTypography.bodyRegular.copyWith(
    fontFamily: 'Jua',
  );
  static final _labelStyle = AppTypography.labelMedium.copyWith(
    fontFamily: 'Jua',
    color: _secondary,
  );
  static final _captionStyle = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: _muted,
  );

  // Verbatim design examples, not API records or calculated reminder dates.
  static const _examples = [
    (
      title: '욱이 급여할 시간이에요',
      detail: '마지막 급여 후 4일이 지났어요',
      time: '오전 9:00',
      icon: 'assets/icons/notification_feed.svg',
    ),
    (
      title: '치토 탈피 예정일이 다가와요',
      detail: '습도를 평소보다 높여 주세요',
      time: '오전 8:30',
      icon: 'assets/icons/notification_shed.svg',
    ),
    (
      title: '레오 체중을 재 볼까요?',
      detail: '마지막 측정 후 7일 지났어요',
      time: '오전 8:00',
      icon: 'assets/icons/home_first_visit_weight.svg',
    ),
    (
      title: '욱이 캐릭터가 한 단계 자랐어요',
      detail: '기록 30회 달성',
      time: '10월 18일',
      icon: 'assets/icons/notification_egg.svg',
    ),
    (
      title: '루비 급여 기록이 저장됐어요',
      detail: '냉동 마우스 1마리',
      time: '10월 17일',
      icon: 'assets/icons/notification_feed.svg',
    ),
  ];

  final _unread = <int>{0, 1};
  bool get _isPreview => kDebugMode && widget._designPreview;
  bool get _canMarkAll => _isPreview && _unread.isNotEmpty;

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: Navigator.of(context).canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _goBack();
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _background,
        systemNavigationBarDividerColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('notification_screen'),
        backgroundColor: _background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  // Exact byte match for Figma bg 408:2318. Reuse the existing
                  // decoration only; all notification content is real widgets.
                  child: Image.asset(
                    'assets/images/home_first_visit_background.png',
                    key: const ValueKey('notification_background'),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: math.max(
                        4,
                        58 - MediaQuery.paddingOf(context).top,
                      ),
                    ),
                    _header(),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('notification_scroll'),
                        padding: const EdgeInsets.only(top: 18, bottom: 24),
                        child: _isPreview ? _previewList() : _emptyState(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => ConstrainedBox(
    key: const ValueKey('notification_header'),
    constraints: const BoxConstraints(minHeight: 44),
    child: Row(
      children: [
        Semantics(
          label: '뒤로가기',
          button: true,
          excludeSemantics: true,
          onTap: _goBack,
          child: InkWell(
            key: const ValueKey('notification_back'),
            onTap: _goBack,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox.square(
              dimension: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppGlassSurface(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Center(
                      child: _icon('assets/icons/terms_chevron_left.svg'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text('알림', textAlign: TextAlign.center, style: _titleStyle),
          ),
        ),
        // Preserve the original title alignment and 73×34 pill while enlarging
        // its hit target. This grows naturally with accessibility text scaling.
        Semantics(
          label: '모두 읽음',
          hint: _canMarkAll ? '표시된 알림을 모두 읽음으로 표시' : null,
          button: true,
          enabled: _canMarkAll,
          excludeSemantics: true,
          onTap: _canMarkAll ? _markAll : null,
          child: InkWell(
            key: const ValueKey('notification_mark_all'),
            onTap: _canMarkAll ? _markAll : null,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 73),
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  alignment: Alignment.centerRight,
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 43),
                      child: Text(
                        '모두 읽음',
                        textAlign: TextAlign.center,
                        style: _labelStyle.copyWith(
                          color: _canMarkAll ? _ink : _muted,
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
  );

  void _markAll() => setState(_unread.clear);

  Widget _previewList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 18,
    children: [
      Semantics(header: true, child: Text('오늘', style: _labelStyle)),
      _group('today', const [0, 1, 2]),
      Semantics(
        header: true,
        child: Text('이번 주', style: _captionStyle.copyWith(color: _secondary)),
      ),
      _group('week', const [3, 4]),
    ],
  );

  Widget _group(String id, List<int> indices) => AppGlassSurface(
    key: ValueKey('notification_group_$id'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
    child: Column(
      children: [
        for (final (position, index) in indices.indexed) ...[
          if (position > 0)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE6E1D6)),
          _notification(index),
        ],
      ],
    ),
  );

  Widget _notification(int index) {
    final item = _examples[index];
    final unread = _unread.contains(index);
    void markRead() {
      if (unread) setState(() => _unread.remove(index));
    }

    return Semantics(
      key: ValueKey('notification_semantics_$index'),
      label: '${item.title}, ${item.detail}, ${item.time}',
      value: unread ? '읽지 않음' : '읽음',
      hint: unread ? '읽음으로 표시' : null,
      button: true,
      excludeSemantics: true,
      onTap: markRead,
      child: InkWell(
        key: ValueKey('notification_item_$index'),
        onTap: markRead,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppGlassSurface(
                key: ValueKey('notification_badge_$index'),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox.square(
                  dimension: 34,
                  child: Center(child: _icon(item.icon)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 2,
                  children: [
                    // Wrap dates beneath long titles at narrow widths/large
                    // text instead of truncating notification content.
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          item.title,
                          style: _bodyStyle.copyWith(
                            color: unread ? _ink : _secondary,
                          ),
                        ),
                        Text(item.time, style: _captionStyle),
                      ],
                    ),
                    Text(item.detail, style: _captionStyle),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 12),
                // The requested unread colour is green; preserve the original
                // Figma 6px shape without modifying the downloaded SVG file.
                SvgPicture.asset(
                  'assets/icons/notification_unread.svg',
                  key: ValueKey('notification_unread_$index'),
                  colorFilter: const ColorFilter.mode(_green, BlendMode.srcIn),
                  excludeFromSemantics: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => AppGlassSurface(
    key: const ValueKey('notification_empty'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.all(25),
    child: Column(
      spacing: 8,
      children: [
        Text('아직 알림이 없어요', style: _titleStyle, textAlign: TextAlign.center),
        Text(
          '새로운 알림이 도착하면 여기에서 확인할 수 있어요',
          style: _captionStyle,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _icon(String asset) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: 16,
      child: FittedBox(child: SvgPicture.asset(asset)),
    ),
  );
}
