import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'pet_hatching_date_sheet.dart';

/// Read-only display values, independent of registration or API persistence.
@immutable
class PetRegistrationCompleteData {
  const PetRegistrationCompleteData({
    required this.name,
    required this.speciesLabel,
    required this.genderLabel,
    required this.hatchingDate,
    required this.feedingCycleDays,
  });

  final String name;
  final String speciesLabel;
  final String genderLabel;
  final HatchingDateSelection? hatchingDate;
  final int? feedingCycleDays;
}

/// An explicit Debug preview; no caller in the registration save flow.
Future<void> showPetRegistrationCompletePreview(BuildContext context) async {
  if (!kDebugMode) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(
        '이 화면은 Figma 디자인 미리보기입니다. 실제 개체 등록, 서버 저장, '
        '캐릭터 생성 및 홈 데이터 변경은 실행되지 않습니다.',
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
    MaterialPageRoute(
      builder: (_) => const PetRegistrationCompleteScreen(
        data: PetRegistrationCompleteData(
          name: '욱이',
          speciesLabel: '레오파드 게코',
          genderLabel: '수컷',
          hatchingDate: HatchingDateSelection(year: 2024, month: 7, day: 12),
          feedingCycleDays: 4,
        ),
      ),
    ),
  );
}

/// Figma 03-6. Success wording describes a design sample only.
class PetRegistrationCompleteScreen extends StatelessWidget {
  const PetRegistrationCompleteScreen({required this.data, super.key});

  final PetRegistrationCompleteData data;

  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF6B675E);
  static const _shadow = [
    BoxShadow(color: Color(0x143D3329), offset: Offset(0, 12), blurRadius: 32),
  ];
  static final _title = AppTypography.titleLarge.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _body = AppTypography.bodyRegular.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _button = AppTypography.titleMedium.copyWith(fontFamily: 'Jua');

  String get _completionTitle {
    final lastRune = data.name.runes.lastOrNull;
    final hasFinalConsonant =
        lastRune != null &&
        lastRune >= 0xAC00 &&
        lastRune <= 0xD7A3 &&
        (lastRune - 0xAC00) % 28 != 0;
    final particle = hasFinalConsonant ? '이' : '가';
    return '${data.name}$particle 꼬리친구가 됐어요';
  }

  void _createCharacter(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            math.max(30, MediaQuery.viewPaddingOf(context).bottom) + 120,
          ),
          content: const Text('디자인 미리보기입니다. 실제 캐릭터 생성 기능은 연결되지 않았습니다.'),
        ),
      );
  }

  void _exitPreview(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
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
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        if (!didPop) _exitPreview(context);
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
          key: const ValueKey('pet_registration_complete_screen'),
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Figma 408:2326 exported without modifying the background.
              Image.asset(
                'assets/images/pet_registration_complete_background.png',
                key: const ValueKey('pet_registration_complete_background'),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('pet_registration_complete_scroll'),
                        padding: EdgeInsets.only(
                          top: math.max(12, 150 - media.padding.top),
                          bottom: 24,
                        ),
                        child: _content(),
                      ),
                    ),
                    AppButton(
                      key: const ValueKey(
                        'pet_registration_complete_create_character',
                      ),
                      label: '캐릭터 만들기',
                      backgroundColor: const Color(0xFF2F6B57),
                      foregroundColor: Colors.white,
                      textStyle: _button,
                      onPressed: () => _createCharacter(context),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      key: const ValueKey('pet_registration_complete_home'),
                      label: '홈으로',
                      variant: AppButtonVariant.ghost,
                      foregroundColor: _ink,
                      textStyle: _button,
                      onPressed: () => _exitPreview(context),
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

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Semantics(
          label: '캐릭터 이미지가 없는 Figma 미리보기 자리',
          child: SizedBox.square(
            dimension: 120,
            child: AppGlassSurface(
              key: const ValueKey('pet_registration_complete_avatar'),
              borderRadius: BorderRadius.circular(AppRadius.full),
              gradient: AppColors.glassSoftGradient,
              boxShadow: _shadow,
              child: const Center(
                child: SizedBox(
                  key: ValueKey('pet_registration_complete_empty_character'),
                  width: 50.4,
                  height: 75.6,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Semantics(
        header: true,
        child: Text(
          _completionTitle,
          semanticsLabel: 'Figma 예시: $_completionTitle. 실제 개체 등록은 실행되지 않았습니다.',
          textAlign: TextAlign.center,
          style: _title,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '이제 사진으로 캐릭터를 만들어 볼까요?',
        textAlign: TextAlign.center,
        style: AppTypography.captionRegular.copyWith(
          fontFamily: 'Jua',
          color: _muted,
        ),
      ),
      const SizedBox(height: 18),
      AppGlassSurface(
        key: const ValueKey('pet_registration_complete_summary'),
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.glassSoftGradient,
        boxShadow: _shadow,
        // Includes the original one-pixel border inset.
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 5),
        child: Column(
          children: [
            _row('종', data.speciesLabel, first: true),
            _row('성별', data.genderLabel),
            _row('해칭일', data.hatchingDate?.label ?? '미입력'),
            _row(
              '급여 주기',
              data.feedingCycleDays == null
                  ? '미입력'
                  : '${data.feedingCycleDays}일',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _row(String label, String value, {bool first = false}) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: Color(0xFFE6E1D6))),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: first ? 11 : 12, bottom: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label, style: _body.copyWith(color: _muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(value, textAlign: TextAlign.right, style: _body),
            ),
          ],
        ),
      ),
    ),
  );
}
