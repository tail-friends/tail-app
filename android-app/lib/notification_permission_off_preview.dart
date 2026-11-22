import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/notification_settings_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/notification_permission_off_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 알림 권한 꺼짐 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const NotificationPermissionOffPreviewHost(),
    ),
  );
}

class NotificationPermissionOffPreviewHost extends StatefulWidget {
  const NotificationPermissionOffPreviewHost({super.key});
  @override
  State<NotificationPermissionOffPreviewHost> createState() => _HostState();
}

class _HostState extends State<NotificationPermissionOffPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) {
        showNotificationSettingsPreview(context, permissionOff: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
