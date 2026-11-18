import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/account_management_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/account_management_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 계정 관리 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const AccountManagementPreviewHost(),
    ),
  );
}

class AccountManagementPreviewHost extends StatefulWidget {
  const AccountManagementPreviewHost({super.key});

  @override
  State<AccountManagementPreviewHost> createState() =>
      _AccountManagementPreviewHostState();
}

class _AccountManagementPreviewHostState
    extends State<AccountManagementPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAccountManagementPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
