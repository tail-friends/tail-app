import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const healthAlertsNotice =
    '이 화면은 디자인 미리보기입니다. 치토·레오·욱이·세라와 체중·습도·증상·경고는 모두 Figma 예시이며 실제 건강 분석, 진단, 알림 또는 기록 조회가 아닙니다.';
const _tabs = ['경고', '사진 체크', '진료', '온습도'];
const _history = [
  (name: '욱이 · 거식 3번 연속', detail: '9월 2일 · 해제', avatar: '욱'),
  (name: '세라 · 묽은 변 2번 연속', detail: '8월 14일 · 해제', avatar: '세'),
];
final _healthNavs = Expando<bool>();
Future<void> showHealthAlertsPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final nav = Navigator.of(context);
  if (_healthNavs[nav] == true) return;
  _healthNavs[nav] = true;
  try {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(healthAlertsNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('미리보기 열기'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted || !nav.mounted) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => const HealthAlertsScreen.preview(),
    );
    await nav.push(route);
    await route.completed;
  } finally {
    _healthNavs[nav] = false;
  }
}

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen.preview({super.key});
  @override
  State<HealthAlertsScreen> createState() => _HealthState();
}

class _HealthState extends State<HealthAlertsScreen> {
  static const green = Color(0xff2f6b57),
      ink = Color(0xff2b2a26),
      muted = Color(0xff736e65);
  final messenger = GlobalKey<ScaffoldMessengerState>();
  bool leaving = false;
  TextStyle st(double s, double h, [Color c = ink]) => AppTypography.bodyRegular
      .copyWith(fontFamily: 'Jua', fontSize: s, height: h / s, color: c);
  void back() {
    if (leaving) return;
    leaving = true;
    final n = Navigator.of(context);
    if (n.canPop()) {
      n.pop();
    } else {
      n.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void note(String s) {
    messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(s)),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (did, _) {
        if (!did) back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: ScaffoldMessenger(
          key: messenger,
          child: Scaffold(
            backgroundColor: const Color(0xfffaf7f0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/warning_units_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      math.max(4, 58 - MediaQuery.paddingOf(context).top),
                      24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 18),
                        _tabbar(),
                        const SizedBox(height: 18),
                        _alert(
                          name: '치토 · 체중 12% 감소',
                          detail: '최근 30일 468g → 412g',
                          avatar: '치',
                          color: const Color(0xffb23b30),
                          first: true,
                        ),
                        const SizedBox(height: 18),
                        _alert(
                          name: '레오 · 습도 범위 밖',
                          detail: '38% · 적정 60–80%',
                          avatar: '레',
                          color: const Color(0xff96570c),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '지난 경고',
                          style: st(13, 19, const Color(0xff6b675e)),
                        ),
                        const SizedBox(height: 14),
                        AppGlassSurface(
                          key: const ValueKey('health_history'),
                          borderRadius: BorderRadius.circular(22),
                          gradient: AppColors.glassSoftGradient,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x143d3329),
                              offset: Offset(0, 12),
                              blurRadius: 32,
                            ),
                          ],
                          child: Column(
                            children: [
                              for (var i = 0; i < _history.length; i++) ...[
                                _historyRow(i),
                                if (i == 0)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xffe6e1d6),
                                  ),
                              ],
                            ],
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
      ),
    );
  }

  Widget _header() => Row(
    key: const ValueKey('health_header'),
    children: [
      Semantics(
        label: '뒤로가기',
        button: true,
        child: SizedBox.square(
          dimension: 44,
          child: GestureDetector(
            key: const ValueKey('health_back'),
            behavior: HitTestBehavior.opaque,
            onTap: back,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppGlassSurface(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/terms_chevron_left.svg',
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Text('건강 관리', textAlign: TextAlign.center, style: st(14, 20)),
      ),
      const SizedBox(width: 44),
    ],
  );
  Widget _tabbar() => AppGlassSurface(
    key: const ValueKey('health_tabs'),
    borderRadius: BorderRadius.circular(999),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.all(3),
    child: Row(
      children: [
        for (var i = 0; i < _tabs.length; i++) ...[
          if (i == 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xfff3efe6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('준비 중', style: st(10, 13, const Color(0xff6b675e))),
            ),
          Expanded(
            child: Semantics(
              key: ValueKey('health_tab_$i'),
              label: _tabs[i],
              button: true,
              selected: i == 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i != 0) note('이 화면은 아직 연결되지 않았습니다.');
                },
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: i == 0
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xffe6e1d6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x193d2e1f),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        )
                      : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _tabs[i],
                      style: st(12, 16, i == 0 ? ink : muted),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _pill(String label, VoidCallback onTap, {double opacity = 1}) =>
      Opacity(
        opacity: opacity,
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: AppGlassSurface(
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Text(
                      label,
                      style: st(12, 16, const Color(0xff6b675e)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  Widget _alert({
    required String name,
    required String detail,
    required String avatar,
    required Color color,
    bool first = false,
  }) => AppGlassSurface(
    key: ValueKey('alert_$avatar'),
    borderRadius: BorderRadius.circular(22),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xe0ffffff), Color(0xbff3e2c2)],
    ),
    padding: const EdgeInsets.all(15),
    boxShadow: const [
      BoxShadow(color: Color(0x0f3d2e1f), offset: Offset(0, 8), blurRadius: 24),
    ],
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(12) > 18;
        final content = Row(
          children: [
            _avatar(avatar),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: st(13, 19, color)),
                  Text(detail, style: st(11, 14, const Color(0xff6b675e))),
                ],
              ),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact)
              content
            else
              Row(
                children: [
                  Expanded(child: content),
                  _pill('확인', () => note('경고 확인 기능은 미리보기에 연결되지 않았습니다.')),
                ],
              ),
            if (compact)
              Align(
                alignment: Alignment.centerRight,
                child: _pill('확인', () => note('경고 확인 기능은 미리보기에 연결되지 않았습니다.')),
              ),
            if (first) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _pill(
                    '진료 기록',
                    () => note('진료 기록은 아직 연결되지 않았습니다.'),
                    opacity: .45,
                  ),
                  _pill(
                    '사육 가이드',
                    () => note('사육 가이드는 아직 연결되지 않았습니다.'),
                    opacity: .45,
                  ),
                ],
              ),
            ],
          ],
        );
      },
    ),
  );
  Widget _avatar(String t) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: green,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white),
    ),
    child: Text(t, style: st(10, 13, Colors.white)),
  );
  Widget _historyRow(int i) {
    final e = _history[i];
    return Opacity(
      opacity: .65,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _avatar(e.avatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: st(13, 19)),
                  Text(e.detail, style: st(11, 14, muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
