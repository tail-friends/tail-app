import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/notices_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/notices_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 공지사항 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const NoticesPreviewHost(),
    ),
  );
}

class NoticesPreviewHost extends StatefulWidget {
  const NoticesPreviewHost({super.key});
  @override
  State<NoticesPreviewHost> createState() => _NoticesPreviewHostState();
}

class _NoticesPreviewHostState extends State<NoticesPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showNoticesPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
