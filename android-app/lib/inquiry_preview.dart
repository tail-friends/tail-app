import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/inquiry_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/inquiry_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 문의하기 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const InquiryPreviewHost(),
    ),
  );
}

class InquiryPreviewHost extends StatefulWidget {
  const InquiryPreviewHost({super.key});
  @override
  State<InquiryPreviewHost> createState() => _InquiryPreviewHostState();
}

class _InquiryPreviewHostState extends State<InquiryPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showInquiryPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
