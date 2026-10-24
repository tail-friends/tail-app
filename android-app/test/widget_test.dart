import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/main.dart';

void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('앱 실행 시 Figma 로그인 화면의 필수 요소를 표시한다', (tester) async {
    _setViewSize(tester, const Size(390, 844));

    await tester.pumpWidget(const TailFriendsApp());
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Tail'), findsOneWidget);
    expect(find.text('기록할수록 닮아가는 나의 파충류'), findsOneWidget);
    expect(find.text('Apple로 계속하기'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(find.text('계속하면 이용약관 및 개인정보처리방침에 동의하게 됩니다'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const ValueKey('login_background'))),
      const Size(390, 844),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('login_character_slot'))),
      const Size(63, 94.5),
    );
    final appleButton = find.byKey(const ValueKey('login_apple_button'));
    expect(tester.getSize(appleButton), const Size(342, 50));
    expect(tester.getTopLeft(appleButton).dy, closeTo(644, 0.1));
  });

  testWidgets('소셜 버튼은 준비 중 안내만 표시하고 로그인 상태를 바꾸지 않는다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(const TailFriendsApp());

    for (final key in const [
      ValueKey('login_apple_button'),
      ValueKey('login_kakao_button'),
      ValueKey('login_google_button'),
    ]) {
      final button = find.byKey(key);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(find.text('로그인 기능은 준비 중입니다.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    }
  });

  testWidgets('작은 Android 화면에서도 모든 버튼과 약관 안내에 접근할 수 있다', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(360, 800), Size(320, 640)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const TailFriendsApp());
      await tester.pump();

      expect(tester.takeException(), isNull, reason: '$size 초기 렌더링');
      for (final key in const [
        ValueKey('login_apple_button'),
        ValueKey('login_kakao_button'),
        ValueKey('login_google_button'),
      ]) {
        final button = find.byKey(key);
        await tester.ensureVisible(button);
        await tester.pump();
        final buttonSize = tester.getSize(button);
        expect(
          buttonSize.width,
          greaterThanOrEqualTo(44),
          reason: '$size $key',
        );
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(44),
          reason: '$size $key',
        );
        expect(tester.takeException(), isNull, reason: '$size $key');
      }

      final terms = find.byKey(const ValueKey('login_terms'));
      await tester.ensureVisible(terms);
      await tester.pump();
      expect(terms, findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size 약관 안내');
    }
  });

  testWidgets('텍스트를 150%와 200%로 확대해도 로그인 콘텐츠가 overflow되지 않는다', (tester) async {
    _setViewSize(tester, const Size(320, 640));

    for (final textScale in const [1.5, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.mist,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      for (final key in const [
        ValueKey('login_apple_button'),
        ValueKey('login_kakao_button'),
        ValueKey('login_google_button'),
        ValueKey('login_terms'),
      ]) {
        final target = find.byKey(key);
        await tester.ensureVisible(target);
        await tester.pump();
        expect(target, findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'textScale=$textScale $key',
        );
      }
    }
  });
}
