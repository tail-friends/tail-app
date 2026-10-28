import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

/// Opens a static design preview, never a photo-analysis or generation task.
/// No production screen calls this entry point.
Future<void> showPetCharacterGenerationPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      content: const Text(
        '실제 사진 분석과 캐릭터 생성은 실행하지 않습니다. 진행률과 단계는 Figma 고정 예시입니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('미리보기 열기'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const PetCharacterGenerationScreen()),
  );
}

/// Figma 03-2. All progress and stage labels are fixed Debug-only examples.
class PetCharacterGenerationScreen extends StatelessWidget {
  const PetCharacterGenerationScreen({super.key});

  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  static final _body = AppTypography.bodyRegular.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _caption = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: _muted,
  );

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // A directly launched preview must also have a working exit.
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          key: const ValueKey('pet_character_generation_screen'),
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // SHA-256 matches the exported background-only Figma node.
              Image.asset(
                'assets/images/home_first_visit_background.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: math.max(4, 58 - media.padding.top)),
                    SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _closeButton(context),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('pet_generation_scroll'),
                        padding: const EdgeInsets.only(top: 68, bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: _progress(context)),
                            const SizedBox(height: 34),
                            _copy(),
                            const SizedBox(height: 36),
                            _stages(),
                          ],
                        ),
                      ),
                    ),
                    AppButton(
                      key: const ValueKey('pet_generation_cancel'),
                      label: '취소',
                      variant: AppButtonVariant.ghost,
                      foregroundColor: _ink,
                      textStyle: AppTypography.titleMedium.copyWith(
                        fontFamily: 'Jua',
                      ),
                      onPressed: () => _close(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _closeButton(BuildContext context) => Semantics(
    label: '캐릭터 생성 미리보기 닫기',
    button: true,
    excludeSemantics: true,
    onTap: () => _close(context),
    child: InkWell(
      key: const ValueKey('pet_generation_close'),
      borderRadius: BorderRadius.circular(22),
      onTap: () => _close(context),
      child: SizedBox.square(
        dimension: 44,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 36,
            child: AppGlassSurface(
              key: const ValueKey('pet_generation_close_surface'),
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: SizedBox.square(
                  dimension: 16,
                  child: FittedBox(
                    child: SvgPicture.asset(
                      'assets/icons/species_picker_close.svg',
                      width: 24,
                      height: 24,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _progress(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final badgeHeight = scaler.scale(13) * 19 / 13 + 10;
    // Preserve Figma's clipped badge at 100%; allow enlarged text to grow.
    final height = scaler.scale(13) <= 13
        ? 220.0
        : math.max(220.0, 196 + badgeHeight);
    return Semantics(
      label: '캐릭터 생성 디자인 미리보기',
      value: '68%, 고정 시안. 실제 분석은 실행되지 않습니다.',
      excludeSemantics: true,
      child: SizedBox(
        key: const ValueKey('pet_generation_progress'),
        width: 220,
        height: height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            SvgPicture.asset(
              'assets/icons/character_generation_ring.svg',
              width: 220,
              height: 220,
              excludeFromSemantics: true,
            ),
            Positioned(
              top: 26,
              left: 26,
              child: Container(
                key: const ValueKey('pet_generation_empty_character'),
                width: 168,
                height: 168,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.25, 0.75],
                    colors: [Color(0xFF2F6B57), Color(0xFFBDAD99)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 196,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(2.5, 0),
                  child: AppGlassSurface(
                    key: const ValueKey('pet_generation_percentage'),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 26),
                      child: Text(
                        '68%',
                        textAlign: TextAlign.center,
                        style: _body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _copy() => Padding(
    // The source copy is intentionally 17px left of the ring's center.
    padding: const EdgeInsets.only(right: 34),
    child: Center(
      child: ConstrainedBox(
        key: const ValueKey('pet_generation_copy'),
        constraints: const BoxConstraints(minWidth: 164),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                '사진을 읽는 중…',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontFamily: 'Jua',
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '먼저 사진 색으로 미리보기를 만들었어요',
              textAlign: TextAlign.center,
              style: _caption.copyWith(color: const Color(0xFF6B675E)),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _stages() => AppGlassSurface(
    key: const ValueKey('pet_generation_stages'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 7),
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    child: Column(
      children: [
        _stage('기기에서 주요 색 추출', '완료', complete: true),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE6E1D6)),
        _stage('AI 분석 (체형·무늬·색 4개)', '진행 중', active: true),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE6E1D6)),
        _stage('캐릭터 생성', '대기', waiting: true),
      ],
    ),
  );

  Widget _stage(
    String title,
    String status, {
    bool complete = false,
    bool active = false,
    bool waiting = false,
  }) => Semantics(
    label: '$title, $status. 디자인 예시, 실제 분석 미실행',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/character_generation_check_${complete ? 'on' : 'off'}.svg',
            width: 18,
            height: 18,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: _body.copyWith(color: waiting ? _muted : _ink),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: active ? 36 : (complete ? 19 : 18),
            ),
            child: Text(
              status,
              textAlign: TextAlign.right,
              style: active ? _body : _caption,
            ),
          ),
        ],
      ),
    ),
  );
}
