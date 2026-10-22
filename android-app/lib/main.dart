import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
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
      home: const ProjectReadyScreen(),
    );
  }
}

class ProjectReadyScreen extends StatelessWidget {
  const ProjectReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.mistScreenGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  const Text('Tail Friends', style: AppTypography.displayLarge),
                  const SizedBox(height: AppSpacing.x2),
                  const Text('Android 개발 환경이 준비되었습니다.'),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.x6),
                    SizedBox(
                      width: 280,
                      child: AppButton(
                        label: '디자인 시스템 미리보기',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DesignSystemPreviewScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
