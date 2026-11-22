import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/inquiry_screen.dart';
import 'package:tail_friends/inquiry_preview.dart';
import 'package:tail_friends/main.dart';

Finder key(String value) => find.byKey(ValueKey('inquiry_$value'));

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const InquiryScreen.preview(),
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

Finder get titleField =>
    find.descendant(of: key('title'), matching: find.byType(TextFormField));

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('empty local draft and design labels', (tester) async {
    await open(tester);
    expect(find.text('문의하기'), findsOneWidget);
    expect(find.text('0 / 1000'), findsOneWidget);
    expect(tester.widget<TextFormField>(titleField).controller!.text, isEmpty);
    expect(
      tester.widget<TextFormField>(key('content')).controller!.text,
      isEmpty,
    );
    expect(find.text('답변은 가입한 이메일로 보내드려요'), findsOneWidget);
    expect(
      tester.getRect(key('content_surface')),
      const Rect.fromLTWH(24, 306, 342, 140),
    );
    expect(tester.getRect(key('send')), const Rect.fromLTWH(24, 760, 342, 50));
  });

  testWidgets('single category selection and minimum touch targets', (
    tester,
  ) async {
    await open(tester);
    for (final category in ['캐릭터', '계정', '제안', '앱 오류']) {
      await tester.tap(key('category_$category'));
      await tester.pumpAndSettle();
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: key('category_$category'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.selected, isTrue);
      final rect = tester.getRect(key('category_$category'));
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
    }
    expect(tester.getSize(key('back')), const Size(44, 44));
  });

  testWidgets('editable title, multiline content and grapheme limit', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(titleField, '문의 제목');
    await tester.enterText(key('content'), '첫 줄\n두 번째 줄');
    await tester.pumpAndSettle();
    expect(
      find.text('${'첫 줄\n두 번째 줄'.characters.length} / 1000'),
      findsOneWidget,
    );
    await tester.enterText(key('content'), List.filled(1001, '🐢').join());
    await tester.pumpAndSettle();
    expect(find.text('1000 / 1000'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(key('content'))
          .controller!
          .text
          .characters
          .length,
      1000,
    );
    expect(tester.widget<TextFormField>(titleField).controller!.text, '문의 제목');
  });

  testWidgets('attachment and repeated send preserve draft without requests', (
    tester,
  ) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await open(tester);
        await tester.enterText(titleField, '제목 유지');
        await tester.enterText(key('content'), '내용 유지');
        await tester.tap(key('category_계정'));
        await tester.ensureVisible(key('attach'));
        await tester.tap(key('attach'));
        await tester.pumpAndSettle();
        expect(find.text('스크린샷 첨부 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.tap(key('send'));
        }
        await tester.pumpAndSettle();
        expect(find.text('UI 미리보기입니다. 문의가 전송되지 않았습니다.'), findsOneWidget);
        expect(find.text('스크린샷 첨부 기능은 아직 연결되지 않았습니다.'), findsNothing);
        expect(
          tester.widget<TextFormField>(titleField).controller!.text,
          '제목 유지',
        );
        expect(
          tester.widget<TextFormField>(key('content')).controller!.text,
          '내용 유지',
        );
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Unexpected HTTP');
      },
    );
    expect(requests, 0);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('scroll and fixed send $size text $scale', (tester) async {
        await open(tester, size: size, scale: scale);
        final sendBefore = tester.getRect(key('send'));
        await tester.drag(key('scroll'), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('send')), sendBefore);
        await tester.ensureVisible(key('attach'));
        await tester.tap(key('attach'));
        await tester.pumpAndSettle();
        expect(find.text('스크린샷 첨부 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(sendBefore.left, 24);
        expect(sendBefore.right, size.width - 24);
        expect(sendBefore.bottom, lessThanOrEqualTo(size.height - 24));
      });
    }
  }

  testWidgets('keyboard keeps draft and send reachable', (tester) async {
    await open(tester, size: const Size(320, 640), scale: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.ensureVisible(key('content'));
    await tester.enterText(key('content'), '키보드 입력');
    await tester.pumpAndSettle();
    expect(tester.getRect(key('send')).bottom, lessThanOrEqualTo(380));
    await tester.tap(key('send'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(key('content')).controller!.text,
      '키보드 입력',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'content has an accessible name and selected category is exclusive',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await open(tester);
        expect(tester.getSemantics(key('content')).label, startsWith('내용\n'));
        await tester.tap(key('category_제안'));
        await tester.pumpAndSettle();
        for (final category in ['앱 오류', '캐릭터', '계정', '제안']) {
          final semantics = tester.widget<Semantics>(
            find
                .ancestor(
                  of: key('category_$category'),
                  matching: find.byType(Semantics),
                )
                .first,
          );
          expect(semantics.properties.selected, category == '제안');
        }
      } finally {
        handle.dispose();
      }
    },
  );

  for (final systemBack in [false, true]) {
    testWidgets('preview notice and ${systemBack ? 'system' : 'header'} back', (
      tester,
    ) async {
      await open(tester, home: const InquiryPreviewHost());
      expect(find.text(inquiryPreviewNotice), findsOneWidget);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(find.byType(InquiryScreen), findsOneWidget);
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(key('back'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(InquiryScreen), findsNothing);
    });
  }

  testWidgets('preview disclaimer cancellation and normal login entry', (
    tester,
  ) async {
    await open(tester, home: const InquiryPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(InquiryScreen), findsNothing);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
