import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/profile_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 마이 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const ProfilePreviewHost(),
    ),
  );
}

class ProfilePreviewHost extends StatefulWidget {
  const ProfilePreviewHost({super.key});
  @override
  State<ProfilePreviewHost> createState() => _HostState();
}

class _HostState extends State<ProfilePreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showProfilePreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
