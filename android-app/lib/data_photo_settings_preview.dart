import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/data_photo_settings_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/data_photo_settings_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 데이터·사진 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const DataPhotoSettingsPreviewHost(),
    ),
  );
}

class DataPhotoSettingsPreviewHost extends StatefulWidget {
  const DataPhotoSettingsPreviewHost({super.key});
  @override
  State<DataPhotoSettingsPreviewHost> createState() => _HostState();
}

class _HostState extends State<DataPhotoSettingsPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showDataPhotoSettingsPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
