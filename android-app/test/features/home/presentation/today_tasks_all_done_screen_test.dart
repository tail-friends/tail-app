import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/today_tasks_all_done_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/today_tasks_all_done_preview.dart';

Finder key(String name) => find.byKey(ValueKey('all_done_$name'));
const examples = [
  ('ukki', '욱이', '급여 · 귀뚜라미 5마리', '욱'),
  ('leo', '레오', '급여 · 귀뚜라미 4마리', '레'),
  ('haru', '하루', '칼슘 더스팅', '하'),
  ('chito', '치토', 'UVB 램프 점검', '치'),
];
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const TodayTasksAllDoneScreen.preview(),
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
        onPressed: () => showTodayTasksAllDonePreview(context),
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
    'original hero geometry, avatar overlap, list size and bottom navigation',
    (tester) async {
      await open(tester);
      expect(find.text('10월 20일 화요일'), findsOneWidget);
      expect(find.text('오늘 할 일'), findsOneWidget);
      expect(find.text('오늘은 다 챙겼어요'), findsOneWidget);
      expect(find.text('휴면 중인 토토는 목록에서 빠졌어요'), findsOneWidget);
      expect(
        tester.getRect(key('hero')),
        const Rect.fromLTWH(24, 111, 342, 160),
      );
      expect(
        tester.getRect(key('avatar_stack')),
        const Rect.fromLTWH(138, 171, 114, 36),
      );
      expect(
        tester.getRect(key('list')),
        const Rect.fromLTWH(24, 326, 342, 265),
      );
      expect(
        tester.getRect(key('navigation')),
        const Rect.fromLTWH(24, 766, 342, 54),
      );
      for (final (index, example) in examples.indexed) {
        final id = example.$1;
        final hero = key('avatar_hero_$id');
        expect(
          tester.getRect(hero),
          Rect.fromLTWH(138 + 26.0 * index, 171, 36, 36),
        );
        final avatar = tester.widget<Container>(hero);
        expect(
          (avatar.decoration as BoxDecoration).color,
          const Color(0xFF2F6B57),
        );
        expect(
          find.descendant(of: hero, matching: find.text(example.$4)),
          findsOneWidget,
        );
        if (index > 0) {
          final previous = key('avatar_hero_${examples[index - 1].$1}');
          expect(
            tester.getRect(previous).right - tester.getRect(hero).left,
            10,
          );
        }
      }
      final glass = tester.widget<AppGlassSurface>(key('list'));
      expect(glass.gradient, AppColors.glassSoftGradient);
      expect(glass.blur, 18);
      expect(glass.borderRadius, BorderRadius.circular(22));
      expect(glass.borderColor, Colors.white);
      expect(
        (await rootBundle.load(
          'assets/images/privacy_policy_background.png',
        )).lengthInBytes,
        greaterThan(0),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'four completed examples in order with original check and 60% opacity',
    (tester) async {
      await open(tester);
      expect(find.text('완료'), findsOneWidget);
      expect(tester.widget<Text>(key('count')).data, '4');
      for (final (index, (id, name, detail, letter)) in examples.indexed) {
        expect(find.text(name), findsOneWidget);
        expect(find.text(detail), findsOneWidget);
        expect(
          find.descendant(
            of: key('avatar_row_$id'),
            matching: find.text(letter),
          ),
          findsOneWidget,
        );
        expect(tester.getSize(key('avatar_row_$id')), const Size(36, 36));
        expect(tester.getSize(key('row_$id')).height, 64);
        expect(tester.widget<Opacity>(key('opacity_$id')).opacity, 0.6);
        final icon = tester.widget<SvgPicture>(key('check_$id'));
        expect(
          (icon.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/today_tasks_all_done_check.svg',
        );
        expect(tester.getSize(key('check_$id')), const Size(20, 20));
        if (index > 0) {
          expect(
            tester.getTopLeft(key('row_$id')).dy,
            greaterThan(
              tester.getTopLeft(key('row_${examples[index - 1].$1}')).dy,
            ),
          );
        }
      }
      expect(find.byType(Divider), findsNWidgets(3));
      expect(
        (await rootBundle.load(
          'assets/icons/today_tasks_all_done_check.svg',
        )).lengthInBytes,
        greaterThan(0),
      );
      final paths = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((p) => (p.bytesLoader as SvgAssetLoader).assetName)
          .toSet();
      expect(paths, {
        'assets/icons/today_tasks_all_done_check.svg',
        'assets/icons/home_first_visit_nav_home.svg',
        'assets/icons/home_first_visit_nav_record.svg',
        'assets/icons/home_first_visit_nav_pets.svg',
        'assets/icons/home_first_visit_nav_profile.svg',
      });
    },
  );

  testWidgets(
    'row actions only notify and leave the completed fixtures unchanged',
    (tester) async {
      await open(tester);
      for (final (id, name, detail, _) in examples) {
        await tester.tap(key('row_$id'));
        await tester.pumpAndSettle();
        expect(find.text('디자인 미리보기입니다. 실제 기록은 변경되지 않습니다.'), findsOneWidget);
        expect(find.text(name), findsOneWidget);
        expect(find.text(detail), findsOneWidget);
        expect(tester.widget<Opacity>(key('opacity_$id')).opacity, 0.6);
      }
      expect(tester.widget<Text>(key('count')).data, '4');
      expect(find.byType(Checkbox), findsNothing);
    },
  );

  testWidgets('multi select and tabs do not change data or navigate', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('multi'));
    await tester.tap(key('multi'));
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
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<Text>(key('count')).data, '4');
  });

  testWidgets('selected habitat and actionable preview-only semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    final tab = tester
        .getSemantics(
          find.byKey(
            const ValueKey('app_bottom_navigation_habitat_touch_target'),
          ),
        )
        .getSemanticsData();
    expect(tab.flagsCollection.isSelected, ui.Tristate.isTrue);
    final node = tester.getSemantics(
      find
          .ancestor(of: key('row_chito'), matching: find.byType(Semantics))
          .first,
    );
    expect(node.getSemanticsData().label, '치토, UVB 램프 점검, 완료 예시');
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, ui.SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.text('디자인 미리보기입니다. 실제 기록은 변경되지 않습니다.'), findsOneWidget);
    handle.dispose();
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('all content reachable and fixed nav $size × $scale', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final nav = tester.getRect(key('navigation'));
        expect(tester.getSize(key('multi')).height, greaterThanOrEqualTo(44));
        expect(tester.getRect(key('hero')).top, greaterThanOrEqualTo(54));
        for (final (id, name, detail, _) in examples) {
          await tester.ensureVisible(key('row_$id'));
          await tester.pumpAndSettle();
          expect(key('row_$id').hitTestable(), findsOneWidget);
          expect(
            tester.getSize(key('row_$id')).height,
            greaterThanOrEqualTo(44),
          );
          for (final copy in [name, detail]) {
            expect(
              tester
                  .renderObject<RenderParagraph>(find.text(copy))
                  .didExceedMaxLines,
              isFalse,
            );
          }
        }
        expect(tester.getRect(key('navigation')), nav);
        expect(
          tester.getRect(key('row_chito')).bottom,
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
      });
    }
  }

  testWidgets('disclaimer cancellation, duplicate entry and system back', (
    tester,
  ) async {
    await open(tester, home: const Entry());
    final start = tester
        .widget<TextButton>(find.widgetWithText(TextButton, '열기'))
        .onPressed!;
    start();
    start();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(todayTasksAllDonePreviewNotice), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsNothing);
    start();
    await tester.pumpAndSettle();
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Entry), findsOneWidget);
    expect(key('screen'), findsNothing);
  });

  testWidgets('Debug host and direct root back keep the login flow', (
    tester,
  ) async {
    await open(tester, home: const TodayTasksAllDonePreviewHost());
    expect(find.text(todayTasksAllDonePreviewNotice), findsOneWidget);
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

  testWidgets('normal application still opens LoginScreen', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TodayTasksAllDoneScreen), findsNothing);
  });
}
