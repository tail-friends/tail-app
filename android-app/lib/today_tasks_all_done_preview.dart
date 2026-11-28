import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/today_tasks_all_done_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/today_tasks_all_done_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 다 챙김 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const TodayTasksAllDonePreviewHost(),
    ),
  );
}

class TodayTasksAllDonePreviewHost extends StatefulWidget {
  const TodayTasksAllDonePreviewHost({super.key});
  @override
  State<TodayTasksAllDonePreviewHost> createState() => _HostState();
}

class _HostState extends State<TodayTasksAllDonePreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showTodayTasksAllDonePreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
