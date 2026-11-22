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
import 'package:tail_friends/features/profile/presentation/terrarium_theme_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/terrarium_theme_preview.dart';

Finder key(String suffix) => find.byKey(ValueKey('terrarium_theme_$suffix'));
const names = ['사막', '열대우림', '바위 협곡', '물가', '달밤', '내 사육장 사진으로'];
const unavailable = '테마 변경 기능은 아직 연결되지 않았습니다.';

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const TerrariumThemeScreen.preview(),
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

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showTerrariumThemePreview(context),
        child: const Text('열기'),
      ),
    ),
  );
}

Future<void> accept(WidgetTester tester) async {
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Figma header grid and unequal first-row card geometry', (
    tester,
  ) async {
    await open(tester);
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(tester.getRect(key('grid')), const Rect.fromLTWH(24, 156, 342, 467));
    const rects = [
      Rect.fromLTWH(24, 156, 164, 145),
      Rect.fromLTWH(198, 156, 168, 149),
      Rect.fromLTWH(24, 315, 166, 149),
      Rect.fromLTWH(200, 315, 166, 149),
      Rect.fromLTWH(24, 474, 166, 149),
      Rect.fromLTWH(200, 474, 166, 149),
    ];
    for (var i = 0; i < 6; i++) {
      expect(tester.getRect(key('card_$i')), rects[i]);
      expect(find.text(names[i]), findsOneWidget);
      expect(tester.getSize(key('placeholder_$i')).height, 96);
      expect(tester.getSize(key('icon_$i')), const Size(28, 24));
    }
    expect(tester.getSize(key('back')), const Size(44, 44));
    expect(find.text('사용 중'), findsOneWidget);
    expect(find.text('미리보기'), findsNWidgets(4));
    expect(find.text('확장'), findsOneWidget);
  });

  testWidgets('original placeholder assets empty character and glass styling', (
    tester,
  ) async {
    await open(tester);
    expect(tester.getSize(key('character_slot')), const Size(36, 54));
    expect(
      find.byType(Image),
      findsOneWidget,
    ); // Background only; no theme/character photos.
    for (var i = 0; i < 6; i++) {
      expect(
        tester.widget<ColoredBox>(key('placeholder_$i')).color,
        const Color(0xFFE4DDD3),
      );
      final svg = tester.widget<SvgPicture>(key('icon_$i'));
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/icons/terrarium_theme_placeholder.svg',
      );
      expect(
        tester.widget<Opacity>(key('opacity_$i')).opacity,
        i == 1 || i == 5 ? .45 : 1,
      );
      final surface = tester.widget<AppGlassSurface>(key('surface_$i'));
      expect(surface.borderRadius, BorderRadius.circular(22));
      expect(surface.boxShadow.length, i == 0 ? 2 : 0);
      expect(
        surface.gradient,
        i == 0
            ? const LinearGradient(colors: [Colors.white, Colors.white])
            : AppColors.glassSoftGradient,
      );
    }
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  for (var i = 0; i < 6; i++) {
    testWidgets(
      '${names[i]} only shows unavailable feedback and preserves desert',
      (tester) async {
        await open(tester);
        await tester.tap(key('tap_$i'));
        await tester.pumpAndSettle();
        expect(find.text(unavailable), findsOneWidget);
        expect(
          tester.widget<Semantics>(key('card_0')).properties.selected,
          isTrue,
        );
        for (var j = 1; j < 6; j++) {
          expect(
            tester.widget<Semantics>(key('card_$j')).properties.selected,
            isFalse,
          );
        }
        expect(key('screen'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  }

  testWidgets('TalkBack card actions labels selection and touch targets', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await open(tester);
      for (var i = 0; i < 6; i++) {
        final node = tester.getSemantics(key('card_$i'));
        expect(node.label, contains(names[i]));
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        expect(
          tester.getSize(key('tap_$i')).shortestSide,
          greaterThanOrEqualTo(44),
        );
      }
      final node = tester.getSemantics(key('card_5'));
      tester.binding.performSemanticsAction(
        ui.SemanticsActionEvent(
          type: ui.SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(unavailable), findsOneWidget);
      expect(find.bySemanticsLabel('뒤로가기'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('scroll and untruncated text at $size scale $scale', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final header = tester.getRect(key('header'));
        for (final name in [...names, '사용 중', '확장']) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(name),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          for (final box in paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: name.length),
          )) {
            expect(box.left, greaterThanOrEqualTo(-.1));
            expect(box.right, lessThanOrEqualTo(paragraph.size.width + .1));
          }
        }
        await tester.ensureVisible(key('tap_5'));
        await tester.pumpAndSettle();
        expect(key('tap_5').hitTestable(), findsOneWidget);
        expect(tester.getRect(key('header')), header);
        await tester.tap(key('tap_5'));
        await tester.pumpAndSettle();
        expect(find.text(unavailable), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('disclaimer cancellation and duplicate entry protection', (
    tester,
  ) async {
    await open(tester, home: const Entry());
    await tester.tap(find.text('열기'));
    await tester.tap(find.text('열기'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(terrariumThemePreviewNotice), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsNothing);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await accept(tester);
    expect(key('screen'), findsOneWidget);
  });

  for (final system in [false, true]) {
    testWidgets(
      '${system ? 'system' : 'header'} back preserves previous screen and allows reopen',
      (tester) async {
        await open(tester, home: const Entry());
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await accept(tester);
        await tester.tap(key('tap_4'));
        await tester.pumpAndSettle();
        if (system) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.text('열기'), findsOneWidget);
        expect(find.text(unavailable), findsNothing);
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await accept(tester);
        expect(
          tester.widget<Semantics>(key('card_0')).properties.selected,
          isTrue,
        );
      },
    );
  }

  testWidgets('standalone root back safely returns to login', (tester) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('preview host explains examples before entering', (tester) async {
    await open(tester, home: const TerrariumThemePreviewHost());
    expect(find.text(terrariumThemePreviewNotice), findsOneWidget);
    await accept(tester);
    expect(key('screen'), findsOneWidget);
  });

  testWidgets('cards never request network and normal app still starts login', (
    tester,
  ) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await open(tester);
        for (var i = 0; i < 6; i++) {
          await tester.tap(key('tap_$i'));
          await tester.pumpAndSettle();
        }
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Unexpected network');
      },
    );
    expect(requests, 0);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(key('screen'), findsNothing);
  });
}
