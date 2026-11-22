import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/notification_time_preview_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/notification_time_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 알림 시간 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const NotificationTimePreviewHost(),
    ),
  );
}

class NotificationTimePreviewHost extends StatefulWidget {
  const NotificationTimePreviewHost({super.key});
  @override
  State<NotificationTimePreviewHost> createState() =>
      _NotificationTimePreviewHostState();
}

class _NotificationTimePreviewHostState
    extends State<NotificationTimePreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showNotificationTimePreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
