import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/pets/presentation/pet_list_error_screen.dart';
import 'main.dart' as app;

/// flutter run --target lib/pet_list_error_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 개체 목록 오류 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const PetListErrorPreviewHost(),
    ),
  );
}

class PetListErrorPreviewHost extends StatefulWidget {
  const PetListErrorPreviewHost({super.key});

  @override
  State<PetListErrorPreviewHost> createState() =>
      _PetListErrorPreviewHostState();
}

class _PetListErrorPreviewHostState extends State<PetListErrorPreviewHost> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetListErrorPreview(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
