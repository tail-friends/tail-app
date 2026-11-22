import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/notices_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/notices_preview.dart';

Finder key(String name) => find.byKey(ValueKey('notices_$name'));
const titles = [
  '꼬리친구 1.0이 출시됐어요',
  '사진 캐릭터 생성 품질 개선',
  '개인정보 처리방침 개정 안내',
  '서버 점검 안내 (11/12 02:00–04:00)',
];
const dates = ['2026.11.01', '2026.11.08', '2026.10.25', '2026.10.20'];

Future<void> pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const NoticesScreen.preview(),
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

void fullText(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  expect(p.didExceedMaxLines, isFalse);
  for (final word in RegExp(r'\S+').allMatches(text)) {
    for (final box in p.getBoxesForSelection(
      TextSelection(baseOffset: word.start, extentOffset: word.end),
    )) {
      final bearing = (p.text.style?.letterSpacing ?? 0).abs() / 2 + .01;
      expect(box.left, greaterThanOrEqualTo(-bearing), reason: text);
      expect(box.right, lessThanOrEqualTo(p.size.width + .11), reason: text);
      expect(box.bottom, lessThanOrEqualTo(p.size.height + .11), reason: text);
    }
  }
}

Future<void> enter(WidgetTester tester) async {
  await pump(tester, home: const NoticesPreviewHost());
  expect(find.text(noticesPreviewNotice), findsOneWidget);
  expect(find.text(titles[0]), findsNothing);
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
  expect(key('screen'), findsOneWidget);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await loader.load();
  });

  testWidgets('Figma 헤더·342×257 Glass 카드·제목·날짜·새 표시를 원본 순서대로 표시한다', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(
      tester.getRect(key('back_surface')),
      const Rect.fromLTWH(24, 62, 36, 36),
    );
    expect(tester.getRect(key('card')), const Rect.fromLTWH(24, 122, 342, 257));
    expect(tester.getSize(key('back')), const Size(44, 44));
    for (var i = 0; i < 4; i++) {
      expect(
        find.descendant(of: key('item_$i'), matching: find.text(titles[i])),
        findsOneWidget,
      );
      expect(
        find.descendant(of: key('item_$i'), matching: find.text(dates[i])),
        findsOneWidget,
      );
      expect(tester.getSize(key('item_$i')).height, 63);
    }
    expect(key('new_0'), findsOneWidget);
    expect(key('new_1'), findsOneWidget);
    expect(key('new_2'), findsNothing);
    expect(key('new_3'), findsNothing);
    expect(find.byType(Divider), findsNWidgets(3));
    final card = tester.widget<AppGlassSurface>(key('card'));
    expect(card.borderRadius, BorderRadius.circular(22));
    expect(card.boxShadow.single.blurRadius, 32);
    expect(find.text('9:41'), findsNothing);
  });

  for (var i = 0; i < 4; i++) {
    testWidgets('공지 $i 탭은 상세 미연결 안내만 표시하고 목록·새 표시·라우트를 유지한다', (tester) async {
      await pump(tester);
      final original = tester.element(key('screen'));
      await tester.tap(key('item_$i'));
      await tester.pumpAndSettle();
      expect(find.text('공지 상세 화면은 아직 연결되지 않았습니다.'), findsOneWidget);
      expect(tester.element(key('screen')), same(original));
      expect(find.byType(LoginScreen), findsNothing);
      expect(key('new_0'), findsOneWidget);
      expect(key('new_1'), findsOneWidget);
      for (final t in titles) {
        expect(find.text(t), findsOneWidget);
      }
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale에서 제목·날짜가 잘리지 않고 스크롤과 44px 터치가 가능하다', (
        tester,
      ) async {
        await pump(tester, size: size, scale: scale);
        final header = tester.getRect(key('header'));
        for (var i = 0; i < 4; i++) {
          await tester.ensureVisible(key('item_$i'));
          await tester.pumpAndSettle();
          fullText(tester, titles[i]);
          fullText(tester, dates[i]);
          final rect = tester.getRect(key('item_$i'));
          expect(rect.left, greaterThanOrEqualTo(24));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
          expect(rect.height, greaterThanOrEqualTo(44));
        }
        expect(tester.getRect(key('header')), header);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('많은 공지도 마지막 항목까지 스크롤하며 헤더·뒤로가기는 고정된다', (tester) async {
    final items = List.generate(
      30,
      (i) =>
          NoticePreviewItem(title: '테스트 공지 ${i + 1}', displayDate: '디자인 검증 예시'),
    );
    await pump(
      tester,
      size: const Size(320, 640),
      scale: 2,
      home: NoticesScreen.preview(items: items),
    );
    final header = tester.getRect(key('header'));
    await tester.ensureVisible(key('item_29'));
    await tester.pumpAndSettle();
    expect(tester.getRect(key('item_29')).bottom, lessThanOrEqualTo(616));
    expect(tester.getRect(key('header')), header);
    await tester.tap(key('item_29'));
    await tester.pumpAndSettle();
    expect(find.text('공지 상세 화면은 아직 연결되지 않았습니다.'), findsOneWidget);
    await tester.tap(key('back'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('원본 자산과 각 SVG의 실제 슬롯 크기 및 글꼴을 유지한다', (tester) async {
    await pump(tester);
    expect(
      (tester.widget<Image>(key('background')).image as AssetImage).assetName,
      'assets/images/account_withdrawal_background.png',
    );
    for (final element in find.byType(SvgPicture).evaluate()) {
      final svg = element.widget as SvgPicture;
      final asset = (svg.bytesLoader as SvgAssetLoader).assetName;
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      final render = element.renderObject! as RenderBox;
      final a = render.localToGlobal(Offset.zero);
      final b = render.localToGlobal(
        Offset(render.size.width, render.size.height),
      );
      final size = asset.contains('new_dot')
          ? 6.0
          : asset.contains('chevron_left')
          ? 16.0
          : 14.0;
      expect(b.dx - a.dx, closeTo(size, .1));
      expect(b.dy - a.dy, closeTo(size, .1));
    }
    expect(find.byType(SvgPicture), findsNWidgets(7));
    expect(tester.widget<Text>(find.text(titles[0])).style!.fontFamily, 'Jua');
    expect(tester.widget<Text>(find.text(titles[0])).style!.fontSize, 13);
    expect(tester.widget<Text>(find.text(dates[0])).style!.fontSize, 11);
  });

  testWidgets('접근성에 제목·날짜·새 표시와 탭 동작을 함께 알린다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pump(tester);
      final node = tester.getSemantics(
        find.bySemanticsLabel('${titles[0]}, ${dates[0]}, 새 공지 표시'),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      expect(
        find.bySemanticsLabel('${titles[2]}, ${dates[2]}'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('여러 항목 연속 탭은 안내를 중복하지 않으며 HTTP 요청이 없다', (tester) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await pump(tester);
        for (var i = 0; i < 4; i++) {
          tester.widget<InkWell>(key('item_$i')).onTap!();
        }
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(key('new_0'), findsOneWidget);
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('No network in UI preview');
      },
    );
    expect(requests, 0);
  });

  for (final action in ['cancel', 'back']) {
    testWidgets('사전 안내 $action 시에는 예시 공지를 노출하지 않는다', (tester) async {
      await pump(tester, home: const NoticesPreviewHost());
      expect(find.text(noticesPreviewNotice), findsOneWidget);
      if (action == 'cancel') {
        await tester.tap(find.text('취소'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(titles[0]), findsNothing);
    });
  }

  for (final action in ['header', 'system']) {
    testWidgets('미리보기 $action 뒤로가기는 로그인으로 안전 복귀하며 안내를 남기지 않는다', (tester) async {
      await enter(tester);
      await tester.tap(key('item_0'));
      await tester.pumpAndSettle();
      if (action == 'header') {
        await tester.tap(key('back'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(key('screen'), findsNothing);
    });
  }

  testWidgets('일반 앱은 로그인에서 시작하며 공지 예시를 표시하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(key('screen'), findsNothing);
    expect(find.text(titles[0]), findsNothing);
  });
}
