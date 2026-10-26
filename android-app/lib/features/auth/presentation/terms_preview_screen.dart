import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import 'login_screen.dart';

/// Debug-only reproduction of Figma 01-2 (21:1174).
///
/// The date, providers, photo deletion and account-deletion terms below are
/// unapproved design copy, not a legal contract or implemented service policy.
/// Never connect this preview to actual agreement, authentication or storage.
class TermsPreviewScreen extends StatelessWidget {
  const TermsPreviewScreen({super.key});

  static const _background = Color(0xFFFAF7F0);
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);

  // Verbatim Figma preview text, including the provisional effective date.
  static const _articles = [
    (
      title: '제1조 목적',
      body:
          '이 약관은 꼬리친구(이하 "서비스")가 제공하는 파충류 사육 기록 및 캐릭터 서비스의 이용 조건과 절차, 회원과 서비스의 권리·의무를 정하는 것을 목적으로 합니다.',
    ),
    (
      title: '제2조 회원가입',
      body: '회원은 Apple, 카카오, Google 계정으로 가입할 수 있으며, 약관에 동의함으로써 이용계약이 성립됩니다.',
    ),
    (
      title: '제3조 사진 및 캐릭터',
      body:
          '회원이 업로드한 사진은 캐릭터 생성 목적으로만 사용되며, 생성 완료 후 원본은 회원의 요청에 따라 삭제할 수 있습니다.',
    ),
    (
      title: '제4조 회원 탈퇴',
      body: '회원은 마이 > 계정 관리에서 언제든지 탈퇴할 수 있으며, 탈퇴 시 기록과 캐릭터는 즉시 삭제됩니다.',
    ),
  ];

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Direct preview launches must not leave the developer on a blank route.
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTypography.titleMedium.copyWith(
      fontFamily: 'Jua',
      color: _ink,
    );
    final articleStyle = AppTypography.bodyRegular.copyWith(
      fontFamily: 'Jua',
      color: _ink,
    );

    return PopScope<void>(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: _background,
          systemNavigationBarDividerColor: _background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          key: const ValueKey('terms_preview_screen'),
          backgroundColor: _background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Original Figma bg layer 408:2319; only the decoration is raster.
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Image.asset(
                      'assets/images/terms_background.png',
                      key: const ValueKey('terms_background'),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x6,
                  ),
                  child: Column(
                    children: [
                      // Match y=58 in the reference while respecting taller
                      // native status bars. The system draws the status icons.
                      SizedBox(
                        height: math.max(
                          AppSpacing.x1,
                          58 - MediaQuery.paddingOf(context).top,
                        ),
                      ),
                      ConstrainedBox(
                        key: const ValueKey('terms_header'),
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: '뒤로가기',
                              excludeSemantics: true,
                              onTap: () => _goBack(context),
                              child: InkWell(
                                key: const ValueKey('terms_back_button'),
                                onTap: () => _goBack(context),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                                child: SizedBox.square(
                                  dimension: 44,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: AppGlassSurface(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.full,
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
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  '서비스 이용약관',
                                  textAlign: TextAlign.center,
                                  style: titleStyle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('terms_scroll'),
                          padding: const EdgeInsets.only(
                            top: AppSpacing.x5,
                            bottom: AppSpacing.x6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.x5,
                            children: [
                              Text(
                                '시행일 2026년 11월 1일',
                                key: const ValueKey('terms_effective_date'),
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _muted,
                                ),
                              ),
                              AppGlassSurface(
                                key: const ValueKey('terms_card'),
                                borderRadius: BorderRadius.circular(22),
                                gradient: AppColors.glassSoftGradient,
                                // 20px content padding plus the 1px Figma border.
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
                                  spacing: AppSpacing.x4,
                                  children: [
                                    for (var i = 0; i < _articles.length; i++)
                                      Column(
                                        key: ValueKey('terms_article_${i + 1}'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        spacing: 6,
                                        children: [
                                          Semantics(
                                            header: true,
                                            child: Text(
                                              _articles[i].title,
                                              style: articleStyle,
                                            ),
                                          ),
                                          Text(
                                            _articles[i].body,
                                            key: ValueKey(
                                              'terms_article_${i + 1}_body',
                                            ),
                                            style: articleStyle.copyWith(
                                              color: _secondary,
                                            ),
                                          ),
                                        ],
                                      ),
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
