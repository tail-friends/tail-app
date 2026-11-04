import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/pets/presentation/pet_character_detection_failure_screen.dart';
import 'features/pets/presentation/pet_registration_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_character_detection_failure_preview.dart
/// Profile/Release retain the normal application entry point.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 캐릭터 인식 실패 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetCharacterDetectionFailurePreviewHost(),
    ),
  );
}

class PetCharacterDetectionFailurePreviewHost extends StatefulWidget {
  const PetCharacterDetectionFailurePreviewHost({super.key});

  @override
  State<PetCharacterDetectionFailurePreviewHost> createState() =>
      _PetCharacterDetectionFailurePreviewHostState();
}

class _PetCharacterDetectionFailurePreviewHostState
    extends State<PetCharacterDetectionFailurePreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetCharacterDetectionFailurePreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      kDebugMode ? const PetRegistrationScreen() : const LoginScreen();
}
