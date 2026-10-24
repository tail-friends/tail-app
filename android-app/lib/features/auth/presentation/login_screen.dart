import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const _backgroundColor = Color(0xFFFAF7F0);
  static const _primaryTextColor = Color(0xFF2B2A26);
  static const _secondaryTextColor = Color(0xFF6B675E);
  static const _tertiaryTextColor = Color(0xFF736E65);
  static const _appleBackgroundColor = Color(0xFF2F6B57);
  static const _fontFamily = 'Jua';

  static const _brandStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.6,
    color: _primaryTextColor,
  );
  static const _descriptionStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    color: _secondaryTextColor,
  );
  static const _buttonStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const _termsStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
    color: _tertiaryTextColor,
  );

  void _showComingSoon(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인 기능은 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final systemPadding = MediaQuery.paddingOf(context);
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarDividerColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        key: const ValueKey('login_screen'),
        backgroundColor: _backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Image.asset(
                    'assets/images/login_background.png',
                    key: const ValueKey('login_background'),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomShift = math.max(
                    0.0,
                    systemPadding.bottom - AppSpacing.x3,
                  );
                  final characterTopGap = math.max(
                    AppSpacing.x6,
                    236.75 - systemPadding.top - bottomShift,
                  );

                  return SingleChildScrollView(
                    key: const ValueKey('login_scroll_view'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x6,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: characterTopGap),
                          const SizedBox(
                            key: ValueKey('login_character_slot'),
                            width: 63,
                            height: 94.5,
                          ),
                          const SizedBox(height: 72.75),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 73),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tail',
                                  textAlign: TextAlign.center,
                                  style: _brandStyle,
                                ),
                                SizedBox(height: 15),
                                Text(
                                  '기록할수록 닮아가는 나의 파충류',
                                  textAlign: TextAlign.center,
                                  style: _descriptionStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 167),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 342),
                            child: Column(
                              key: const ValueKey('login_social_area'),
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: AppSocialButton(
                                    key: const ValueKey('login_apple_button'),
                                    provider: AppSocialProvider.apple,
                                    backgroundColor: _appleBackgroundColor,
                                    textStyle: _buttonStyle,
                                    onPressed: () => _showComingSoon(context),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x2),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppSocialButton(
                                    key: const ValueKey('login_kakao_button'),
                                    provider: AppSocialProvider.kakao,
                                    textStyle: _buttonStyle,
                                    onPressed: () => _showComingSoon(context),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x2),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppSocialButton(
                                    key: const ValueKey('login_google_button'),
                                    provider: AppSocialProvider.google,
                                    textStyle: _buttonStyle,
                                    onPressed: () => _showComingSoon(context),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x2),
                                const Text(
                                  '계속하면 이용약관 및 개인정보처리방침에 동의하게 됩니다',
                                  key: ValueKey('login_terms'),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: _termsStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x3),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
