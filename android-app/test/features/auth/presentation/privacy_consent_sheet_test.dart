import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/auth/presentation/privacy_consent_sheet.dart';
import 'package:tail_friends/main.dart';

const _ids = ['personal', 'analysis', 'original', 'notifications'];
Finder _row(String id) => find.byKey(ValueKey('consent_$id'));
Finder get _continue => find.byKey(const ValueKey('consent_continue'));

bool _checked(WidgetTester tester, String id) =>
    tester.widget<Semantics>(_row(id)).properties.checked!;

bool _enabled(WidgetTester tester) =>
    tester.widget<AppButton>(_continue).onPressed != null;

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: padding,
          viewPadding: padding,
        ),
        child: child!,
      ),
      home: const PrivacyConsentPreviewScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(_row(id));
  await tester.tap(_row(id));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('초기에는 전체/개별 동의가 모두 미선택이고 진행할 수 없다', (tester) async {
    await _open(tester);
    for (final id in ['all', ..._ids]) {
      expect(_checked(tester, id), isFalse);
    }
    expect(find.text('개인정보 동의'), findsOneWidget);
    expect(find.text('꼬리친구를 시작하려면 필수 항목에 동의해 주세요'), findsOneWidget);
    expect(_enabled(tester), isFalse);
    await tester.ensureVisible(_continue);
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(PrivacyConsentSheet), findsOneWidget);
  });

  testWidgets('전체 동의는 모든 항목을 선택/해제하고 개별 변경도 반영한다', (tester) async {
    await _open(tester);
    await _tap(tester, 'all');
    for (final id in ['all', ..._ids]) {
      expect(_checked(tester, id), isTrue);
    }
    expect(_enabled(tester), isTrue);
    await _tap(tester, 'original');
    expect(_checked(tester, 'all'), isFalse);
    expect(_enabled(tester), isTrue);
    await _tap(tester, 'original');
    expect(_checked(tester, 'all'), isTrue);
    await _tap(tester, 'all');
    for (final id in ['all', ..._ids]) {
      expect(_checked(tester, id), isFalse);
    }
    expect(_enabled(tester), isFalse);
    for (final id in _ids) {
      await _tap(tester, id);
    }
    expect(_checked(tester, 'all'), isTrue);
  });

  testWidgets('각 필수 항목을 해제하면 선택 동의 여부와 무관하게 진행이 차단된다', (tester) async {
    await _open(tester);
    await _tap(tester, 'all');
    for (final id in ['personal', 'analysis']) {
      await _tap(tester, id);
      expect(_enabled(tester), isFalse, reason: id);
      await _tap(tester, id);
      expect(_enabled(tester), isTrue, reason: id);
    }
  });

  testWidgets('필수만 선택해 진행하면 미리보기 안내만 표시하고 선택은 유지한다', (tester) async {
    await _open(tester);
    await _tap(tester, 'personal');
    expect(_enabled(tester), isFalse);
    await _tap(tester, 'analysis');
    expect(_enabled(tester), isTrue);
    expect(_checked(tester, 'all'), isFalse);
    expect(_checked(tester, 'original'), isFalse);
    expect(_checked(tester, 'notifications'), isFalse);
    await tester.ensureVisible(_continue);
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(find.text('UI 미리보기입니다. 동의는 저장되지 않으며 로그인되지 않습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyConsentSheet), findsOneWidget);
    expect(_checked(tester, 'personal'), isTrue);
    expect(_checked(tester, 'analysis'), isTrue);
  });

  testWidgets('스크림을 누르면 시트를 닫고 기존 로그인 동작을 유지한다', (tester) async {
    await _open(tester);
    await tester.tapAt(const Offset(16, 80));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyConsentSheet), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    final login = find.byKey(const ValueKey('login_apple_button'));
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(find.text('로그인 기능은 준비 중입니다.'), findsOneWidget);
    expect(find.byType(PrivacyConsentSheet), findsNothing);
  });

  testWidgets('뒤로가기와 드래그로 닫히며 다시 열면 저장된 동의 없이 시작한다', (tester) async {
    await _open(tester);
    await _tap(tester, 'all');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyConsentSheet), findsNothing);
    final context = tester.element(find.byType(LoginScreen));
    showPrivacyConsentPreview(context);
    await tester.pumpAndSettle();
    expect(_checked(tester, 'all'), isFalse);
    expect(_enabled(tester), isFalse);
    final sheet = find.byKey(const ValueKey('privacy_consent_sheet'));
    await tester.dragFrom(
      tester.getTopLeft(sheet) + const Offset(100, 12),
      const Offset(0, 650),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyConsentSheet), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('체크 상태와 필수 여부를 접근성으로 전달하고 44px 터치 영역을 제공한다', (tester) async {
    await _open(tester);
    for (final id in ['all', ..._ids]) {
      final size = tester.getSize(_row(id));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      final node = tester.getSemantics(_row(id));
      expect(node.flagsCollection.isChecked, CheckedState.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    }
    expect(tester.getSemantics(_row('personal')).label, contains('필수'));
    expect(tester.getSemantics(_row('original')).label, contains('선택'));
    await _tap(tester, 'personal');
    expect(
      tester.getSemantics(_row('personal')).flagsCollection.isChecked,
      CheckedState.isTrue,
    );
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale배에서 모든 항목과 버튼에 스크롤로 접근한다', (tester) async {
        await _open(
          tester,
          size: size,
          scale: scale,
          padding: const EdgeInsets.only(top: 24, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        for (final id in ['all', ..._ids]) {
          await _tap(tester, id);
          final rect = tester.getRect(_row(id));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(tester.takeException(), isNull, reason: id);
        }
        await tester.ensureVisible(_continue);
        await tester.pumpAndSettle();
        final buttonRect = tester.getRect(_continue);
        expect(buttonRect.bottom, lessThanOrEqualTo(size.height - 34));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('일반 시작점은 로그인이고 debug 경로에서만 시트 미리보기를 연다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PrivacyConsentSheet), findsNothing);
    Navigator.of(
      tester.element(find.byType(LoginScreen)),
    ).pushNamed('/consent-preview');
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyConsentSheet), findsOneWidget);
  });
}
