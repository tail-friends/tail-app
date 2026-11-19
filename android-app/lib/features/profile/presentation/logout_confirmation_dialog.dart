import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

enum LogoutConfirmationResult { cancel, confirm }

const logoutConfirmationScrim = Color.fromRGBO(47, 107, 87, .28);
final _openDialogs = Expando<bool>('logout confirmation');

/// Presents a UI intent only; never changes authentication or account data.
/// Duplicate requests on the same root navigator are ignored as cancellation.
Future<LogoutConfirmationResult> showLogoutConfirmationDialog(
  BuildContext context,
) async {
  if (!context.mounted) return LogoutConfirmationResult.cancel;
  final navigator = Navigator.of(context, rootNavigator: true);
  if (_openDialogs[navigator] ?? false) return LogoutConfirmationResult.cancel;
  _openDialogs[navigator] = true;
  try {
    final route = DialogRoute<LogoutConfirmationResult>(
      context: context,
      builder: (_) => const LogoutConfirmationDialog(),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      requestFocus: true,
      settings: const RouteSettings(name: 'logout-confirmation'),
      barrierColor: logoutConfirmationScrim,
      barrierLabel: '로그아웃 확인 닫기',
      barrierDismissible: true,
      // Center on the whole frame, rather than an asymmetric status-bar inset.
      useSafeArea: false,
    );
    final result = await navigator.push(route);
    // Keep the lock during the exit animation as well as while visible.
    await route.completed;
    return result ?? LogoutConfirmationResult.cancel;
  } finally {
    _openDialogs[navigator] = null;
  }
}

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  State<LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog> {
  static const _ink = Color(0xFF2B2A26);
  bool _resolved = false;

  void _finish(LogoutConfirmationResult result) {
    if (!mounted || _resolved || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _resolved = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final horizontal = math.max(
      24.0,
      math.max(media.viewPadding.left, media.viewPadding.right),
    );
    final vertical = math.max(
      24.0,
      math.max(media.viewPadding.top, media.viewPadding.bottom),
    );
    final buttonStyle = AppTypography.titleMedium.copyWith(
      fontFamily: 'Jua',
      color: _ink,
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      constraints: const BoxConstraints(maxWidth: 310),
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: '로그아웃 확인',
        child: Container(
          key: const ValueKey('logout_confirmation_surface'),
          width: 310,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.borderGlass),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x291F1C1A),
                offset: Offset(0, 20),
                blurRadius: 40,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: SingleChildScrollView(
              key: const ValueKey('logout_confirmation_scroll'),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      '로그아웃할까요?',
                      key: const ValueKey('logout_confirmation_title'),
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: 'Jua',
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '기록은 계정에 안전하게 보관돼요.',
                    key: const ValueKey('logout_confirmation_description'),
                    textAlign: TextAlign.center,
                    style: AppTypography.captionRegular.copyWith(
                      fontFamily: 'Jua',
                      color: const Color(0xFF6B675E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AppButton(
                            key: const ValueKey('logout_confirmation_cancel'),
                            label: '취소',
                            onPressed: () =>
                                _finish(LogoutConfirmationResult.cancel),
                            variant: AppButtonVariant.ghost,
                            minHeight: 48,
                            foregroundColor: _ink,
                            textStyle: buttonStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppGlassSurface(
                            key: const ValueKey('logout_confirmation_confirm'),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            blur: 0,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3E2C2), Color(0xFFF3E2C2)],
                            ),
                            borderColor: const Color(0xFFE6E1D6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A804D40),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                            child: TextButton(
                              key: const ValueKey(
                                'logout_confirmation_confirm_button',
                              ),
                              onPressed: () =>
                                  _finish(LogoutConfirmationResult.confirm),
                              style: TextButton.styleFrom(
                                foregroundColor: _ink,
                                minimumSize: const Size(44, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const StadiumBorder(),
                                textStyle: buttonStyle,
                              ),
                              child: const Text('로그아웃'),
                            ),
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
      ),
    );
  }
}
