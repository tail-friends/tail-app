import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/home/presentation/home_screen.dart';
import 'main.dart' as app;

/// Run with: flutter run --target lib/home_first_visit_preview.dart
/// Release/Profile use the normal login entry point even with this target.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends — 홈 첫 방문 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const HomeScreen.firstVisitPreview(),
    ),
  );
}
