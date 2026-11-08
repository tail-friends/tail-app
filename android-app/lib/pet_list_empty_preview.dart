import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/pets/presentation/pet_list_empty_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_list_empty_preview.dart
/// Profile/Release always use the ordinary application login entry point.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 개체 목록 빈 상태 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetListEmptyPreviewHost(),
    ),
  );
}

class PetListEmptyPreviewHost extends StatefulWidget {
  const PetListEmptyPreviewHost({super.key});

  @override
  State<PetListEmptyPreviewHost> createState() =>
      _PetListEmptyPreviewHostState();
}

class _PetListEmptyPreviewHostState extends State<PetListEmptyPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetListEmptyPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
