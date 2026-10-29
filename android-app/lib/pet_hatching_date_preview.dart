import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/pets/presentation/pet_registration_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_hatching_date_preview.dart
/// Profile/Release use the normal application login entry point.
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends — 해칭일 날짜 선택 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetRegistrationScreen.hatchingDatePreview(),
    ),
  );
}
