import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/pets/presentation/pet_registration_complete_screen.dart';
import 'features/pets/presentation/pet_registration_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_registration_complete_preview.dart
/// Profile/Release keep the ordinary login entry point.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 등록 완료 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetRegistrationCompletePreviewHost(),
    ),
  );
}

class PetRegistrationCompletePreviewHost extends StatefulWidget {
  const PetRegistrationCompletePreviewHost({super.key});

  @override
  State<PetRegistrationCompletePreviewHost> createState() =>
      _PetRegistrationCompletePreviewHostState();
}

class _PetRegistrationCompletePreviewHostState
    extends State<PetRegistrationCompletePreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetRegistrationCompletePreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      kDebugMode ? const PetRegistrationScreen() : const LoginScreen();
}
