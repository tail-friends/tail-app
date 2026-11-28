import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/batch_feeding_confirmation_screen.dart';
import 'package:tail_friends/batch_feeding_confirmation_preview.dart';
import 'package:tail_friends/main.dart';

Finder k(String s) => find.byKey(ValueKey('batch_feed_$s'));
Future<void> open(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const BatchFeedingConfirmationScreen.preview(),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.view.padding = const FakeViewPadding(top: 54, bottom: 24);
  t.view.viewPadding = const FakeViewPadding(top: 54, bottom: 24);
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetPadding);
  addTearDown(t.view.resetViewPadding);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await t.pumpAndSettle();
}

bool refused(WidgetTester t, String id) =>
    t.widget<Semantics>(k('refused_$id')).properties.toggled!;

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    body: TextButton(
      onPressed: () => showBatchFeedingConfirmationPreview(c),
      child: const Text('열기'),
    ),
  );
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets('Figma geometry and static fixtures', (t) async {
    await open(t);
    expect(t.getRect(k('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(t.getRect(k('card')), const Rect.fromLTWH(24, 152, 342, 326));
    expect(t.getRect(k('save')), const Rect.fromLTWH(24, 760, 342, 50));
    expect(find.text('3마리 급여 완료'), findsOneWidget);
    expect(find.text('먹이와 개수는 개체별 직전 기록으로 채웠어요'), findsOneWidget);
    for (final (id, name, letter, food, count) in [
      ('leo', '레오', '레', '귀뚜라미', '4마리'),
      ('ukki', '욱이', '욱', '귀뚜라미', '5마리'),
      ('haru', '하루', '하', '밀웜', '3마리'),
    ]) {
      expect(find.text(name), findsOneWidget);
      expect(
        find.descendant(of: k('row_$id'), matching: find.text(food)),
        findsOneWidget,
      );
      expect(find.text(count), findsOneWidget);
      expect(t.getSize(k('row_$id')).height, 106);
      expect(t.getSize(k('avatar_$id')), const Size(36, 36));
      expect(
        find.descendant(of: k('avatar_$id'), matching: find.text(letter)),
        findsOneWidget,
      );
      expect(t.getSize(k('switch_$id')).height, greaterThanOrEqualTo(44));
      expect(t.getSize(k('switch_image_$id')), const Size(40, 24));
    }
    expect(find.byType(Divider), findsNWidgets(2));
    for (final p in [
      'assets/images/data_photo_background.png',
      'assets/icons/terms_chevron_left.svg',
      'assets/images/batch_feeding_switch_on.png',
      'assets/images/batch_feeding_switch_off.png',
    ]) {
      expect((await rootBundle.load(p)).lengthInBytes, greaterThan(0));
    }
    expect(t.takeException(), isNull);
  });
  testWidgets('initial refusal and dimmed food pills', (t) async {
    await open(t);
    expect(refused(t, 'leo'), false);
    expect(refused(t, 'ukki'), false);
    expect(refused(t, 'haru'), true);
    expect(t.widget<Opacity>(k('pills_leo')).opacity, 1);
    expect(t.widget<Opacity>(k('pills_haru')).opacity, 0.4);
  });
  testWidgets(
    'switches independently change local state and retain example quantities',
    (t) async {
      await open(t);
      await t.tap(k('switch_leo'));
      await t.pumpAndSettle();
      expect(refused(t, 'leo'), true);
      expect(refused(t, 'ukki'), false);
      expect(refused(t, 'haru'), true);
      await t.tap(k('switch_haru'));
      await t.pumpAndSettle();
      expect(refused(t, 'haru'), false);
      expect(t.widget<Opacity>(k('pills_haru')).opacity, 1);
      await t.tap(k('switch_ukki'));
      await t.tap(k('switch_leo'));
      await t.pumpAndSettle();
      expect(refused(t, 'ukki'), true);
      expect(refused(t, 'leo'), false);
      for (final v in ['4마리', '5마리', '3마리']) {
        expect(find.text(v), findsOneWidget);
      }
    },
  );
  testWidgets('save only notifies; no success, undo or altered state', (
    t,
  ) async {
    await open(t);
    await t.tap(k('switch_leo'));
    await t.pumpAndSettle();
    await t.tap(k('save'));
    await t.tap(k('save'));
    await t.pumpAndSettle();
    expect(find.text('디자인 미리보기입니다. 실제 급여 기록은 저장되지 않습니다.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('3마리 급여를 기록했어요'), findsNothing);
    expect(find.textContaining('되돌리기'), findsNothing);
    expect(refused(t, 'leo'), true);
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(refused(t, 'leo'), true);
  });
  testWidgets('switch semantics and accessibility action', (t) async {
    final h = t.ensureSemantics();
    await open(t);
    final node = t.getSemantics(k('refused_leo'));
    expect(node.getSemanticsData().label, '레오 안 먹음');
    expect(
      node.getSemanticsData().flagsCollection.isToggled,
      ui.Tristate.isFalse,
    );
    node.owner!.performAction(node.id, ui.SemanticsAction.tap);
    await t.pumpAndSettle();
    expect(refused(t, 'leo'), true);
    h.dispose();
  });
  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('scroll, fixed save and no overflow $size $scale', (t) async {
        await open(t, size: size, scale: scale);
        final save = t.getRect(k('save'));
        for (final id in ['leo', 'ukki', 'haru']) {
          await t.ensureVisible(k('switch_$id'));
          await t.pumpAndSettle();
          await t.tap(k('switch_$id'));
          await t.pumpAndSettle();
        }
        expect(t.getRect(k('save')), save);
        expect(t.getSize(k('back')), const Size(44, 44));
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'disclaimer, cancellation, duplicate entry and reset on reopening',
    (t) async {
      await open(t, home: const Entry());
      final start = t
          .widget<TextButton>(find.widgetWithText(TextButton, '열기'))
          .onPressed!;
      start();
      start();
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(batchFeedingConfirmationNotice), findsOneWidget);
      await t.tap(find.text('취소'));
      await t.pumpAndSettle();
      expect(k('screen'), findsNothing);
      start();
      await t.pumpAndSettle();
      await t.tap(find.text('미리보기 열기'));
      await t.pumpAndSettle();
      await t.tap(k('switch_leo'));
      await t.pumpAndSettle();
      await t.tap(k('back'));
      await t.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
      start();
      await t.pumpAndSettle();
      await t.tap(find.text('미리보기 열기'));
      await t.pumpAndSettle();
      expect(refused(t, 'leo'), false);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
    },
  );
  testWidgets('standalone host and normal app preserve login', (t) async {
    await open(t, home: const BatchFeedingConfirmationPreviewHost());
    await t.tap(find.text('미리보기 열기'));
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(const TailFriendsApp());
    await t.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(BatchFeedingConfirmationScreen), findsNothing);
  });
}
