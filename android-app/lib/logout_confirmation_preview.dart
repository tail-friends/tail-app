import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'core/design_system/widgets/app_glass_surface.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/logout_confirmation_dialog.dart';
import 'main.dart' as app;

const logoutConfirmationPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 카카오 연결 정보·가입일·기록 보관 안내는 시안 예시이며, 실제 로그아웃·세션 삭제·토큰 삭제는 실행되지 않습니다.';

/// flutter run --target lib/logout_confirmation_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 로그아웃 확인 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const LogoutConfirmationPreviewHost(),
    ),
  );
}

class LogoutConfirmationPreviewHost extends StatefulWidget {
  const LogoutConfirmationPreviewHost({super.key});

  @override
  State<LogoutConfirmationPreviewHost> createState() =>
      _LogoutConfirmationPreviewHostState();
}

class _LogoutConfirmationPreviewHostState
    extends State<LogoutConfirmationPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
    }
  }

  Future<void> _enter() async {
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(logoutConfirmationPreviewNotice),
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
    if (!mounted || accepted != true) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _LogoutDesignPreview()),
    );
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}

class _LogoutDesignPreview extends StatefulWidget {
  const _LogoutDesignPreview();
  @override
  State<_LogoutDesignPreview> createState() => _LogoutDesignPreviewState();
}

class _LogoutDesignPreviewState extends State<_LogoutDesignPreview> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  Future<void> _open() async {
    if (!kDebugMode || !mounted || _opening) return;
    _opening = true;
    _messenger.currentState?.removeCurrentSnackBar();
    try {
      final result = await showLogoutConfirmationDialog(context);
      if (mounted && result == LogoutConfirmationResult.confirm) {
        _messenger.currentState?.showSnackBar(
          const SnackBar(content: Text('로그아웃 기능은 아직 연결되지 않았습니다.')),
        );
      }
    } finally {
      _opening = false;
    }
  }

  void _exit() {
    _messenger.currentState?.removeCurrentSnackBar();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
          key: const ValueKey('logout_preview_screen'),
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/pet_registration_complete_background.png',
                key: const ValueKey('logout_preview_background'),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: math.max(4, 58 - MediaQuery.paddingOf(context).top),
                    bottom: 24,
                  ),
                  child: _PreviewBackdrop(onBack: _exit, onOpen: _open),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal Figma background presentation, not the account-management feature.
/// No dependency on account_management_screen.dart or its preview entry point.
class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop({required this.onBack, required this.onOpen});
  final VoidCallback onBack;
  final VoidCallback onOpen;

  static TextStyle _text(double size, double line, Color color) => TextStyle(
    fontFamily: 'Jua',
    fontSize: size,
    height: line / size,
    color: color,
    letterSpacing: size == 14
        ? -.2
        : size == 13
        ? -.1
        : null,
  );
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);

  Widget _group(Widget child) => AppGlassSurface(
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    padding: const EdgeInsets.all(1),
    child: child,
  );

  Widget _row(String label, TextStyle style) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 10),
        SvgPicture.asset(
          'assets/icons/home_metric_chevron_right.svg',
          width: 14,
          height: 14,
          excludeFromSemantics: true,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: '미리보기 닫기',
                  button: true,
                  excludeSemantics: true,
                  onTap: onBack,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey('logout_preview_back'),
                      onTap: onBack,
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
                                child: SizedBox.square(
                                  dimension: 16,
                                  child: FittedBox(
                                    child: SvgPicture.asset(
                                      'assets/icons/terms_chevron_left.svg',
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
                ),
                const SizedBox.square(dimension: 36),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                '계정 관리',
                textAlign: TextAlign.center,
                style: _text(14, 20, _ink),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text('로그인 정보', style: _text(12, 16, const Color(0xFF6B675E))),
      const SizedBox(height: 20),
      Semantics(
        label: 'Figma 예시 계정 정보',
        container: true,
        child: _group(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('카카오', style: _text(13, 19, _ink)),
                Text('연결됨 · 2025년 9월 6일 가입', style: _text(11, 14, _muted)),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _group(
        Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Semantics(
                label: '로그아웃 확인 미리보기 열기',
                button: true,
                excludeSemantics: true,
                onTap: onOpen,
                child: InkWell(
                  key: const ValueKey('logout_preview_open'),
                  onTap: onOpen,
                  child: _row('로그아웃', _text(13, 19, _ink)),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE6E1D6))),
                ),
                child: _row('회원 탈퇴', _text(11, 14, const Color(0xFFB23B30))),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
