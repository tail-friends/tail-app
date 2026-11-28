import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/today_tasks_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/today_tasks_preview.dart';

Finder key(String name) => find.byKey(ValueKey('today_tasks_$name'));
const rows = <(String, String, String, String)>[
  ('leo', '레오', '크레스티드 게코 · 귀뚜라미 4마리', '레'),
  ('ukki', '욱이', '레오파드 게코 · 귀뚜라미 5마리', '욱'),
  ('haru', '하루', '펫테일 게코 · 밀웜 3마리', '하'),
  ('calcium', '칼슘 더스팅', '욱이 · 하루 · 매주 월·목', '욱'),
  ('uvb', 'UVB 램프 점검', '치토 · 180일마다', '치'),
  ('chito', '치토', '최근 30일 체중 12% 감소', '치'),
  ('sera', '세라', '급여 · 냉동 마우스 1마리', '세'),
];
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 952),
  double scale = 1,
  Widget home = const TodayTasksScreen.preview(),
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

Future<void> visible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showTodayTasksPreview(context),
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

  testWidgets(
    'Figma 390x952 geometry, sections, seven fixtures and original assets',
    (tester) async {
      await open(tester);
      expect(find.text('오늘 할 일'), findsOneWidget);
      expect(find.text('10월 20일 화요일'), findsOneWidget);
      for (final (id, title, count, rect) in [
        ('overdue', '지난 급여', '1', const Rect.fromLTWH(24, 150, 342, 70)),
        ('feeding', '오늘 급여', '2', const Rect.fromLTWH(24, 275, 342, 135)),
        ('schedule', '오늘 일정', '2', const Rect.fromLTWH(24, 465, 342, 135)),
        ('alert', '건강 경고', '1', const Rect.fromLTWH(24, 655, 342, 70)),
        ('done', '완료', '1', const Rect.fromLTWH(24, 780, 342, 70)),
      ]) {
        expect(tester.widget<Text>(key('section_$id')).data, title);
        expect(tester.widget<Text>(key('count_$id')).data, count);
        expect(tester.getRect(key('group_$id')), rect);
        final glass = tester.widget<AppGlassSurface>(key('group_$id'));
        expect(glass.gradient, AppColors.glassSoftGradient);
        expect(glass.blur, 18);
        expect(glass.borderRadius, BorderRadius.circular(22));
      }
      for (final (id, title, description, avatar) in rows) {
        expect(key('row_$id'), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        expect(find.text(description), findsOneWidget);
        expect(
          find.descendant(of: key('avatar_$id'), matching: find.text(avatar)),
          findsOneWidget,
        );
        expect(tester.getSize(key('avatar_$id')), const Size(36, 36));
        expect(tester.getSize(key('row_$id')).height, greaterThanOrEqualTo(44));
      }
      expect(tester.widget<Opacity>(key('opacity_sera')).opacity, 0.55);
      expect(
        tester.getSize(key('multi_select')).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getRect(key('navigation')),
        const Rect.fromLTWH(24, 874, 342, 54),
      );
      for (final id in ['calcium', 'uvb', 'sera']) {
        final picture = tester.widget<SvgPicture>(key('icon_$id'));
        expect(
          (picture.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/today_tasks_${id == 'sera' ? 'done' : 'pending'}.svg',
        );
        expect(tester.getSize(key('icon_$id')), const Size(20, 20));
      }
      expect(
        (await rootBundle.load(
          'assets/images/today_tasks_background.png',
        )).lengthInBytes,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('status Pill copy and colors match Figma', (tester) async {
    await open(tester);
    for (final (id, text, color, ink) in [
      ('leo', '2일 지남', const Color(0xFFFBE3DF), const Color(0xFFB23B30)),
      ('ukki', '오늘 급여', const Color(0xFFFBEBD3), const Color(0xFF96570C)),
      ('haru', '오늘 급여', const Color(0xFFFBEBD3), const Color(0xFF96570C)),
      ('chito', '확인 필요', const Color(0xFFFBE3DF), const Color(0xFFB23B30)),
    ]) {
      final pill = tester.widget<Container>(key('status_$id'));
      expect((pill.decoration as BoxDecoration).color, color);
      final label = tester.widget<Text>(
        find.descendant(of: key('status_$id'), matching: find.byType(Text)),
      );
      expect(label.data, text);
      expect(label.style!.color, ink);
    }
  });

  testWidgets(
    'all rows and check icons only notify without changing fixtures',
    (tester) async {
      await open(tester);
      for (final (id, title, description, _) in rows) {
        await visible(tester, key('row_$id'));
        await tester.tap(key('row_$id'));
        await tester.pumpAndSettle();
        expect(find.text('디자인 미리보기입니다. 실제 기록은 변경되지 않습니다.'), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        expect(find.text(description), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
      expect(tester.widget<Opacity>(key('opacity_sera')).opacity, 0.55);
      expect(tester.widget<Text>(key('count_done')).data, '1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('multi select and four tabs never navigate or complete records', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('multi_select'));
    await tester.tap(key('multi_select'));
    await tester.pumpAndSettle();
    expect(find.text('일괄 선택 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
    for (final tab in AppTab.values) {
      await tester.tap(
        find.byKey(ValueKey('app_bottom_navigation_${tab.name}_touch_target')),
      );
      await tester.pumpAndSettle();
      expect(key('screen'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    }
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('selected habitat tab and row TalkBack actions', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    final selected = tester
        .getSemantics(
          find.byKey(
            const ValueKey('app_bottom_navigation_habitat_touch_target'),
          ),
        )
        .getSemanticsData();
    expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);
    final node = tester.getSemantics(
      find.ancestor(of: key('row_uvb'), matching: find.byType(Semantics)).first,
    );
    expect(node.getSemanticsData().label, contains('UVB 램프 점검'));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, ui.SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.text('디자인 미리보기입니다. 실제 기록은 변경되지 않습니다.'), findsOneWidget);
    handle.dispose();
  });

  for (final size in [
    const Size(390, 952),
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'all content reachable, no text clipping, fixed nav $size × $scale',
        (tester) async {
          await open(tester, size: size, scale: scale);
          final nav = tester.getRect(key('navigation'));
          for (final (id, title, description, _) in rows) {
            await visible(tester, key('row_$id'));
            expect(key('row_$id').hitTestable(), findsOneWidget);
            for (final copy in [title, description]) {
              final paragraph = tester.renderObject<RenderParagraph>(
                find.text(copy),
              );
              expect(paragraph.didExceedMaxLines, isFalse);
            }
          }
          expect(tester.getRect(key('navigation')), nav);
          expect(
            tester.getRect(key('row_sera')).bottom,
            lessThanOrEqualTo(nav.top),
          );
          for (final tab in AppTab.values) {
            final target = find.byKey(
              ValueKey('app_bottom_navigation_${tab.name}_touch_target'),
            );
            expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
            expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'preview disclaimer cancellation, duplicate entry and safe back',
    (tester) async {
      await open(tester, home: const Entry());
      final callback = tester
          .widget<TextButton>(find.widgetWithText(TextButton, '열기'))
          .onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(todayTasksPreviewNotice), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(key('screen'), findsNothing);
      callback();
      await tester.pumpAndSettle();
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(key('screen'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
      expect(key('screen'), findsNothing);
    },
  );

  testWidgets('standalone Debug host and direct back preserve login', (
    tester,
  ) async {
    await open(tester, home: const TodayTasksPreviewHost());
    expect(find.text(todayTasksPreviewNotice), findsOneWidget);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('normal app starts on login without preview fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TodayTasksScreen), findsNothing);
  });
}
