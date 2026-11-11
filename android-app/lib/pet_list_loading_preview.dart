import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/pets/presentation/pet_list_loading_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_list_loading_preview.dart
/// Profile/Release always use the ordinary application login entry point.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 개체 목록 로딩 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetListLoadingPreviewHost(),
    ),
  );
}

class PetListLoadingPreviewHost extends StatefulWidget {
  const PetListLoadingPreviewHost({super.key});

  @override
  State<PetListLoadingPreviewHost> createState() =>
      _PetListLoadingPreviewHostState();
}

class _PetListLoadingPreviewHostState extends State<PetListLoadingPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetListLoadingPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
