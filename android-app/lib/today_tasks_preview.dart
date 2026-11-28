import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/today_tasks_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/today_tasks_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 오늘 할 일 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const TodayTasksPreviewHost(),
    ),
  );
}

class TodayTasksPreviewHost extends StatefulWidget {
  const TodayTasksPreviewHost({super.key});
  @override
  State<TodayTasksPreviewHost> createState() => _HostState();
}

class _HostState extends State<TodayTasksPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showTodayTasksPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
