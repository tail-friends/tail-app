import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/profile/presentation/data_photo_settings_screen.dart';
import 'features/profile/presentation/csv_export_sheet.dart';
import 'main.dart' as app;

/// flutter run --target lib/csv_export_preview.dart
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
      home: const CsvExportPreviewHost(),
    ),
  );
}

class CsvExportPreviewHost extends StatefulWidget {
  const CsvExportPreviewHost({super.key});
  @override
  State<CsvExportPreviewHost> createState() => _HostState();
}

class _HostState extends State<CsvExportPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) showCsvExportPreviewSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) => const DataPhotoSettingsScreen.preview();
}
