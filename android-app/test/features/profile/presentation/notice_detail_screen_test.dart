import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/notice_detail_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/notice_detail_preview.dart';

Finder key(String name) => find.byKey(ValueKey('notice_detail_$name'));
const title = '꼬리친구 1.0이 출시됐어요';
const paragraphs = [
  '안녕하세요, 꼬리친구 팀이에요. 우리 아이의 하루를 기록하고, 사진 한 장으로 캐릭터를 만드는 꼬리친구가 정식 출시됐어요.',
  '급여·탈피·체중 기록, 돌봄 주기 알림, 사진 기반 캐릭터를 지금 바로 사용해 보세요. 의견은 마이 › 문의하기로 보내주세요.',
];

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 24,
  Widget home = const NoticeDetailScreen.preview(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
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
  testWidgets('verbatim Figma copy, empty navbar and baseline geometry', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(title), findsOneWidget);
    expect(find.text('2026.11.01'), findsOneWidget);
    for (final value in paragraphs) {
      expect(find.text(value), findsOneWidget);
      fullText(tester, value);
    }
    expect(
      find.descendant(of: key('header'), matching: find.byType(Text)),
      findsNothing,
    );
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(tester.getRect(key('title')), const Rect.fromLTWH(24, 122, 342, 19));
    expect(tester.getRect(key('date')), const Rect.fromLTWH(24, 145, 342, 14));
    expect(tester.getRect(key('card')), const Rect.fromLTWH(24, 179, 342, 292));
    expect(
      tester.getRect(key('cover')),
      const Rect.fromLTWH(45, 200, 300, 150),
    );
    expect(
      tester.getRect(key('character_slot')),
      const Rect.fromLTWH(168, 230, 60, 90),
    );
  });

  testWidgets('existing Glass tokens, cover gradient and exact local assets', (
    tester,
  ) async {
    await open(tester);
    final glass = tester.widget<AppGlassSurface>(key('card'));
    expect(glass.gradient, AppColors.glassSoftGradient);
    expect(glass.borderRadius, BorderRadius.circular(22));
    expect(glass.padding, const EdgeInsets.all(21));
    final gradient =
        (tester.widget<DecoratedBox>(key('cover')).decoration as BoxDecoration)
                .gradient!
            as LinearGradient;
    expect(gradient.colors, const [Color(0xFFF3E2C2), Color(0xFFE6E1D6)]);
    expect(gradient.stops, [.25, .75]);
    expect(tester.widget<Text>(key('title')).style!.fontFamily, 'Jua');
    expect(tester.widget<Image>(key('background')).image, isA<AssetImage>());
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(16, 16));
    expect(
      find.descendant(of: key('character_slot'), matching: find.byType(Image)),
      findsNothing,
    );
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('readable copy and fixed back $size text $scale', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final header = tester.getRect(key('header'));
        for (final value in [title, '2026.11.01', ...paragraphs]) {
          fullText(tester, value);
        }
        await tester.ensureVisible(find.text(paragraphs.last));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('header')), header);
        final last = tester.getRect(find.text(paragraphs.last));
        expect(last.bottom, lessThanOrEqualTo(size.height - 24 + .1));
        expect(last.left, greaterThanOrEqualTo(24));
        expect(last.right, lessThanOrEqualTo(size.width - 24));
        expect(tester.getSize(key('back')), const Size(44, 44));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('larger system insets respected', (tester) async {
    await open(
      tester,
      size: const Size(320, 640),
      scale: 2,
      top: 80,
      bottom: 48,
    );
    expect(tester.getRect(key('header')).top, 84);
    await tester.ensureVisible(find.text(paragraphs.last));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text(paragraphs.last)).bottom,
      lessThanOrEqualTo(592),
    );
    expect(tester.takeException(), isNull);
  });

  for (final systemBack in [false, true]) {
    testWidgets('disclaimer and ${systemBack ? 'system' : 'header'} back', (
      tester,
    ) async {
      await open(tester, home: const NoticeDetailPreviewHost());
      expect(find.text(noticeDetailPreviewNotice), findsOneWidget);
      expect(find.byType(NoticeDetailScreen), findsNothing);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(key('back'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NoticeDetailScreen), findsNothing);
    });
    testWidgets(
      'root ${systemBack ? 'system' : 'header'} back returns safely',
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

  testWidgets('cancel leaves login and original app entry unchanged', (
    tester,
  ) async {
    await open(tester, home: const NoticeDetailPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('accessible article heading and back control', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await open(tester);
      expect(
        tester.getSemantics(key('title')).flagsCollection.isHeader,
        isTrue,
      );
      expect(tester.getSemantics(key('back')).label, '뒤로가기');
      expect(tester.getSemantics(key('back')).flagsCollection.isButton, isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('duplicate entry is guarded, prior route preserved, no HTTP', (
    tester,
  ) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await open(
          tester,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  showNoticeDetailPreview(context);
                  showNoticeDetailPreview(context);
                },
                child: const Text('상세 예시 열기'),
              ),
            ),
          ),
        );
        final previous = tester.element(find.text('상세 예시 열기'));
        await tester.tap(find.text('상세 예시 열기'));
        await tester.pumpAndSettle();
        expect(find.text(noticeDetailPreviewNotice), findsOneWidget);
        await tester.tap(find.text('미리보기 열기'));
        await tester.pumpAndSettle();
        expect(find.byType(NoticeDetailScreen), findsOneWidget);
        await tester.tap(key('back'));
        await tester.pumpAndSettle();
        expect(tester.element(find.text('상세 예시 열기')), same(previous));
        await tester.tap(find.text('상세 예시 열기'));
        await tester.pumpAndSettle();
        expect(find.text(noticeDetailPreviewNotice), findsOneWidget);
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Unexpected HTTP');
      },
    );
    expect(requests, 0);
  });
}
