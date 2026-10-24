import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/design_system_preview/design_system_preview_screen.dart';

void main() {
  registerDesignSystemLicenses();
  runApp(const TailFriendsApp());
}

class TailFriendsApp extends StatelessWidget {
  const TailFriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tail Friends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const LoginScreen(),
      routes: {
        if (kDebugMode)
          '/design-system-preview': (_) => const DesignSystemPreviewScreen(),
      },
    );
  }
}
