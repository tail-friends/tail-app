import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/privacy_policy_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/privacy_policy_preview.dart';

Finder key(String name) => find.byKey(ValueKey('privacy_policy_$name'));
const articles = [
  '1. 수집하는 정보',
  '소셜 로그인 식별자, 닉네임, 반려 파충류 정보(이름·종·성별·날짜), 사육 기록, 업로드한 사진.',
  '2. 이용 목적',
  '사육 기록 저장, 돌봄 알림 발송, 사진 기반 캐릭터 생성 및 서비스 개선.',
  '3. 사진 데이터 처리',
  '사진은 캐릭터 생성에만 사용되며 외부 AI 처리 시 식별 정보를 제거합니다. 원본 삭제를 요청할 수 있습니다.',
  '4. 보관 및 파기',
  '탈퇴 즉시 모든 정보를 파기하며, 법령상 보관 의무가 있는 정보는 해당 기간 동안 분리 보관합니다.',
];

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const PrivacyPolicyScreen.preview(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 54, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void fullText(WidgetTester tester, String value) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
  expect(paragraph.didExceedMaxLines, isFalse, reason: value);
  final bearing = (paragraph.text.style?.letterSpacing ?? 0).abs() / 2 + .01;
  for (final word in RegExp(r'\S+').allMatches(value)) {
    for (final box in paragraph.getBoxesForSelection(
      TextSelection(baseOffset: word.start, extentOffset: word.end),
    )) {
      expect(box.left, greaterThanOrEqualTo(-bearing), reason: value);
      expect(
        box.right,
        lessThanOrEqualTo(paragraph.size.width + bearing),
        reason: value,
      );
      expect(
        box.bottom,
        lessThanOrEqualTo(paragraph.size.height + .1),
        reason: value,
      );
    }
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Figma copy, baseline geometry and Glass styling', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
    expect(find.text('시행일 2026년 11월 1일'), findsOneWidget);
    for (final article in articles) {
      expect(find.text(article), findsOneWidget);
      fullText(tester, article);
    }
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(tester.getRect(key('date')), const Rect.fromLTWH(24, 122, 342, 14));
    expect(tester.getRect(key('card')), const Rect.fromLTWH(24, 156, 342, 342));
    final glass = tester.widget<AppGlassSurface>(key('card'));
    expect(glass.borderRadius, BorderRadius.circular(22));
    expect(glass.gradient, AppColors.glassSoftGradient);
    expect(glass.padding, const EdgeInsets.all(21));
    expect(
      tester.widget<Text>(find.text(articles.first)).style!.fontFamily,
      'Jua',
    );
    expect(find.byType(TextField), findsNothing);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('all copy readable, header fixed $size text $scale', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final headerRect = tester.getRect(key('header'));
        for (final article in articles) {
          fullText(tester, article);
        }
        await tester.ensureVisible(find.text(articles.last));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('header')), headerRect);
        final lastRect = tester.getRect(find.text(articles.last));
        expect(lastRect.bottom, lessThanOrEqualTo(size.height - 24 + .1));
        expect(lastRect.left, greaterThanOrEqualTo(24));
        expect(lastRect.right, lessThanOrEqualTo(size.width - 24));
        expect(tester.getSize(key('back')), const Size(44, 44));
        fullText(tester, '개인정보 처리방침');
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final systemBack in [false, true]) {
    testWidgets(
      'preview disclaimer and ${systemBack ? 'system' : 'header'} back',
      (tester) async {
        await open(tester, home: const PrivacyPolicyPreviewHost());
        expect(find.text(privacyPolicyPreviewNotice), findsOneWidget);
        expect(find.byType(PrivacyPolicyScreen), findsNothing);
        await tester.tap(find.text('미리보기 열기'));
        await tester.pumpAndSettle();
        expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(PrivacyPolicyScreen), findsNothing);
      },
    );
    testWidgets(
      'root preview ${systemBack ? 'system' : 'header'} back is safe',
      (tester) async {
        await open(tester);
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  }

  testWidgets('cancel leaves login and normal entry unchanged', (tester) async {
    await open(tester, home: const PrivacyPolicyPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PrivacyPolicyScreen), findsNothing);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('back accessibility role and section headings', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await open(tester);
      final back = tester.getSemantics(key('back'));
      expect(back.label, '뒤로가기');
      expect(back.flagsCollection.isButton, isTrue);
      for (final article in [
        articles[0],
        articles[2],
        articles[4],
        articles[6],
      ]) {
        expect(
          tester.getSemantics(find.text(article)).flagsCollection.isHeader,
          isTrue,
        );
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'repeated preview requests create one disclaimer and route; no HTTP',
    (tester) async {
      var requests = 0;
      await HttpOverrides.runZoned(
        () async {
          await open(
            tester,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    showPrivacyPolicyPreview(context);
                    showPrivacyPolicyPreview(context);
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('열기'));
          await tester.pumpAndSettle();
          expect(find.text(privacyPolicyPreviewNotice), findsOneWidget);
          await tester.tap(find.text('미리보기 열기'));
          await tester.pumpAndSettle();
          expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
          await tester.tap(key('back'));
          await tester.pumpAndSettle();
          expect(find.text('열기'), findsOneWidget);
          await tester.tap(find.text('열기'));
          await tester.pumpAndSettle();
          expect(find.text(privacyPolicyPreviewNotice), findsOneWidget);
        },
        createHttpClient: (_) {
          requests++;
          throw StateError('Unexpected HTTP');
        },
      );
      expect(requests, 0);
    },
  );
}
