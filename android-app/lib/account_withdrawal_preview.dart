import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/account_withdrawal_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/account_withdrawal_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 회원 탈퇴 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const AccountWithdrawalPreviewHost(),
    ),
  );
}

class AccountWithdrawalPreviewHost extends StatefulWidget {
  const AccountWithdrawalPreviewHost({super.key});

  @override
  State<AccountWithdrawalPreviewHost> createState() =>
      _AccountWithdrawalPreviewHostState();
}

class _AccountWithdrawalPreviewHostState
    extends State<AccountWithdrawalPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAccountWithdrawalPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
