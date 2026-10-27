import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/pets/presentation/pet_registration_screen.dart';
import 'main.dart' as app;

/// Run with: flutter run --target lib/pet_photo_add_preview.dart
/// Keep PR #58's main.dart independent; Release/Profile start at normal login.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends — 사진 추가 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetRegistrationScreen.photoAddPreview(),
    ),
  );
}
