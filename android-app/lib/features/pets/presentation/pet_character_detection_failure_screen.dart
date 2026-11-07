import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'pet_character_ai_result_screen.dart';

/// Opens an explicitly selected design example, never an AI/file error result.
Future<void> showPetCharacterDetectionFailurePreview(
  BuildContext context,
) async {
  if (!kDebugMode) return;
  final fileErrorExample = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(
        '실제 사진을 읽거나 검사하지 않으며 AI 분석, 업로드, 저장 및 홈 데이터 변경은 '
        '실행하지 않습니다. 인식 실패와 파일 오류는 Figma 디자인 예시입니다. '
        '직접 고치기도 실제 분석 결과가 아닌 기존 03-3 예시 화면만 엽니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('기본 미리보기'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('파일 오류 예시'),
        ),
      ],
    ),
  );
  if (fileErrorExample == null || !context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PetCharacterDetectionFailureScreen(
        showFileErrorExample: fileErrorExample,
      ),
    ),
  );
}

/// Figma 03-7. All failure wording is a Debug-only design scenario.
class PetCharacterDetectionFailureScreen extends StatefulWidget {
  const PetCharacterDetectionFailureScreen({
    this.showFileErrorExample = false,
    super.key,
  });

  /// Explicit preview variant; unrelated to photo selection or validation.
  final bool showFileErrorExample;

  @override
  State<PetCharacterDetectionFailureScreen> createState() =>
      _PetCharacterDetectionFailureScreenState();
}

class _PetCharacterDetectionFailureScreenState
    extends State<PetCharacterDetectionFailureScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF6B675E);
  static final _title = AppTypography.titleMedium.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _openingEditor = false;

  void _close() {
    _messengerKey.currentState?.removeCurrentSnackBar();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _editExample() async {
    if (!kDebugMode || _openingEditor) return;
    _openingEditor = true;
    _messengerKey.currentState?.removeCurrentSnackBar();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          // Scope existing preview notices to this route without modifying 03-3.
          builder: (_) =>
              const ScaffoldMessenger(child: PetCharacterAiResultScreen()),
        ),
      );
    } finally {
      _openingEditor = false;
    }
  }

  void _choosePhoto() {
    _messengerKey.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('사진 선택 기능은 아직 연결되지 않았습니다. 실제 파일은 읽거나 검사하지 않습니다.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ScaffoldMessenger(
          key: _messengerKey,
          child: Scaffold(
            key: const ValueKey('pet_detection_failure_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Unmodified Figma 408:2370 background-only PNG export.
                Image.asset(
                  'assets/images/character_detection_failure_background.png',
                  key: const ValueKey('pet_detection_failure_background'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(24, 0, 24, 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: math.max(4, 58 - media.padding.top)),
                      _header(),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('pet_detection_failure_scroll'),
                          padding: const EdgeInsets.only(top: 20, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _warning(),
                              const SizedBox(height: 20),
                              _preview(),
                              const SizedBox(height: 20),
                              AppButton(
                                key: const ValueKey(
                                  'pet_detection_failure_edit',
                                ),
                                label: '직접 고치기',
                                backgroundColor: const Color(0xFF2F6B57),
                                foregroundColor: Colors.white,
                                textStyle: _title,
                                onPressed: _editExample,
                              ),
                              const SizedBox(height: 8),
                              AppButton(
                                key: const ValueKey(
                                  'pet_detection_failure_photo',
                                ),
                                label: '다른 사진 고르기',
                                variant: AppButtonVariant.ghost,
                                foregroundColor: _ink,
                                textStyle: _title,
                                onPressed: _choosePhoto,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.showFileErrorExample) _fileErrorExample(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => SizedBox(
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Semantics(
            header: true,
            child: Text('캐릭터 만들기', textAlign: TextAlign.center, style: _title),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            label: '캐릭터 인식 실패 미리보기 닫기',
            button: true,
            excludeSemantics: true,
            onTap: _close,
            child: InkWell(
              key: const ValueKey('pet_detection_failure_close'),
              onTap: _close,
              borderRadius: BorderRadius.circular(22),
              child: SizedBox.square(
                dimension: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox.square(
                    dimension: 36,
                    child: AppGlassSurface(
                      key: const ValueKey(
                        'pet_detection_failure_close_surface',
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
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
          ),
        ),
      ],
    ),
  );

  Widget _warning() => AppGlassSurface(
    key: const ValueKey('pet_detection_failure_warning'),
    borderRadius: BorderRadius.circular(22),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xE0FFFFFF), Color(0xBFF3E2C2)],
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x0F3D2E1F), offset: Offset(0, 8), blurRadius: 24),
    ],
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사진에서 파충류를 찾지 못했어요',
          semanticsLabel:
              '인식 실패 디자인 예시: 사진에서 파충류를 찾지 못했어요. 실제 AI 분석은 실행되지 않았습니다.',
          style: AppTypography.bodyRegular.copyWith(
            fontFamily: 'Jua',
            color: const Color(0xFF96570C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '사진 색으로 만든 캐릭터예요. 아래에서 직접 고쳐 주세요',
          semanticsLabel:
              'Figma 예시 문구: 사진 색으로 만든 캐릭터예요. 아래에서 직접 고쳐 주세요. 실제 캐릭터는 생성되지 않았습니다.',
          style: AppTypography.captionRegular.copyWith(
            fontFamily: 'Jua',
            color: _muted,
          ),
        ),
      ],
    ),
  );

  Widget _preview() => SizedBox(
    height: 210,
    child: AppGlassSurface(
      key: const ValueKey('pet_detection_failure_preview_card'),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      gradient: AppColors.glassSoftGradient,
      boxShadow: const [
        BoxShadow(
          color: Color(0x143D3329),
          offset: Offset(0, 12),
          blurRadius: 32,
        ),
      ],
      child: Center(
        child: Semantics(
          label: '캐릭터 이미지가 없는 Figma 미리보기 자리',
          child: const SizedBox(
            key: ValueKey('pet_detection_failure_empty_character'),
            width: 60,
            height: 90,
          ),
        ),
      ),
    ),
  );

  Widget _fileErrorExample() => Padding(
    // Figma's toast is offset 9.5px right of center at the reference width.
    padding: const EdgeInsets.only(left: 19),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 305,
        child: Semantics(
          liveRegion: true,
          label:
              '파일 오류 디자인 예시, 실제 파일은 검사하지 않았습니다. 열 수 없는 파일이에요 · JPG나 PNG 사진을 골라 주세요',
          excludeSemantics: true,
          child: DecoratedBox(
            key: const ValueKey('pet_detection_failure_file_toast'),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Padding(
              // Bundled Jua measures this line ~6px wider than the Figma
              // render. Keep its 13px type and 305px shell without scaling.
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Text(
                '열 수 없는 파일이에요 · JPG나 PNG 사진을 골라 주세요',
                style: AppTypography.bodyRegular.copyWith(
                  fontFamily: 'Jua',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
