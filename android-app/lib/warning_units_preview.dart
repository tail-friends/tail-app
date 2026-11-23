import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/warning_units_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/warning_units_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 경고 기준·단위 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const WarningUnitsPreviewHost(),
    ),
  );
}

class WarningUnitsPreviewHost extends StatefulWidget {
  const WarningUnitsPreviewHost({super.key});
  @override
  State<WarningUnitsPreviewHost> createState() => _HostState();
}

class _HostState extends State<WarningUnitsPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showWarningUnitsPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
