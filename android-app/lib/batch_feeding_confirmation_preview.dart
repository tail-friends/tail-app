import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/batch_feeding_confirmation_screen.dart';
import 'main.dart' as app;

void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 급여 확인 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const BatchFeedingConfirmationPreviewHost(),
    ),
  );
}

class BatchFeedingConfirmationPreviewHost extends StatefulWidget {
  const BatchFeedingConfirmationPreviewHost({super.key});
  @override
  State<BatchFeedingConfirmationPreviewHost> createState() => _HostState();
}

class _HostState extends State<BatchFeedingConfirmationPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showBatchFeedingConfirmationPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
