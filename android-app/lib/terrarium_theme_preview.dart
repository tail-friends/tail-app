import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/terrarium_theme_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/terrarium_theme_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 사육장 테마 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const TerrariumThemePreviewHost(),
    ),
  );
}

class TerrariumThemePreviewHost extends StatefulWidget {
  const TerrariumThemePreviewHost({super.key});
  @override
  State<TerrariumThemePreviewHost> createState() =>
      _TerrariumThemePreviewHostState();
}

class _TerrariumThemePreviewHostState extends State<TerrariumThemePreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showTerrariumThemePreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
