import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/batch_record_selection_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/batch_record_selection_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 일괄 선택 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const BatchRecordSelectionPreviewHost(),
    ),
  );
}

class BatchRecordSelectionPreviewHost extends StatefulWidget {
  const BatchRecordSelectionPreviewHost({super.key});
  @override
  State<BatchRecordSelectionPreviewHost> createState() => _HostState();
}

class _HostState extends State<BatchRecordSelectionPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showBatchRecordSelectionPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('일괄 기록 선택 UI 미리보기'),
              const SizedBox(height: 16),
              const Text('독립 디자인 미리보기입니다. 선택은 화면 안에서만 유지되며 실제 기록을 변경하지 않습니다.'),
              const SizedBox(height: 24),
              AppButton(
                label: '선택 미리보기 다시 열기',
                onPressed: () => showBatchRecordSelectionPreview(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
