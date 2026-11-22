import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/privacy_policy_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/privacy_policy_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 개인정보 처리방침 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PrivacyPolicyPreviewHost(),
    ),
  );
}

class PrivacyPolicyPreviewHost extends StatefulWidget {
  const PrivacyPolicyPreviewHost({super.key});
  @override
  State<PrivacyPolicyPreviewHost> createState() =>
      _PrivacyPolicyPreviewHostState();
}

class _PrivacyPolicyPreviewHostState extends State<PrivacyPolicyPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showPrivacyPolicyPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
