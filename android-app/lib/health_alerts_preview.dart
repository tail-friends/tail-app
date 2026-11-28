import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/health/presentation/health_alerts_screen.dart';
import 'main.dart' as app;

void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: '건강 관리 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const HealthAlertsPreviewHost(),
    ),
  );
}

class HealthAlertsPreviewHost extends StatefulWidget {
  const HealthAlertsPreviewHost({super.key});
  @override
  State<HealthAlertsPreviewHost> createState() => _HostState();
}

class _HostState extends State<HealthAlertsPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showHealthAlertsPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
