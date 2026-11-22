import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const privacyPolicyPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 시행일과 개인정보 수집·이용·사진 처리·파기 문구는 미확정 시안이며, 실제 개인정보 처리방침이나 구현된 서비스 동작이 아닙니다.';

final _previewInProgress = Expando<bool>();

Future<void> showPrivacyPolicyPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewInProgress[navigator] == true) return;
  _previewInProgress[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(privacyPolicyPreviewNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('미리보기 열기'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted || !navigator.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen.preview()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// Verbatim, unapproved Figma 09-9 copy. This preview performs no data handling.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen.preview({super.key});

  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  static const _articles = [
    (
      title: '1. 수집하는 정보',
      body: '소셜 로그인 식별자, 닉네임, 반려 파충류 정보(이름·종·성별·날짜), 사육 기록, 업로드한 사진.',
    ),
    (title: '2. 이용 목적', body: '사육 기록 저장, 돌봄 알림 발송, 사진 기반 캐릭터 생성 및 서비스 개선.'),
    (
      title: '3. 사진 데이터 처리',
      body: '사진은 캐릭터 생성에만 사용되며 외부 AI 처리 시 식별 정보를 제거합니다. 원본 삭제를 요청할 수 있습니다.',
    ),
    (
      title: '4. 보관 및 파기',
      body: '탈퇴 즉시 모든 정보를 파기하며, 법령상 보관 의무가 있는 정보는 해당 기간 동안 분리 보관합니다.',
    ),
  ];

  void _back(BuildContext context) {
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
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
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
          key: const ValueKey('privacy_policy_screen'),
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Original Figma bg 408:2353, exported separately from the UI.
              Image.asset(
                'assets/images/privacy_policy_background.png',
                key: const ValueKey('privacy_policy_background'),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    math.max(4, 58 - MediaQuery.paddingOf(context).top),
                    24,
                    0,
                  ),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        key: const ValueKey('privacy_policy_header'),
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Semantics(
                              label: '뒤로가기',
                              button: true,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey('privacy_policy_back'),
                                  onTap: () => _back(context),
                                  borderRadius: BorderRadius.circular(999),
                                  child: SizedBox.square(
                                    dimension: 44,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AppGlassSurface(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: SizedBox.square(
                                          dimension: 36,
                                          child: Center(
                                            child: SizedBox.square(
                                              dimension: 16,
                                              child: SvgPicture.asset(
                                                'assets/icons/terms_chevron_left.svg',
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
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  '개인정보 처리방침',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontFamily: 'Jua',
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('privacy_policy_scroll'),
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '시행일 2026년 11월 1일',
                                key: const ValueKey('privacy_policy_date'),
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _tertiary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppGlassSurface(
                                key: const ValueKey('privacy_policy_card'),
                                borderRadius: BorderRadius.circular(22),
                                gradient: AppColors.glassSoftGradient,
                                padding: const EdgeInsets.all(21),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x143D3329),
                                    offset: Offset(0, 12),
                                    blurRadius: 32,
                                  ),
                                ],
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _articles.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(height: 16),
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          _articles[i].title,
                                          style: AppTypography.bodyRegular
                                              .copyWith(
                                                fontFamily: 'Jua',
                                                color: _ink,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _articles[i].body,
                                        style: AppTypography.bodyRegular
                                            .copyWith(
                                              fontFamily: 'Jua',
                                              color: _secondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
