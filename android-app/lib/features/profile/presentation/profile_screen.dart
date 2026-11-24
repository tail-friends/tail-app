import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/terms_preview_screen.dart';
import 'account_management_screen.dart';
import 'data_photo_settings_screen.dart';
import 'inquiry_screen.dart';
import 'notices_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_edit_screen.dart';
import 'terrarium_theme_screen.dart';
import 'warning_units_screen.dart';

const profilePreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 민준, 카카오 로그인, 친구 7명, 기록 128개, 함께한 날 410일, 사막 테마와 앱 버전은 시안 예시입니다. 실제 계정·기록·설정을 조회하거나 변경하지 않습니다. 연결된 화면도 Debug 미리보기이며 실제 로그인이나 저장은 실행되지 않습니다.';
final _previewInProgress = Expando<bool>();

Future<void> showProfilePreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewInProgress[navigator] == true) return;
  _previewInProgress[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(profilePreviewNotice),
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
    if (accepted != true || !context.mounted || !navigator.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => const ProfileScreen.preview()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// Figma 09 fixture only. No account, record, authentication or storage service.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen.preview({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _shadow = [
    BoxShadow(color: Color(0x143D3329), offset: Offset(0, 12), blurRadius: 32),
  ];
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _opening = false;

  TextStyle _style(double size, double height, [Color color = _ink]) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: height / size,
        color: color,
        letterSpacing: size == 13 ? -0.1 : 0,
      );

  void _notice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 94),
          content: Text(message),
        ),
      );
  }

  Future<void> _open(Future<void> Function(BuildContext) showPreview) async {
    if (_opening || !kDebugMode) return;
    _opening = true;
    _messenger.currentState?.removeCurrentSnackBar();
    try {
      await showPreview(context);
    } finally {
      _opening = false;
    }
  }

  Future<void> _terms(BuildContext context) async {
    final navigator = Navigator.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(
          '약관 내용과 시행일은 Figma 시안이며 확정된 법적 계약이 아닙니다. 실제 동의나 저장은 실행되지 않습니다.',
        ),
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
    if (accepted == true && context.mounted && navigator.mounted) {
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const TermsPreviewScreen()),
      );
    }
  }

  void _back() {
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
        if (!didPop) _back();
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
            key: const ValueKey('profile_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Original isolated Figma bg 408:2343, including SVG blur filters.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/profile_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('profile_scroll'),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            math.max(8, 62 - MediaQuery.paddingOf(context).top),
                            24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 20,
                            children: [
                              Semantics(
                                header: true,
                                child: Text('마이', style: _style(13, 19)),
                              ),
                              _profile(),
                              _stats(),
                              _heading('설정', size: 12, height: 16),
                              _group([
                                _row(
                                  '알림 설정',
                                  icon: 'home_bell.svg',
                                  onTap: () =>
                                      _open(showNotificationSettingsPreview),
                                ),
                                _row(
                                  '사육장 테마',
                                  icon: 'profile_settings_home.svg',
                                  trailing: '사막',
                                  onTap: () => _open(showTerrariumThemePreview),
                                ),
                                _row(
                                  '경고 기준 · 온도 단위',
                                  pending: true,
                                  onTap: () => _open(showWarningUnitsPreview),
                                ),
                                _row(
                                  '데이터 · 사진 · 내보내기',
                                  pending: true,
                                  onTap: () =>
                                      _open(showDataPhotoSettingsPreview),
                                ),
                                _row(
                                  '일정 · 재고',
                                  pending: true,
                                  onTap: () =>
                                      _notice('일정·재고 기능은 아직 연결되지 않았습니다.'),
                                ),
                                _row(
                                  '건강 관리',
                                  onTap: () =>
                                      _notice('건강 관리 기능은 아직 연결되지 않았습니다.'),
                                ),
                              ]),
                              _heading('고객센터'),
                              _group([
                                _row(
                                  '공지사항',
                                  icon: 'home_first_visit_record.svg',
                                  onTap: () => _open(showNoticesPreview),
                                ),
                                _row(
                                  '문의하기',
                                  icon: 'profile_support_user.svg',
                                  onTap: () => _open(showInquiryPreview),
                                ),
                              ]),
                              _heading('약관'),
                              _group([
                                _row('서비스 이용약관', onTap: () => _open(_terms)),
                                _row(
                                  '개인정보 처리방침',
                                  onTap: () => _open(showPrivacyPolicyPreview),
                                ),
                                _row(
                                  '계정 관리',
                                  onTap: () =>
                                      _open(showAccountManagementPreview),
                                ),
                                _row('앱 버전', trailing: '1.0.0'),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                        child: AppBottomNavigation(
                          key: const ValueKey('profile_navigation'),
                          currentTab: AppTab.profile,
                          labelMaxLines: 2,
                          labelStyle: _style(10, 13),
                          unselectedLabelColor: _secondary,
                          selectedLabelColor: _ink,
                          iconAssets: const {
                            AppTab.habitat:
                                'assets/icons/pet_list_empty_nav_home.svg',
                            AppTab.records:
                                'assets/icons/home_first_visit_nav_record.svg',
                            AppTab.pets:
                                'assets/icons/home_first_visit_nav_pets.svg',
                            AppTab.profile: 'assets/icons/profile_nav_user.svg',
                          },
                          onTabSelected: (tab) {
                            if (tab != AppTab.profile) {
                              _notice('이 미리보기에서는 하단 탭 이동이 연결되지 않았습니다.');
                            }
                          },
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

  Widget _heading(String label, {double size = 11, double height = 14}) =>
      Semantics(
        header: true,
        child: Text(label, style: _style(size, height, _secondary)),
      );

  Widget _profile() => AppGlassSurface(
    key: const ValueKey('profile_card'),
    borderRadius: BorderRadius.circular(24),
    gradient: AppColors.glassSoftGradient,
    boxShadow: _shadow,
    padding: const EdgeInsets.all(19),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(13) > 19;
        final identity = Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Text('민', style: _style(13, 19)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('민준', style: _style(13, 19)),
                  const SizedBox(height: 2),
                  Text('카카오 계정으로 로그인 중', style: _style(11, 14, _muted)),
                ],
              ),
            ),
          ],
        );
        final edit = Semantics(
          button: true,
          child: InkWell(
            key: const ValueKey('profile_edit'),
            onTap: () => _open(showProfileEditPreview),
            borderRadius: BorderRadius.circular(999),
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
                  child: Text('프로필 편집', style: _style(12, 16, _secondary)),
                ),
              ),
            ),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              identity,
              Align(alignment: Alignment.centerRight, child: edit),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 14),
            edit,
          ],
        );
      },
    ),
  );

  Widget _stats() => Row(
    key: const ValueKey('profile_stats'),
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      for (final item in [('7', '친구'), ('128', '기록'), ('410', '함께한 날')])
        Expanded(
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.glassSoftGradient,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
            child: Column(
              children: [
                Text(
                  item.$1,
                  style: _style(16, 22).copyWith(letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: _style(11, 14, _muted),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _group(List<Widget> rows) => AppGlassSurface(
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    boxShadow: _shadow,
    padding: const EdgeInsets.all(1),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE6E1D6)),
          rows[index],
        ],
      ],
    ),
  );

  Widget _row(
    String label, {
    String? icon,
    String? trailing,
    bool pending = false,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 10,
        children: [
          if (icon != null)
            SvgPicture.asset(
              'assets/icons/$icon',
              width: 18,
              height: 18,
              excludeFromSemantics: true,
            ),
          Expanded(child: Text(label, style: _style(13, 19))),
          if (trailing != null)
            Text(trailing, style: _style(13, 19, _secondary)),
          if (pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('준비 중', style: _style(10, 12, _secondary)),
            ),
          if (onTap != null)
            SvgPicture.asset(
              'assets/icons/home_metric_chevron_right.svg',
              width: 14,
              height: 14,
              excludeFromSemantics: true,
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('profile_menu_$label'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: content,
          ),
        ),
      ),
    );
  }
}
