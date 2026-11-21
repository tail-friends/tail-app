import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/account_withdrawal_confirmation_dialog.dart';
import 'features/profile/presentation/account_withdrawal_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/account_withdrawal_confirmation_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 탈퇴 최종 확인 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const AccountWithdrawalConfirmationPreviewHost(),
    ),
  );
}

class AccountWithdrawalConfirmationPreviewHost extends StatefulWidget {
  const AccountWithdrawalConfirmationPreviewHost({super.key});

  @override
  State<AccountWithdrawalConfirmationPreviewHost> createState() =>
      _AccountWithdrawalConfirmationPreviewHostState();
}

class _AccountWithdrawalConfirmationPreviewHostState
    extends State<AccountWithdrawalConfirmationPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAccountWithdrawalPreview(
          context,
          confirmPreview: (context) async {
            return await showAccountWithdrawalConfirmationDialog(context) ==
                AccountWithdrawalConfirmationResult.confirm;
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
