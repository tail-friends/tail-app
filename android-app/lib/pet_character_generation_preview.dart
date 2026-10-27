import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/pets/presentation/pet_character_generation_screen.dart';
import 'features/pets/presentation/pet_registration_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_character_generation_preview.dart
/// Release/Profile always use the normal application entry point.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 캐릭터 생성 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetCharacterGenerationPreviewHost(),
    ),
  );
}

class PetCharacterGenerationPreviewHost extends StatefulWidget {
  const PetCharacterGenerationPreviewHost({super.key});

  @override
  State<PetCharacterGenerationPreviewHost> createState() =>
      _PetCharacterGenerationPreviewHostState();
}

class _PetCharacterGenerationPreviewHostState
    extends State<PetCharacterGenerationPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetCharacterGenerationPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      kDebugMode ? const PetRegistrationScreen() : const LoginScreen();
}
