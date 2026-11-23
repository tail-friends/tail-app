import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/warning_units_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/warning_units_preview.dart';

Finder key(String suffix) => find.byKey(ValueKey('warning_units_$suffix'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const WarningUnitsScreen.preview(),
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

bool selected(WidgetTester tester, bool celsius) =>
    tester
        .getSemantics(key(celsius ? 'celsius' : 'fahrenheit'))
        .flagsCollection
        .isSelected ==
    ui.Tristate.isTrue;

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showWarningUnitsPreview(context),
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
  testWidgets('Figma card geometry original background and example labels', (
    tester,
  ) async {
    await open(tester);
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(
      tester.getRect(key('thresholds')),
      const Rect.fromLTWH(24, 161, 342, 197),
    );
    expect(tester.getRect(key('units')), const Rect.fromLTWH(24, 417, 342, 76));
    expect(tester.getSize(key('unit_visual')), const Size(140, 42));
    expect(
      (tester.widget<Image>(key('background')).image as AssetImage).assetName,
      'assets/images/warning_units_background.png',
    );
    for (final name in [
      '경고 기준 · 단위',
      '건강 경고 기준',
      '거식 경고',
      '체중 감소 경고',
      '묽은 변 경고',
      '온도 단위',
      '연속 안 먹음 횟수',
      '최근 30일 기준',
      '연속 횟수',
      '서버에는 °C로 저장돼요',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('3번'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('2번'), findsOneWidget);
    expect(find.text('9:41'), findsNothing);
  });
  for (var i = 0; i < 3; i++) {
    testWidgets(
      'threshold $i increments independently and prevents negative display',
      (tester) async {
        await open(tester);
        const defaults = [3, 10, 2];
        await tester.tap(key('plus_$i'));
        await tester.pump();
        expect(
          tester.widget<Text>(key('value_$i')).data,
          '${defaults[i] + 1}${i == 1 ? '%' : '번'}',
        );
        for (var n = 0; n < defaults[i] + 3; n++) {
          await tester.tap(key('minus_$i'));
          await tester.pump();
        }
        expect(
          tester.widget<Text>(key('value_$i')).data,
          '0${i == 1 ? '%' : '번'}',
        );
        expect(tester.widget<InkWell>(key('minus_$i')).onTap, isNull);
        await tester.tap(key('plus_$i'));
        await tester.pump();
        expect(
          tester.widget<Text>(key('value_$i')).data,
          '1${i == 1 ? '%' : '번'}',
        );
        for (var j = 0; j < 3; j++) {
          if (i != j) {
            expect(
              tester.widget<Text>(key('value_$j')).data,
              '${defaults[j]}${j == 1 ? '%' : '번'}',
            );
          }
        }
      },
    );
  }
  testWidgets(
    'temperature selection remains local and leaves examples unchanged',
    (tester) async {
      final h = tester.ensureSemantics();
      try {
        await open(tester);
        expect(selected(tester, true), isTrue);
        await tester.tap(key('fahrenheit'));
        await tester.pumpAndSettle();
        expect(selected(tester, false), isTrue);
        expect(selected(tester, true), isFalse);
        expect(
          find.text('서버에는 °C로 저장돼요'),
          findsOneWidget,
        ); // Unchanged Figma copy, explained before entry.
        expect(find.text('10%'), findsOneWidget);
        await tester.tap(key('celsius'));
        await tester.pumpAndSettle();
        expect(selected(tester, true), isTrue);
      } finally {
        h.dispose();
      }
    },
  );
  testWidgets(
    '28px step visuals have 44px accessible touch targets and actions',
    (tester) async {
      final h = tester.ensureSemantics();
      try {
        await open(tester);
        for (var i = 0; i < 3; i++) {
          for (final kind in ['minus', 'plus']) {
            expect(tester.getSize(key('${kind}_$i')), const Size(44, 44));
            expect(
              tester.getSize(key('${kind}_visual_$i')),
              const Size(28, 28),
            );
          }
        }
        final n = tester.getSemantics(find.bySemanticsLabel('거식 경고 증가'));
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: ui.SemanticsAction.tap,
            viewId: tester.view.viewId,
            nodeId: n.id,
          ),
        );
        await tester.pump();
        expect(find.text('4번'), findsOneWidget);
        final f = tester.getSemantics(key('fahrenheit'));
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: ui.SemanticsAction.tap,
            viewId: tester.view.viewId,
            nodeId: f.id,
          ),
        );
        await tester.pump();
        expect(selected(tester, false), isTrue);
        expect(
          tester.getSize(key('fahrenheit')).height,
          greaterThanOrEqualTo(44),
        );
        expect(tester.getSize(key('back')), const Size(44, 44));
      } finally {
        h.dispose();
      }
    },
  );
  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '$size scale $scale controls labels and units accessible without overflow',
        (tester) async {
          await open(tester, size: size, scale: scale);
          final header = tester.getRect(key('header'));
          for (final title in [
            '거식 경고',
            '체중 감소 경고',
            '묽은 변 경고',
            '온도 단위',
            '서버에는 °C로 저장돼요',
          ]) {
            final p = tester.renderObject<RenderParagraph>(find.text(title));
            expect(p.didExceedMaxLines, isFalse);
            for (var c = 0; c < title.length; c++) {
              if (title[c].trim().isEmpty) continue;
              for (final box in p.getBoxesForSelection(
                TextSelection(baseOffset: c, extentOffset: c + 1),
              )) {
                expect(box.right, lessThanOrEqualTo(p.size.width + .1));
              }
            }
          }
          await tester.ensureVisible(key('fahrenheit'));
          await tester.pumpAndSettle();
          expect(key('fahrenheit').hitTestable(), findsOneWidget);
          await tester.tap(key('fahrenheit'));
          await tester.pumpAndSettle();
          expect(tester.getRect(key('header')), header);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('preview notice cancellation and duplicate entry guard', (
    tester,
  ) async {
    await open(tester, home: const Entry());
    await tester.tap(find.text('열기'));
    await tester.tap(find.text('열기'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(warningUnitsPreviewNotice), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsNothing);
  });
  for (final system in [false, true]) {
    testWidgets(
      '${system ? 'system' : 'header'} back and fresh preview reset',
      (tester) async {
        await open(tester, home: const Entry());
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await accept(tester);
        await tester.tap(key('plus_0'));
        await tester.pump();
        await tester.tap(key('fahrenheit'));
        await tester.pump();
        if (system) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.text('열기'), findsOneWidget);
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await accept(tester);
        expect(find.text('3번'), findsOneWidget);
        expect(tester.widget<Text>(key('value_0')).data, '3번');
        final h = tester.ensureSemantics();
        try {
          await tester.pump();
          expect(selected(tester, true), isTrue);
        } finally {
          h.dispose();
        }
      },
    );
  }
  testWidgets('standalone preview host disclosure and root back', (
    tester,
  ) async {
    await open(tester, home: const WarningUnitsPreviewHost());
    expect(find.text(warningUnitsPreviewNotice), findsOneWidget);
    await accept(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
  testWidgets('no network requests or normal app flow change', (tester) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await open(tester);
        for (var i = 0; i < 3; i++) {
          await tester.tap(key('plus_$i'));
          await tester.pump();
        }
        await tester.tap(key('fahrenheit'));
        await tester.pump();
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
