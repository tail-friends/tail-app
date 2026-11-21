import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

enum AccountWithdrawalConfirmationResult { cancel, confirm }

const accountWithdrawalConfirmationScrim = Color.fromRGBO(47, 107, 87, .28);
final _openDialogs = Expando<bool>('account withdrawal confirmation');

/// Returns a presentation intent only; never deletes accounts or stored data.
Future<AccountWithdrawalConfirmationResult>
showAccountWithdrawalConfirmationDialog(BuildContext context) async {
  if (!context.mounted) return AccountWithdrawalConfirmationResult.cancel;
  final navigator = Navigator.of(context, rootNavigator: true);
  if (_openDialogs[navigator] ?? false) {
    return AccountWithdrawalConfirmationResult.cancel;
  }
  _openDialogs[navigator] = true;
  try {
    final route = DialogRoute<AccountWithdrawalConfirmationResult>(
      context: context,
      builder: (_) => const AccountWithdrawalConfirmationDialog(),
      settings: const RouteSettings(name: 'account-withdrawal-confirmation'),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      requestFocus: true,
      barrierColor: accountWithdrawalConfirmationScrim,
      barrierLabel: '탈퇴 최종 확인 닫기',
      barrierDismissible: true,
      useSafeArea: false,
    );
    final result = await navigator.push(route);
    // Opening remains locked until the closing transition actually finishes.
    await route.completed;
    return result ?? AccountWithdrawalConfirmationResult.cancel;
  } finally {
    _openDialogs[navigator] = null;
  }
}

class AccountWithdrawalConfirmationDialog extends StatefulWidget {
  const AccountWithdrawalConfirmationDialog({super.key});

  @override
  State<AccountWithdrawalConfirmationDialog> createState() =>
      _AccountWithdrawalConfirmationDialogState();
}

class _AccountWithdrawalConfirmationDialogState
    extends State<AccountWithdrawalConfirmationDialog> {
  static const _ink = Color(0xFF2B2A26);
  bool _resolved = false;

  void _finish(AccountWithdrawalConfirmationResult result) {
    if (!mounted || _resolved || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _resolved = true;
    Navigator.of(context).pop(result);
  }

  Widget _button({required bool confirm}) {
    final result = confirm
        ? AccountWithdrawalConfirmationResult.confirm
        : AccountWithdrawalConfirmationResult.cancel;
    return AppGlassSurface(
      key: ValueKey(
        'withdrawal_confirmation_${confirm ? 'confirm_surface' : 'cancel_surface'}',
      ),
      borderRadius: BorderRadius.circular(AppRadius.full),
      blur: confirm ? 0 : 18,
      gradient: confirm
          ? const LinearGradient(colors: [Color(0xFFC0463A), Color(0xFFC0463A)])
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              transform: GradientRotation(-.35371),
              colors: [Color(0xB3FFFFFF), Color(0x59FFFFFF)],
            ),
      borderColor: confirm ? const Color(0xFFE6E1D6) : Colors.white,
      boxShadow: confirm
          ? const [
              BoxShadow(
                color: Color(0x1A804D40),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ]
          : const [],
      child: TextButton(
        key: ValueKey(
          'withdrawal_confirmation_${confirm ? 'confirm' : 'cancel'}',
        ),
        onPressed: () => _finish(result),
        style: TextButton.styleFrom(
          foregroundColor: confirm ? Colors.white : _ink,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
          textStyle: AppTypography.titleMedium.copyWith(fontFamily: 'Jua'),
        ),
        child: Text(confirm ? '탈퇴' : '취소'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      constraints: const BoxConstraints(maxWidth: 310),
      // Symmetric safe insets keep the dialog centered on the complete frame.
      insetPadding: EdgeInsets.symmetric(
        horizontal: math.max(
          24,
          math.max(media.viewPadding.left, media.viewPadding.right),
        ),
        vertical: math.max(
          24,
          math.max(media.viewPadding.top, media.viewPadding.bottom),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: '탈퇴 최종 확인',
        child: Container(
          key: const ValueKey('withdrawal_confirmation_surface'),
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
              key: const ValueKey('withdrawal_confirmation_scroll'),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      '탈퇴할까요?',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: 'Jua',
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '모든 기록과 캐릭터가 즉시 삭제돼요.',
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
                        Expanded(child: _button(confirm: false)),
                        const SizedBox(width: 8),
                        Expanded(child: _button(confirm: true)),
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
