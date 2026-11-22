import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/profile_edit_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/profile_edit_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 프로필 편집 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const ProfileEditPreviewHost(),
    ),
  );
}

class ProfileEditPreviewHost extends StatefulWidget {
  const ProfileEditPreviewHost({super.key});
  @override
  State<ProfileEditPreviewHost> createState() => _ProfileEditPreviewHostState();
}

class _ProfileEditPreviewHostState extends State<ProfileEditPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showProfileEditPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
