import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/batch_cleaning_preview.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/batch_cleaning_screen.dart';
import 'package:tail_friends/main.dart';

Finder key(String value) => find.byKey(ValueKey('cleaning_$value'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const BatchCleaningScreen.preview(),
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
    body: TextButton(
      onPressed: () => showBatchCleaningPreview(context),
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

  testWidgets(
    'Figma header, segmented, card, avatars and fixed save geometry',
    (tester) async {
      await open(tester);
      expect(find.text('3마리 청소 기록'), findsOneWidget);
      expect(
        tester.getRect(key('header')),
        const Rect.fromLTWH(24, 58, 342, 44),
      );
      expect(
        tester.getRect(key('type')),
        const Rect.fromLTWH(24, 120, 342, 45),
      );
      expect(
        tester.getRect(key('card')),
        const Rect.fromLTWH(24, 183, 342, 207),
      );
      expect(
        tester.getRect(key('save')),
        const Rect.fromLTWH(24, 760, 342, 50),
      );
      for (final id in ['leo', 'ukki', 'haru']) {
        expect(tester.getSize(key('avatar_$id')), const Size(36, 36));
      }
      expect(find.text('레오'), findsOneWidget);
      expect(find.text('욱이'), findsOneWidget);
      expect(find.text('하루'), findsOneWidget);
      expect(find.text('배변 상태'), findsNWidgets(3));
      expect(find.text('정상'), findsNWidgets(3));
      expect(find.text('묽음'), findsNWidgets(3));
      expect(find.text('없음'), findsNWidgets(3));
      expect(
        tester.widget<AppGlassSurface>(key('card')).borderRadius,
        BorderRadius.circular(22),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/batch_cleaning_background.png',
      );
      expect(find.text('9:41'), findsNothing);
    },
  );

  testWidgets(
    'type and all three independent choices expose selected semantics and touch targets',
    (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      expect(
        tester
            .getSemantics(key('type_0'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      await tester.tap(key('type_1'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(key('type_1'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(key('type_0'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isFalse,
      );
      for (final id in ['leo', 'ukki', 'haru']) {
        expect(
          tester
              .getSemantics(key('${id}_0'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
      }
      await tester.tap(key('leo_1'));
      await tester.pump();
      await tester.tap(key('ukki_2'));
      await tester.pump();
      expect(
        tester
            .getSemantics(key('leo_1'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(key('ukki_2'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(key('haru_0'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      final node = tester.getSemantics(key('haru_2'));
      node.owner!.performAction(node.id, ui.SemanticsAction.tap);
      await tester.pump();
      expect(
        tester
            .getSemantics(key('haru_2'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      for (final finder in [
        key('back'),
        key('type_0'),
        key('type_1'),
        for (final id in ['leo', 'ukki', 'haru'])
          for (var i = 0; i < 3; i++) key('${id}_$i'),
      ]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      handle.dispose();
    },
  );

  testWidgets(
    'save only notifies, preserves choices and does not claim success or Undo',
    (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await tester.tap(key('leo_1'));
      await tester.pump();
      await tester.tap(key('save'));
      await tester.tap(key('save'));
      await tester.pumpAndSettle();
      expect(find.text(batchCleaningSaveNotice), findsOneWidget);
      expect(
        tester
            .getSemantics(key('leo_1'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(find.textContaining('청소를 기록했어요'), findsNothing);
      expect(find.text('되돌리기 5'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets(
    'notice precedes preview, repeated entry is guarded and choices reset on reentry',
    (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, home: const Entry());
      await tester.tap(find.text('열기'));
      await tester.tap(find.text('열기'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(batchCleaningPreviewNotice), findsOneWidget);
      expect(find.byType(BatchCleaningScreen), findsNothing);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      await tester.tap(key('leo_2'));
      await tester.pump();
      await tester.tap(key('back'));
      await tester.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(key('leo_0'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Entry), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'preview cancel and standalone host safely return to original login',
    (tester) async {
      await open(tester, home: const BatchCleaningPreviewHost());
      expect(find.text(batchCleaningPreviewNotice), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('responsive $size scale $scale with scroll and fixed save', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        expect(tester.takeException(), isNull);
        final button = tester.getRect(key('save'));
        await tester.ensureVisible(key('haru_2'));
        await tester.pumpAndSettle();
        await tester.tap(key('haru_2'));
        await tester.pump();
        await tester.drag(key('scroll'), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('save')), button);
        expect(tester.takeException(), isNull);
        expect(button.right, lessThanOrEqualTo(size.width - 24));
        expect(button.bottom, lessThanOrEqualTo(size.height - 24));
      });
    }
  }
  testWidgets('normal app still starts on login', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(BatchCleaningScreen), findsNothing);
  });
}
