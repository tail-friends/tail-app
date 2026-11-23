import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/profile/presentation/csv_export_sheet.dart';
import 'package:tail_friends/features/profile/presentation/data_photo_settings_screen.dart';
import 'package:tail_friends/csv_export_preview.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/main.dart';

Finder key(String name) => find.byKey(ValueKey('csv_export_$name'));
Finder dataKey(String name) => find.byKey(ValueKey('data_photo_$name'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool accept = true,
  Widget home = const DataPhotoSettingsScreen.preview(),
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
  if (home is! CsvExportPreviewHost) {
    await tester.ensureVisible(dataKey('csv'));
    await tester.tap(dataKey('csv'));
    await tester.pumpAndSettle();
  }
  if (accept) {
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
  }
}

bool enabled(WidgetTester tester, int i) =>
    tester.widget<Semantics>(key('toggle_$i')).properties.toggled!;
void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets('modal reuses data photo backdrop and Figma geometry', (
    tester,
  ) async {
    await open(tester);
    expect(dataKey('screen'), findsOneWidget);
    expect(tester.getRect(key('sheet')), const Rect.fromLTWH(0, 312, 390, 532));
    expect(tester.getSize(key('grabber')), const Size(32, 4));
    expect(tester.getSize(key('start')), const Size(166, 62));
    expect(tester.getSize(key('end')), const Size(166, 62));
    expect(tester.getSize(key('export')), const Size(340, 50));
    expect(find.text('선택한 기간의 모든 기록'), findsOneWidget);
    expect(find.text('2026.07.21'), findsOneWidget);
    expect(find.text('2026.10.20'), findsOneWidget);
    expect(find.text('기록 214개 · 7마리'), findsOneWidget);
    expect(
      tester.widget<Semantics>(key('period_1')).properties.selected,
      isTrue,
    );
    final route =
        ModalRoute.of(tester.element(key('sheet'))) as ModalBottomSheetRoute;
    expect(route.barrierColor, const Color(0x332F6B57));
  });
  testWidgets(
    'preview disclosure cancel and rapid taps do not create duplicate sheets',
    (tester) async {
      await open(tester, accept: false);
      expect(find.text(csvExportPreviewNotice), findsOneWidget);
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(key('sheet'), findsNothing);
      final context = tester.element(dataKey('screen'));
      showCsvExportPreviewSheet(context);
      showCsvExportPreviewSheet(context);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(key('sheet'), findsOneWidget);
    },
  );
  testWidgets('period choices use fixed sample dates and one selected pill', (
    tester,
  ) async {
    await open(tester);
    for (final i in [0, 2, 3, 1]) {
      await tester.tap(key('period_$i'));
      await tester.pumpAndSettle();
      for (var j = 0; j < 4; j++) {
        expect(
          tester.widget<Semantics>(key('period_$j')).properties.selected,
          j == i,
        );
      }
      expect(find.text('기록 214개 · 7마리'), findsOneWidget);
    }
    expect(find.text('2026.07.21'), findsOneWidget);
  });
  testWidgets(
    'date pickers constrain start and end and cancellation preserves dates',
    (tester) async {
      await open(tester);
      await tester.tap(key('start'));
      await tester.pumpAndSettle();
      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(picker.lastDate, DateTime(2026, 10, 20));
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(find.text('2026.07.21'), findsOneWidget);
      await tester.tap(key('end'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
            .firstDate,
        DateTime(2026, 7, 21),
      );
      await tester.tap(find.text('21').last);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('2026.10.21'), findsOneWidget);
      expect(
        tester.widget<Semantics>(key('period_3')).properties.selected,
        isTrue,
      );
    },
  );
  for (var i = 0; i < 3; i++) {
    testWidgets(
      'toggle $i has independent local state and stable sample count',
      (tester) async {
        await open(tester);
        const defaults = [true, true, false];
        for (var j = 0; j < 3; j++) {
          expect(enabled(tester, j), defaults[j]);
        }
        await tester.tap(key('toggle_$i'));
        await tester.pumpAndSettle();
        for (var j = 0; j < 3; j++) {
          expect(enabled(tester, j), j == i ? !defaults[j] : defaults[j]);
        }
        expect(find.text('기록 214개 · 7마리'), findsOneWidget);
        expect(tester.getSize(key('switch_$i')), const Size(40, 24));
      },
    );
  }
  testWidgets('accessible toggle actions and selected period labels', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    try {
      await open(tester);
      final node = tester.getSemantics(key('toggle_2'));
      expect(node.flagsCollection.isToggled, ui.Tristate.isFalse);
      tester.binding.performSemanticsAction(
        ui.SemanticsActionEvent(
          type: ui.SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pump();
      expect(enabled(tester, 2), isTrue);
      expect(tester.getSize(key('toggle_0')).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(key('period_0')).height, greaterThanOrEqualTo(44));
    } finally {
      h.dispose();
    }
  });
  testWidgets(
    'export produces notice only and no network or platform file calls',
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
          await tester.tap(key('export'));
          await tester.pumpAndSettle();
          expect(
            find.text('디자인 미리보기입니다. 실제 CSV 파일은 생성되지 않습니다.'),
            findsOneWidget,
          );
          expect(key('sheet'), findsOneWidget);
        },
        createHttpClient: (_) {
          requests++;
          throw StateError('Unexpected network');
        },
      );
      expect(requests, 0);
      expect(
        calls.where((x) => x.contains('file') || x.contains('share')),
        isEmpty,
      );
    },
  );
  for (final mode in ['close', 'scrim', 'back', 'drag']) {
    testWidgets(
      '$mode dismisses only sheet; reentry resets and keeps parent state',
      (tester) async {
        await open(tester);
        await tester.tap(key('period_2'));
        await tester.pump();
        await tester.tap(key('toggle_0'));
        await tester.pump();
        if (mode == 'close') {
          await tester.tap(key('close'));
        } else if (mode == 'scrim') {
          await tester.tapAt(const Offset(5, 150));
        } else if (mode == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.drag(key('grabber'), const Offset(0, 600));
        }
        await tester.pumpAndSettle();
        expect(key('sheet'), findsNothing);
        expect(dataKey('confirm'), findsOneWidget);
        await tester.tap(dataKey('csv'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('미리보기 열기'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(key('period_1')).properties.selected,
          isTrue,
        );
        expect(enabled(tester, 0), isTrue);
      },
    );
  }
  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size scale $scale scroll controls and no text clipping', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        for (final text in [
          'CSV로 내보내기',
          '선택한 기간의 모든 기록',
          '2026.07.21',
          '2026.10.20',
          '급여·탈피·체중',
          '청소·배변·메모',
        ]) {
          final f = find.descendant(
            of: key('sheet'),
            matching: find.text(text),
          );
          final p = tester.renderObject<RenderParagraph>(f);
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
        await tester.ensureVisible(key('export'));
        await tester.pumpAndSettle();
        await tester.tap(key('export'));
        await tester.pumpAndSettle();
        expect(find.text('디자인 미리보기입니다. 실제 CSV 파일은 생성되지 않습니다.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('CSV open and close preserve changed photo and delete UI state', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('close'));
    await tester.pumpAndSettle();
    await tester.tap(dataKey('keep'));
    await tester.pump();
    await tester.tap(dataKey('cancel'));
    await tester.pumpAndSettle();
    await tester.tap(dataKey('csv'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    await tester.tap(key('close'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Semantics>(dataKey('keep')).properties.toggled,
      isFalse,
    );
    expect(dataKey('confirm'), findsNothing);
    await tester.tap(dataKey('pdf'));
    await tester.pumpAndSettle();
    expect(find.text('PDF 리포트 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
  });
  testWidgets('independent preview host and normal app startup preserved', (
    tester,
  ) async {
    await open(tester, home: const CsvExportPreviewHost());
    expect(key('sheet'), findsOneWidget);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
