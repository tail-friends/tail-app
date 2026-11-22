import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/notification_settings_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/notification_settings_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 알림 설정 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const NotificationSettingsPreviewHost(),
    ),
  );
}

class NotificationSettingsPreviewHost extends StatefulWidget {
  const NotificationSettingsPreviewHost({super.key});
  @override
  State<NotificationSettingsPreviewHost> createState() =>
      _NotificationSettingsPreviewHostState();
}

class _NotificationSettingsPreviewHostState
    extends State<NotificationSettingsPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showNotificationSettingsPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
