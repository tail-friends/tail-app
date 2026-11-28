import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/batch_cleaning_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/batch_cleaning_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 일괄 청소 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const BatchCleaningPreviewHost(),
    ),
  );
}

class BatchCleaningPreviewHost extends StatefulWidget {
  const BatchCleaningPreviewHost({super.key});
  @override
  State<BatchCleaningPreviewHost> createState() => _HostState();
}

class _HostState extends State<BatchCleaningPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showBatchCleaningPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
