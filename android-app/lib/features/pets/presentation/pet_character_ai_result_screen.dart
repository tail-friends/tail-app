import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

/// Independent design preview; never connected to analysis or saved pet data.
Future<void> showPetCharacterAiResultPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(
        '실제 AI 분석, 캐릭터 생성 및 저장은 실행하지 않습니다. '
        'Figma 예시 데이터만 표시하며 선택 상태는 미리보기 안에서만 변경됩니다. '
        '화면의 안내 문구와 달리 실제 사육장 데이터는 변경되지 않습니다.',
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
    MaterialPageRoute(builder: (_) => const PetCharacterAiResultScreen()),
  );
}

/// Figma 03-3. Selections only highlight controls; no character is generated.
class PetCharacterAiResultScreen extends StatefulWidget {
  const PetCharacterAiResultScreen({super.key});

  @override
  State<PetCharacterAiResultScreen> createState() =>
      _PetCharacterAiResultScreenState();
}

class _PetCharacterAiResultScreenState
    extends State<PetCharacterAiResultScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  static const _selectionBorder = Color(0xE6E6E1D6);
  static const _cardShadow = [
    BoxShadow(color: Color(0x143D3329), offset: Offset(0, 12), blurRadius: 32),
  ];
  static const _selectionShadow = [
    BoxShadow(color: Color(0x0F3D2E1F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x1A3D2E1F), offset: Offset(0, 2), blurRadius: 8),
  ];
  static final _caption = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: const Color(0xFF6B675E),
  );
  static final _title = AppTypography.titleMedium.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );

  // UI-only indices, intentionally not species codes or persistence models.
  int _body = 0;
  int _pattern = 0;
  int _color = 0;

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        child: Scaffold(
          key: const ValueKey('pet_ai_result_screen'),
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Original background-only Figma export, not a screen image.
              Image.asset(
                'assets/images/character_ai_result_background.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 31),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: math.max(4, 58 - media.padding.top)),
                    _header(),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('pet_ai_result_scroll'),
                        padding: const EdgeInsets.only(top: 20, bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _preview(),
                            const SizedBox(height: 20),
                            Text(
                              '바꾸는 즉시 사육장 캐릭터에 반영돼요',
                              semanticsLabel:
                                  'Figma 예시 문구: 바꾸는 즉시 사육장 캐릭터에 반영돼요. '
                                  '실제 사육장 데이터는 변경되지 않습니다.',
                              style: _caption.copyWith(color: _muted),
                            ),
                            const SizedBox(height: 20),
                            _customize(),
                          ],
                        ),
                      ),
                    ),
                    AppButton(
                      key: const ValueKey('pet_ai_result_save'),
                      label: '저장',
                      backgroundColor: const Color(0xFF2F6B57),
                      textStyle: _title,
                      onPressed: () =>
                          _notice('디자인 미리보기입니다. 실제 캐릭터는 저장되지 않았습니다.'),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      key: const ValueKey('pet_ai_result_photo'),
                      label: '다른 사진 고르기',
                      variant: AppButtonVariant.ghost,
                      foregroundColor: _ink,
                      textStyle: _title,
                      onPressed: () => _notice('사진 선택 기능은 아직 연결되지 않았습니다.'),
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
            label: '캐릭터 결과 미리보기 닫기',
            button: true,
            excludeSemantics: true,
            onTap: _close,
            child: InkWell(
              key: const ValueKey('pet_ai_result_close'),
              borderRadius: BorderRadius.circular(22),
              onTap: _close,
              child: SizedBox.square(
                dimension: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox.square(
                    dimension: 36,
                    child: AppGlassSurface(
                      key: const ValueKey('pet_ai_result_close_surface'),
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
          ),
        ),
      ],
    ),
  );

  Widget _preview() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 210),
    child: AppGlassSurface(
      key: const ValueKey('pet_ai_result_preview_card'),
      borderRadius: BorderRadius.circular(24),
      gradient: AppColors.glassSoftGradient,
      boxShadow: _cardShadow,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppGlassSurface(
            key: const ValueKey('pet_ai_result_badge'),
            borderRadius: BorderRadius.circular(AppRadius.full),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            child: Text(
              'AI가 본 모습: 탠저린 레오파드 게코',
              semanticsLabel: 'Figma 예시, 실제 AI 분석 결과 아님: 탠저린 레오파드 게코',
              style: AppTypography.bodyRegular.copyWith(
                fontFamily: 'Jua',
                color: _ink,
              ),
            ),
          ),
          // Figma's character/lizard node is empty. Do not invent an asset.
          const SizedBox(height: 14),
          const Center(
            child: SizedBox(
              key: ValueKey('pet_ai_result_empty_character'),
              width: 60,
              height: 90,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _customize() => AppGlassSurface(
    key: const ValueKey('pet_ai_result_customize'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    boxShadow: _cardShadow,
    padding: const EdgeInsets.all(19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('체형', style: _caption),
        const SizedBox(height: 12),
        _segments(
          'body',
          '체형',
          ['게코', '도마뱀', '뱀', '거북'],
          _body,
          (value) => setState(() => _body = value),
        ),
        // Two pixels reclaimed between groups for 44px hit targets while
        // preserving the reference panel's overall height at default scale.
        const SizedBox(height: 10),
        Text('무늬', style: _caption),
        const SizedBox(height: 12),
        _segments(
          'pattern',
          '무늬',
          ['점박이', '가로 밴드', '세로 줄', '없음'],
          _pattern,
          (value) => setState(() => _pattern = value),
        ),
        const SizedBox(height: 10),
        Text('색', style: _caption),
        const SizedBox(height: 12),
        _colors(),
      ],
    ),
  );

  Widget _segments(
    String key,
    String group,
    List<String> labels,
    int selected,
    ValueChanged<int> onSelected,
  ) => AppGlassSurface(
    borderRadius: BorderRadius.circular(AppRadius.full),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: Semantics(
              label: '$group ${labels[index]}',
              button: true,
              selected: active,
              inMutuallyExclusiveGroup: true,
              excludeSemantics: true,
              onTap: () => onSelected(index),
              child: InkWell(
                key: ValueKey('pet_ai_result_${key}_$index'),
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: () => onSelected(index),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: active
                            ? Border.all(color: _selectionBorder)
                            : null,
                        boxShadow: active ? _selectionShadow : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 9,
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            style: AppTypography.labelMedium.copyWith(
                              fontFamily: 'Jua',
                              color: active ? _ink : _muted,
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
        }),
      ),
    ),
  );

  Widget _colors() {
    const labels = ['몸', '무늬', '배', '눈'];
    const assets = ['body', 'dark', 'belly', 'dark'];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                label: '색 ${labels[index]}',
                value: 'Figma 색상 견본, 실제 색상 편집 없음',
                button: true,
                selected: _color == index,
                inMutuallyExclusiveGroup: true,
                excludeSemantics: true,
                onTap: () => setState(() => _color = index),
                child: InkWell(
                  key: ValueKey('pet_ai_result_color_$index'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _color = index),
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _color == index
                        ? const LinearGradient(
                            colors: [Colors.white, Colors.white],
                          )
                        : AppColors.glassStrongGradient,
                    borderColor: _color == index
                        ? _selectionBorder
                        : Colors.white,
                    boxShadow: _color == index ? _selectionShadow : const [],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1,
                      vertical: 11,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/character_result_${assets[index]}_swatch.svg',
                          width: 26,
                          height: 26,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style:
                              (_color == index
                                      ? AppTypography.bodyRegular
                                      : AppTypography.captionRegular)
                                  .copyWith(
                                    fontFamily: 'Jua',
                                    color: _color == index ? _ink : _muted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
