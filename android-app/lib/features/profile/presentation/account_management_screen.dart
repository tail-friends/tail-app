import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'account_withdrawal_confirmation_dialog.dart';
import 'account_withdrawal_screen.dart';
import 'logout_confirmation_dialog.dart';

const accountManagementPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 카카오 연결 정보와 가입일은 예시이며, 실제 로그아웃이나 회원 탈퇴는 실행되지 않습니다.';

Future<void> showAccountManagementPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(accountManagementPreviewNotice),
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
  if (accepted != true || !context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const AccountManagementScreen.preview()),
  );
}

/// Figma 09-3 examples, never an authenticated user's account screen.
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen.preview({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

enum _AccountAction { logout, deleteAccount }

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  static const _danger = Color(0xFFB23B30);
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _actionInProgress = false;

  void _showNotice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // These are Debug presentation intents, not authentication operations.
  Future<void> _onAction(_AccountAction action) async {
    if (!kDebugMode ||
        !mounted ||
        _actionInProgress ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _actionInProgress = true;
    _messenger.currentState?.removeCurrentSnackBar();
    try {
      switch (action) {
        case _AccountAction.logout:
          final result = await showLogoutConfirmationDialog(context);
          if (!mounted || result != LogoutConfirmationResult.confirm) return;
          _showNotice('로그아웃 기능은 아직 연결되지 않았습니다.');
        case _AccountAction.deleteAccount:
          await showAccountWithdrawalPreview(
            context,
            confirmPreview: (context) async =>
                await showAccountWithdrawalConfirmationDialog(context) ==
                AccountWithdrawalConfirmationResult.confirm,
          );
      }
    } catch (_) {
      if (mounted) _showNotice('미리보기 화면을 열지 못했어요. 다시 시도해 주세요.');
    } finally {
      _actionInProgress = false;
    }
  }

  void _back() {
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
            key: const ValueKey('account_management_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma bg 408:2347 export is byte-identical to this local asset.
                Image.asset(
                  'assets/images/pet_registration_complete_background.png',
                  key: const ValueKey('account_management_background'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SingleChildScrollView(
                    key: const ValueKey('account_management_scroll'),
                    padding: EdgeInsets.only(
                      top: math.max(4, 58 - MediaQuery.paddingOf(context).top),
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 20),
                        Text(
                          '로그인 정보',
                          key: const ValueKey('account_management_section'),
                          style: AppTypography.labelMedium.copyWith(
                            fontFamily: 'Jua',
                            color: _secondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          container: true,
                          label: 'Figma 예시 계정 정보',
                          child: _AccountGlassGroup(
                            key: const ValueKey('account_management_info'),
                            child: Padding(
                              // Includes the original 1px border.
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '카카오',
                                    style: AppTypography.bodyRegular.copyWith(
                                      fontFamily: 'Jua',
                                      color: _ink,
                                    ),
                                  ),
                                  Text(
                                    '연결됨 · 2025년 9월 6일 가입',
                                    style: AppTypography.captionRegular
                                        .copyWith(
                                          fontFamily: 'Jua',
                                          color: _tertiary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _AccountGlassGroup(
                          key: const ValueKey('account_management_actions'),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                _AccountActionRow(
                                  key: const ValueKey(
                                    'account_management_logout',
                                  ),
                                  label: '로그아웃',
                                  onTap: () => _onAction(_AccountAction.logout),
                                  style: AppTypography.bodyRegular.copyWith(
                                    fontFamily: 'Jua',
                                    color: _ink,
                                  ),
                                  minHeight: 47,
                                  padding: const EdgeInsets.fromLTRB(
                                    17,
                                    15,
                                    17,
                                    13,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 1),
                                  child: SizedBox(
                                    key: ValueKey('account_management_divider'),
                                    width: double.infinity,
                                    height: 1,
                                    child: ColoredBox(color: Color(0xFFE6E1D6)),
                                  ),
                                ),
                                _AccountActionRow(
                                  key: const ValueKey(
                                    'account_management_delete',
                                  ),
                                  label: '회원 탈퇴',
                                  onTap: () =>
                                      _onAction(_AccountAction.deleteAccount),
                                  style: AppTypography.captionRegular.copyWith(
                                    fontFamily: 'Jua',
                                    color: _danger,
                                  ),
                                  minHeight: 44,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 17,
                                    vertical: 15,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => ConstrainedBox(
    key: const ValueKey('account_management_header'),
    constraints: const BoxConstraints(minHeight: 44),
    child: Row(
      children: [
        Semantics(
          label: '뒤로가기',
          button: true,
          excludeSemantics: true,
          onTap: _back,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('account_management_back'),
              onTap: _back,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: SizedBox.square(
                dimension: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppGlassSurface(
                    key: const ValueKey('account_management_back_surface'),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 16,
                          child: FittedBox(
                            child: SvgPicture.asset(
                              'assets/icons/terms_chevron_left.svg',
                              key: const ValueKey(
                                'account_management_back_icon',
                              ),
                              // Preserve the original SVG root size; fit into its 16px slot.
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
        Expanded(
          child: Padding(
            // Balance the 44px hit target against the original 36px empty slot.
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              header: true,
              child: Text(
                '계정 관리',
                key: const ValueKey('account_management_title'),
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  fontFamily: 'Jua',
                  color: _ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox.square(
          key: ValueKey('account_management_right_space'),
          dimension: 36,
        ),
      ],
    ),
  );
}

class _AccountGlassGroup extends StatelessWidget {
  const _AccountGlassGroup({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    child: child,
  );
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.label,
    required this.onTap,
    required this.style,
    required this.minHeight,
    required this.padding,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final TextStyle style;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight, minWidth: 44),
        child: Padding(
          padding: padding,
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
        ),
      ),
    ),
  );
}
