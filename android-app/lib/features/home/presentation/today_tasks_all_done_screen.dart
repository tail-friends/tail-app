import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const todayTasksAllDonePreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 날짜, 개체 정보 및 완료 상태는 예시이며 실제 기록 조회나 저장은 실행되지 않습니다. 휴면 안내도 실제 개체 상태가 아닙니다.';
final _previewNavigators = Expando<bool>();

Future<void> showTodayTasksAllDonePreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewNavigators[navigator] == true) return;
  _previewNavigators[navigator] = true;
  try {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(todayTasksAllDonePreviewNotice),
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
    if (allow != true || !context.mounted || !navigator.mounted) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => const TodayTasksAllDoneScreen.preview(),
    );
    await navigator.push(route);
    await route.completed;
  } finally {
    _previewNavigators[navigator] = false;
  }
}

// Display-only fixtures. These are not pet IDs, completed records or API fields.
const _examples = [
  (id: 'ukki', name: '욱이', detail: '급여 · 귀뚜라미 5마리', avatar: '욱'),
  (id: 'leo', name: '레오', detail: '급여 · 귀뚜라미 4마리', avatar: '레'),
  (id: 'haru', name: '하루', detail: '칼슘 더스팅', avatar: '하'),
  (id: 'chito', name: '치토', detail: 'UVB 램프 점검', avatar: '치'),
];

/// Independent Figma 10-1 fixture; no dependency on Figma 10, 08 or 08-1.
class TodayTasksAllDoneScreen extends StatefulWidget {
  const TodayTasksAllDoneScreen.preview({super.key});

  @override
  State<TodayTasksAllDoneScreen> createState() => _AllDoneState();
}

class _AllDoneState extends State<TodayTasksAllDoneScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  static const _secondary = Color(0xFF6B675E);
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  TextStyle _style(double size, double lineHeight, [Color color = _ink]) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: lineHeight / size,
        color: color,
        letterSpacing: size == 16
            ? -0.3
            : (size == 13 || size == 10 ? -0.1 : 0),
      );

  void _notice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.paddingOf(context).bottom + 100,
          ),
          content: Text(message),
        ),
      );
  }

  void _leave() {
    _messenger.currentState?.removeCurrentSnackBar();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            key: const ValueKey('all_done_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Isolated original Figma bg 408:2375; its blur is preserved by PNG.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/privacy_policy_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('all_done_scroll'),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            math.max(
                              2.5,
                              56.5 - MediaQuery.paddingOf(context).top,
                            ),
                            24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(),
                              const SizedBox(height: 10.5),
                              Padding(
                                key: const ValueKey('all_done_hero'),
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    Semantics(
                                      label: '예시 친구: 욱, 레, 하, 치',
                                      excludeSemantics: true,
                                      child: SizedBox(
                                        key: const ValueKey(
                                          'all_done_avatar_stack',
                                        ),
                                        width: 114,
                                        height: 36,
                                        child: Stack(
                                          children: [
                                            for (final (index, example)
                                                in _examples.indexed)
                                              Positioned(
                                                left: index * 26,
                                                top: 0,
                                                child: _avatar(
                                                  example.avatar,
                                                  'hero_${example.id}',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        '오늘은 다 챙겼어요',
                                        textAlign: TextAlign.center,
                                        style: _style(16, 22),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '휴면 중인 토토는 목록에서 빠졌어요',
                                      textAlign: TextAlign.center,
                                      style: _style(11, 14, _muted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          '완료',
                                          style: _style(13, 19, _secondary),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '4',
                                      key: const ValueKey('all_done_count'),
                                      style: _style(11, 14, _muted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppGlassSurface(
                                key: const ValueKey('all_done_list'),
                                borderRadius: BorderRadius.circular(22),
                                gradient: AppColors.glassSoftGradient,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 17,
                                  vertical: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x143D3329),
                                    offset: Offset(0, 12),
                                    blurRadius: 32,
                                  ),
                                ],
                                child: Column(
                                  children: [
                                    for (final (index, example)
                                        in _examples.indexed) ...[
                                      if (index > 0)
                                        const Opacity(
                                          opacity: 0.6,
                                          child: Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Color(0xFFE6E1D6),
                                          ),
                                        ),
                                      _completedRow(
                                        example.id,
                                        example.name,
                                        example.detail,
                                        example.avatar,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppBottomNavigation(
                          key: const ValueKey('all_done_navigation'),
                          currentTab: AppTab.habitat,
                          labelMaxLines: 2,
                          labelStyle: _style(10, 13),
                          selectedLabelColor: _ink,
                          unselectedLabelColor: _secondary,
                          iconAssets: const {
                            AppTab.habitat:
                                'assets/icons/home_first_visit_nav_home.svg',
                            AppTab.records:
                                'assets/icons/home_first_visit_nav_record.svg',
                            AppTab.pets:
                                'assets/icons/home_first_visit_nav_pets.svg',
                            AppTab.profile:
                                'assets/icons/home_first_visit_nav_profile.svg',
                          },
                          onTabSelected: (_) =>
                              _notice('이 미리보기에서는 하단 탭 이동이 연결되지 않았습니다.'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => ConstrainedBox(
    key: const ValueKey('all_done_header'),
    constraints: const BoxConstraints(minHeight: 44),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('10월 20일 화요일', style: _style(11, 14, _muted)),
              Semantics(
                header: true,
                child: Text('오늘 할 일', style: _style(13, 19)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('all_done_multi'),
              borderRadius: BorderRadius.circular(999),
              onTap: () => _notice('일괄 선택 기능은 아직 연결되지 않았습니다.'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Center(
                  widthFactor: 1,
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    child: Text('여러 개 선택', style: _style(12, 16, _secondary)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _avatar(String letter, String id) => Container(
    key: ValueKey('all_done_avatar_$id'),
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF2F6B57),
      border: Border.all(color: const Color(0xE6FFFFFF)),
    ),
    child: Text(letter, style: _style(10, 13, Colors.white)),
  );

  Widget _completedRow(String id, String name, String detail, String letter) {
    void previewOnly() => _notice('디자인 미리보기입니다. 실제 기록은 변경되지 않습니다.');
    return Semantics(
      button: true,
      label: '$name, $detail, 완료 예시',
      excludeSemantics: true,
      onTap: previewOnly,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('all_done_row_$id'),
          onTap: previewOnly,
          child: Opacity(
            key: ValueKey('all_done_opacity_$id'),
            opacity: 0.6,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Row(
                  children: [
                    _avatar(letter, 'row_$id'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name, style: _style(13, 19)),
                          const SizedBox(height: 2),
                          Text(detail, style: _style(11, 14, _muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SvgPicture.asset(
                      'assets/icons/today_tasks_all_done_check.svg',
                      key: ValueKey('all_done_check_$id'),
                      width: 20,
                      height: 20,
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
