import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/profile/presentation/data_photo_settings_screen.dart';
import 'features/profile/presentation/vet_pdf_report_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/vet_pdf_report_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const VetPdfReportPreviewHost(),
    ),
  );
}

class VetPdfReportPreviewHost extends StatefulWidget {
  const VetPdfReportPreviewHost({super.key});
  @override
  State<VetPdfReportPreviewHost> createState() => _HostState();
}

class _HostState extends State<VetPdfReportPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showVetPdfReportPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const DataPhotoSettingsScreen.preview();
}
