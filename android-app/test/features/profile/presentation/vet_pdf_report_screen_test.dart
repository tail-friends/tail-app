import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/profile/presentation/vet_pdf_report_screen.dart';
import 'package:tail_friends/features/profile/presentation/data_photo_settings_screen.dart';
import 'package:tail_friends/vet_pdf_report_preview.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/main.dart';

Finder key(String name) => find.byKey(ValueKey('vet_pdf_$name'));
Finder dataKey(String name) => find.byKey(ValueKey('data_photo_$name'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const VetPdfReportScreen.preview(),
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

Future<void> enter(WidgetTester tester) async {
  await tester.tap(dataKey('pdf'));
  await tester.pumpAndSettle();
  expect(find.text(vetPdfReportPreviewNotice), findsOneWidget);
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets('Figma baseline page graph and fixed save geometry', (
    tester,
  ) async {
    await open(tester);
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(tester.getRect(key('page')), const Rect.fromLTWH(24, 120, 342, 403));
    expect(tester.getRect(key('save')), const Rect.fromLTWH(24, 760, 342, 50));
    expect(tester.getSize(key('graph')), const Size(298, 80));
    for (var i = 0; i < 4; i++) {
      expect(tester.getSize(key('summary_$i')), const Size(298, 34));
    }
    final box =
        tester.widget<DecoratedBox>(key('page')).decoration as BoxDecoration;
    expect(box.color, Colors.white);
    expect(box.borderRadius, BorderRadius.circular(10));
    expect(find.text('9:41'), findsNothing);
  });
  testWidgets('report is static widgets and exact original SVG vectors', (
    tester,
  ) async {
    await open(tester);
    for (final text in [
      'PDF 리포트',
      '욱이 건강 리포트',
      '레오파드 게코 · 수컷 · 2024.07.12 해칭',
      '2026.07–10',
      '체중',
      '48.1g → 53.4g (+5.3g)',
      '급여',
      '22회 · 안 먹음 2회',
      '탈피',
      '4회 · 평균 21일 · 부분 탈피 1회',
      '진료',
      '없음',
      '꼬리친구에서 생성 · 참고용 자료예요',
      'PDF 저장',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    for (final name in ['grid', 'line']) {
      expect(
        (tester.widget<SvgPicture>(key('graph_$name')).bytesLoader
                as SvgAssetLoader)
            .assetName,
        'assets/images/vet_pdf_graph_$name.svg',
      );
    }
    expect(tester.getSize(key('graph_grid')), const Size(298, 61));
    expect(tester.getSize(key('graph_line')).width, closeTo(291.391, .01));
    expect(
      find.descendant(of: key('page'), matching: find.byType(Image)),
      findsNothing,
    );
  });
  for (final action in ['share', 'save']) {
    testWidgets(
      '$action shows accurate non-operation notice and preserves report',
      (tester) async {
        await open(tester);
        for (var i = 0; i < 3; i++) {
          await tester.tap(key(action));
          await tester.pumpAndSettle();
        }
        expect(
          find.text(
            action == 'share'
                ? '디자인 미리보기에서는 실제 리포트를 공유하지 않습니다.'
                : '디자인 미리보기에서는 PDF 파일을 생성하지 않습니다.',
          ),
          findsOneWidget,
        );
        expect(find.text('48.1g → 53.4g (+5.3g)'), findsOneWidget);
        expect(key('page'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'data photo PDF opens disclosure and duplicate taps create one route',
    (tester) async {
      await open(tester, home: const DataPhotoSettingsScreen.preview());
      await tester.tap(dataKey('pdf'));
      await tester.pumpAndSettle();
      expect(find.text(vetPdfReportPreviewNotice), findsOneWidget);
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(key('screen'), findsNothing);
      final context = tester.element(dataKey('screen'));
      showVetPdfReportPreview(context);
      showVetPdfReportPreview(context);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(key('screen'), findsOneWidget);
    },
  );
  for (final system in [false, true]) {
    testWidgets(
      '${system ? 'system' : 'header'} back preserves parent photo state and CSV flow',
      (tester) async {
        await open(tester, home: const DataPhotoSettingsScreen.preview());
        await tester.tap(dataKey('keep'));
        await tester.pump();
        await tester.tap(dataKey('cancel'));
        await tester.pump();
        await enter(tester);
        if (system) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(dataKey('keep')).properties.toggled,
          isFalse,
        );
        expect(dataKey('confirm'), findsNothing);
        await tester.tap(dataKey('csv'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('미리보기 열기'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('csv_export_sheet')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('csv_export_close')));
        await tester.pumpAndSettle();
        await enter(tester);
        expect(key('page'), findsOneWidget);
      },
    );
  }
  testWidgets('standalone root back and independent preview host remain safe', (
    tester,
  ) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await open(tester, home: const VetPdfReportPreviewHost());
    expect(find.text(vetPdfReportPreviewNotice), findsOneWidget);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsOneWidget);
  });
  testWidgets(
    'button touch targets and graph semantics describe design example',
    (tester) async {
      final h = tester.ensureSemantics();
      try {
        await open(tester);
        for (final name in ['back', 'share', 'save']) {
          expect(
            tester.getSize(key(name)).shortestSide,
            greaterThanOrEqualTo(44),
          );
        }
        expect(
          find.bySemanticsLabel('Figma 예시 체중 추이 그래프. 실제 측정 데이터가 아닙니다.'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('공유'), findsOneWidget);
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
        '$size scale $scale page scroll text and fixed save are usable',
        (tester) async {
          await open(tester, size: size, scale: scale);
          final save = tester.getRect(key('save'));
          for (final text in [
            '욱이 건강 리포트',
            '레오파드 게코 · 수컷 · 2024.07.12 해칭',
            '2026.07–10',
            '48.1g → 53.4g (+5.3g)',
            '4회 · 평균 21일 · 부분 탈피 1회',
          ]) {
            final p = tester.renderObject<RenderParagraph>(find.text(text));
            expect(p.didExceedMaxLines, isFalse);
            for (var i = 0; i < text.length; i++) {
              if (text[i].trim().isEmpty) continue;
              for (final b in p.getBoxesForSelection(
                TextSelection(baseOffset: i, extentOffset: i + 1),
              )) {
                expect(b.right, lessThanOrEqualTo(p.size.width + .1));
              }
            }
          }
          await tester.ensureVisible(find.text('꼬리친구에서 생성 · 참고용 자료예요'));
          await tester.pumpAndSettle();
          expect(tester.getRect(key('save')), save);
          await tester.tap(key('save'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'save share and entry avoid network and platform file/share calls',
    (tester) async {
      var requests = 0;
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await HttpOverrides.runZoned(
        () async {
          await open(tester);
          await tester.tap(key('save'));
          await tester.pumpAndSettle();
          await tester.tap(key('share'));
          await tester.pumpAndSettle();
        },
        createHttpClient: (_) {
          requests++;
          throw StateError('Unexpected network');
        },
      );
      expect(requests, 0);
      expect(
        calls.where(
          (x) =>
              x.contains('file') || x.contains('share') || x.contains('intent'),
        ),
        isEmpty,
      );
      await tester.pumpWidget(const TailFriendsApp());
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
