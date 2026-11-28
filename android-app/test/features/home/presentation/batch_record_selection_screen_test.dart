import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/batch_record_selection_preview.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/batch_record_selection_screen.dart';
import 'package:tail_friends/main.dart';

Finder key(String name) => find.byKey(ValueKey('batch_$name'));
const selectable = ['leo', 'ukki', 'haru', 'calcium', 'uvb'];
const examples = [
  ('leo', '레오', '크레스티드 게코 · 귀뚜라미 4마리'),
  ('ukki', '욱이', '레오파드 게코 · 귀뚜라미 5마리'),
  ('haru', '하루', '펫테일 게코 · 밀웜 3마리'),
  ('calcium', '칼슘 더스팅', '욱이 · 하루 · 매주 월·목'),
  ('uvb', 'UVB 램프 점검', '치토 · 180일마다'),
  ('chito', '치토', '최근 30일 체중 12% 감소'),
  ('sera', '세라', '급여 · 냉동 마우스 1마리'),
];
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 942),
  double scale = 1,
  Widget home = const BatchRecordSelectionScreen.preview(),
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

bool? checked(WidgetTester tester, String id) =>
    tester.widget<Semantics>(key('semantics_$id')).properties.checked;
String count(WidgetTester tester) =>
    tester.widget<Text>(key('selected_count')).data!;
Future<void> toggle(
  WidgetTester tester,
  String id, {
  bool checkbox = false,
}) async {
  await tester.ensureVisible(key('row_$id'));
  await tester.pumpAndSettle();
  await tester.tap(key('${checkbox ? 'checkbox' : 'row'}_$id'));
  await tester.pumpAndSettle();
}

Future<void> accept(WidgetTester tester) async {
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
}

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showBatchRecordSelectionPreview(context),
        child: const Text('열기'),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets('Figma geometry, seven rows and original local assets', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('10월 20일 화요일'), findsOneWidget);
    expect(find.text('오늘 할 일'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    for (final (id, title, n, rect) in [
      ('overdue', '지난 급여', '1', const Rect.fromLTWH(24, 150, 342, 69)),
      ('feeding', '오늘 급여', '2', const Rect.fromLTWH(24, 274, 342, 133)),
      ('schedule', '오늘 일정', '2', const Rect.fromLTWH(24, 462, 342, 133)),
      ('alert', '건강 경고', '1', const Rect.fromLTWH(24, 650, 342, 70)),
      ('done', '완료', '1', const Rect.fromLTWH(24, 775, 342, 70)),
    ]) {
      expect(tester.widget<Text>(key('section_$id')).data, title);
      expect(tester.widget<Text>(key('count_$id')).data, n);
      expect(tester.getRect(key('group_$id')), rect);
      final glass = tester.widget<AppGlassSurface>(key('group_$id'));
      expect(glass.blur, 18);
      expect(glass.gradient, AppColors.glassSoftGradient);
    }
    expect(tester.getRect(key('bar')), const Rect.fromLTWH(24, 869, 342, 49));
    for (final (id, name, detail) in examples) {
      expect(key('row_$id'), findsOneWidget);
      expect(find.text(name), findsOneWidget);
      expect(find.text(detail), findsOneWidget);
      expect(tester.getSize(key('row_$id')).height, greaterThanOrEqualTo(44));
    }
    for (final id in selectable) {
      expect(key('avatar_$id'), findsNothing);
      expect(tester.getSize(key('checkbox_$id')), const Size(20, 20));
    }
    expect(tester.getSize(key('avatar_chito')), const Size(36, 36));
    expect(tester.getSize(key('avatar_sera')), const Size(36, 36));
    expect(tester.widget<Opacity>(key('opacity_sera')).opacity, 0.55);
    final paths = tester
        .widgetList<SvgPicture>(find.byType(SvgPicture))
        .map((p) => (p.bytesLoader as SvgAssetLoader).assetName)
        .toSet();
    expect(paths, {
      'assets/icons/batch_record_checked.svg',
      'assets/icons/batch_record_unchecked.svg',
    });
    for (final path in paths) {
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
    }
    expect(
      (await rootBundle.load(
        'assets/images/batch_record_selection_background.png',
      )).lengthInBytes,
      greaterThan(0),
    );
    expect(find.byType(AppBottomNavigation), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'three feed selections and two unchecked schedule options initially',
    (tester) async {
      await open(tester);
      expect(count(tester), '3마리 선택');
      for (final id in selectable) {
        expect(checked(tester, id), ['leo', 'ukki', 'haru'].contains(id));
        final asset = tester.widget<SvgPicture>(key('checkbox_$id'));
        expect(
          (asset.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/batch_record_${checked(tester, id)! ? 'checked' : 'unchecked'}.svg',
        );
      }
      expect(checked(tester, 'chito'), isNull);
      expect(checked(tester, 'sera'), isNull);
    },
  );

  testWidgets(
    'checkbox and entire row toggle exactly once with correct units',
    (tester) async {
      await open(tester);
      await toggle(tester, 'leo', checkbox: true);
      expect(checked(tester, 'leo'), isFalse);
      expect(count(tester), '2마리 선택');
      await toggle(tester, 'leo');
      expect(checked(tester, 'leo'), isTrue);
      expect(count(tester), '3마리 선택');
      await toggle(tester, 'calcium', checkbox: true);
      expect(count(tester), '4개 선택');
      await toggle(tester, 'uvb');
      expect(count(tester), '5개 선택');
      await toggle(tester, 'calcium');
      await toggle(tester, 'uvb');
      expect(count(tester), '3마리 선택');
      final checkbox = tester.getRect(key('checkbox_leo'));
      await tester.ensureVisible(key('row_leo'));
      await tester.pumpAndSettle();
      final center = tester.getCenter(key('checkbox_leo'));
      await tester.tapAt(center + const Offset(0, 16));
      await tester.pumpAndSettle();
      expect(checkbox.size, const Size(20, 20));
      expect(checked(tester, 'leo'), isFalse);
    },
  );

  testWidgets(
    'zero selections disable both actions; all five can be selected',
    (tester) async {
      await open(tester);
      for (final id in ['leo', 'ukki', 'haru']) {
        await toggle(tester, id);
      }
      expect(count(tester), '0개 선택');
      for (final id in ['feed', 'clean']) {
        expect(tester.widget<InkWell>(key('action_$id')).onTap, isNull);
        await tester.tap(key('action_$id'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
      }
      for (final id in selectable) {
        await toggle(tester, id);
      }
      expect(count(tester), '5개 선택');
      for (final id in selectable) {
        expect(checked(tester, id), isTrue);
      }
      expect(tester.widget<InkWell>(key('action_feed')).onTap, isNotNull);
    },
  );

  testWidgets(
    'schedule-only selection uses items, nonselectable rows leave count unchanged',
    (tester) async {
      await open(tester);
      for (final id in ['leo', 'ukki', 'haru']) {
        await toggle(tester, id);
      }
      await toggle(tester, 'uvb');
      expect(count(tester), '1개 선택');
      for (final id in ['chito', 'sera']) {
        await toggle(tester, id);
        expect(count(tester), '1개 선택');
        expect(checked(tester, id), isNull);
      }
      expect(tester.widget<Text>(key('count_done')).data, '1');
    },
  );

  testWidgets(
    'batch actions only notify and preserve selections and fixtures',
    (tester) async {
      await open(tester);
      await toggle(tester, 'calcium');
      for (final (id, message) in [
        ('feed', '일괄 급여 기록 기능은 아직 연결되지 않았습니다.'),
        ('clean', '일괄 청소 기록 기능은 아직 연결되지 않았습니다.'),
      ]) {
        await tester.tap(key('action_$id'));
        await tester.tap(key('action_$id'));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(count(tester), '4개 선택');
        expect(checked(tester, 'calcium'), isTrue);
        expect(tester.widget<Text>(key('count_done')).data, '1');
      }
    },
  );

  testWidgets('status pills preserve original colors and copy', (tester) async {
    await open(tester);
    for (final (id, text, bg, ink) in [
      ('leo', '2일 지남', const Color(0xFFFBE3DF), const Color(0xFFB23B30)),
      ('ukki', '오늘 급여', const Color(0xFFFBEBD3), const Color(0xFF96570C)),
      ('haru', '오늘 급여', const Color(0xFFFBEBD3), const Color(0xFF96570C)),
      ('chito', '확인 필요', const Color(0xFFFBE3DF), const Color(0xFFB23B30)),
    ]) {
      final pill = tester.widget<Container>(key('status_$id'));
      expect((pill.decoration as BoxDecoration).color, bg);
      final label = tester.widget<Text>(
        find.descendant(of: key('status_$id'), matching: find.byType(Text)),
      );
      expect(label.data, text);
      expect(label.style!.color, ink);
    }
  });

  testWidgets('checked semantics, TalkBack toggle and live count', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    final selected = tester
        .getSemantics(key('semantics_leo'))
        .getSemanticsData();
    expect(selected.flagsCollection.isChecked, ui.CheckedState.isTrue);
    final node = tester.getSemantics(key('semantics_calcium'));
    expect(
      node.getSemanticsData().flagsCollection.isChecked,
      ui.CheckedState.isFalse,
    );
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, ui.SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(count(tester), '4개 선택');
    expect(
      tester
          .getSemantics(key('semantics_calcium'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      ui.CheckedState.isTrue,
    );
    expect(
      tester
          .getSemantics(key('semantics_chito'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      ui.CheckedState.none,
    );
    handle.dispose();
  });

  for (final size in [
    const Size(390, 942),
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('scroll, fixed bar and accessible selection $size × $scale', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final bar = tester.getRect(key('bar'));
        if (size.width - 74 < 250 || scale * 14 > 18) {
          expect(
            tester.getCenter(key('selected_count')).dx,
            closeTo(bar.center.dx + 5, 0.01),
            reason:
                'Expanded count stays over the green center, away from pill corners',
          );
        }
        for (final (id, _, detail) in examples) {
          await tester.ensureVisible(key('row_$id'));
          await tester.pumpAndSettle();
          expect(key('row_$id').hitTestable(), findsOneWidget);
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(detail))
                .didExceedMaxLines,
            isFalse,
          );
        }
        expect(tester.getRect(key('bar')), bar);
        expect(
          tester.getRect(key('row_sera')).bottom,
          lessThanOrEqualTo(bar.top),
        );
        for (final id in ['feed', 'clean']) {
          expect(
            tester.getSize(key('action_$id')).width,
            greaterThanOrEqualTo(44),
          );
          expect(
            tester.getSize(key('action_$id')).height,
            greaterThanOrEqualTo(44),
          );
        }
        expect(tester.getSize(key('cancel')).height, greaterThanOrEqualTo(44));
        await toggle(tester, 'uvb', checkbox: true);
        expect(count(tester), '4개 선택');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'cancel discards selection, reopening restores defaults and back returns safely',
    (tester) async {
      await open(tester, home: const Entry());
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.text(batchRecordSelectionPreviewNotice), findsOneWidget);
      await accept(tester);
      await toggle(tester, 'uvb');
      expect(count(tester), '4개 선택');
      final cancel = tester.widget<InkWell>(key('cancel')).onTap!;
      cancel();
      cancel();
      await tester.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
      expect(key('screen'), findsNothing);
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await accept(tester);
      expect(count(tester), '3마리 선택');
      expect(checked(tester, 'uvb'), isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
    },
  );

  testWidgets(
    'duplicate entry, disclaimer cancellation and preview host reopening',
    (tester) async {
      await open(tester, home: const Entry());
      final start = tester
          .widget<TextButton>(find.widgetWithText(TextButton, '열기'))
          .onPressed!;
      start();
      start();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(key('screen'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await open(tester, home: const BatchRecordSelectionPreviewHost());
      await accept(tester);
      await tester.tap(key('cancel'));
      await tester.pumpAndSettle();
      expect(find.text('선택 미리보기 다시 열기'), findsOneWidget);
      await tester.tap(find.text('선택 미리보기 다시 열기'));
      await tester.pumpAndSettle();
      await accept(tester);
      expect(count(tester), '3마리 선택');
    },
  );

  testWidgets('direct preview back and normal app preserve LoginScreen', (
    tester,
  ) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(BatchRecordSelectionScreen), findsNothing);
  });
}
