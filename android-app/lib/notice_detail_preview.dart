import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/notice_detail_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/notice_detail_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 공지 상세 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const NoticeDetailPreviewHost(),
    ),
  );
}

class NoticeDetailPreviewHost extends StatefulWidget {
  const NoticeDetailPreviewHost({super.key});
  @override
  State<NoticeDetailPreviewHost> createState() =>
      _NoticeDetailPreviewHostState();
}

class _NoticeDetailPreviewHostState extends State<NoticeDetailPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showNoticeDetailPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
