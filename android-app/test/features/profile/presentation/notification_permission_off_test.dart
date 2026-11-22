import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/notification_settings_screen.dart';
import 'package:tail_friends/notification_permission_off_preview.dart';

Finder key(String name) => find.byKey(ValueKey('notification_settings_$name'));
const notice = '기기 알림 설정 연결은 아직 준비 중입니다. 실제 권한은 변경되지 않았습니다.';
const defaults = {
  'feeding': true,
  'shedding': true,
  'weight': false,
  'growth': true,
  'events': false,
};
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const NotificationSettingsScreen.permissionOffPreview(),
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

bool value(WidgetTester tester, String name) =>
    tester.widget<Semantics>(key('toggle_$name')).properties.toggled!;
void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets('09-1a banner geometry and unchanged grouped layout', (
    tester,
  ) async {
    await open(tester);
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(
      tester.getRect(key('permission_banner')),
      const Rect.fromLTWH(24, 122, 342, 145),
    );
    expect(
      tester.getRect(key('care_group')),
      const Rect.fromLTWH(24, 323, 342, 235),
    );
    expect(
      tester.getRect(key('news_group')),
      const Rect.fromLTWH(24, 612, 342, 107),
    );
    expect(
      tester.getRect(key('quiet_group')),
      const Rect.fromLTWH(24, 773, 342, 63),
    );
    expect(tester.getSize(key('permission_button_visual')).height, 33);
    expect(
      tester.getSize(key('permission_settings')).height,
      greaterThanOrEqualTo(44),
    );
    expect(find.text('알림이 꺼져 있어요'), findsOneWidget);
    expect(find.text('기기 설정에서 알림을 켜야 급여일과 탈피 예정일을 알려드릴 수 있어요'), findsOneWidget);
  });
  testWidgets('muted original switch assets and preview defaults', (
    tester,
  ) async {
    await open(tester);
    for (final e in defaults.entries) {
      expect(value(tester, e.key), e.value);
      final image = tester.widget<Image>(key('switch_${e.key}'));
      expect(
        (image.image as AssetImage).assetName,
        e.value
            ? 'assets/images/notification_permission_switch_on.png'
            : 'assets/images/notification_time_switch_off.png',
      );
      expect(tester.getSize(key('switch_${e.key}')), const Size(40, 24));
    }
  });
  for (final name in defaults.keys) {
    testWidgets('$name is local only and does not hide permission banner', (
      tester,
    ) async {
      await open(tester);
      await tester.ensureVisible(key('toggle_$name'));
      await tester.tap(key('toggle_$name'));
      await tester.pumpAndSettle();
      expect(value(tester, name), !defaults[name]!);
      expect(key('permission_banner'), findsOneWidget);
    });
  }
  testWidgets(
    'settings button feedback and accessible 44px target without network',
    (tester) async {
      var calls = 0;
      final semantics = tester.ensureSemantics();
      try {
        await HttpOverrides.runZoned(
          () async {
            await open(tester);
            final node = tester.getSemantics(
              find.bySemanticsLabel('기기 설정으로 가기'),
            );
            expect(
              node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
              isTrue,
            );
            tester.binding.performSemanticsAction(
              ui.SemanticsActionEvent(
                type: ui.SemanticsAction.tap,
                viewId: tester.view.viewId,
                nodeId: node.id,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text(notice), findsOneWidget);
            expect(key('screen'), findsOneWidget);
            expect(value(tester, 'feeding'), isTrue);
            await tester.tap(key('permission_settings'));
            await tester.pumpAndSettle();
            expect(find.text(notice), findsOneWidget);
          },
          createHttpClient: (_) {
            calls++;
            throw StateError('Unexpected network');
          },
        );
        expect(calls, 0);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'existing time picker confirm cancel and banner preserve local values',
    (tester) async {
      await open(tester);
      await tester.tap(key('time_tap'));
      await tester.pumpAndSettle();
      expect(find.text('급여 알림을 받을 시간'), findsOneWidget);
      final hour = find.byKey(const ValueKey('notification_time_hour'));
      final semantics = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(hour);
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: ui.SemanticsAction.increase,
            viewId: tester.view.viewId,
            nodeId: node.id,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('notification_time_confirm')),
        );
        await tester.pumpAndSettle();
        expect(find.text('오후 9:00'), findsOneWidget);
        await tester.tap(key('time_tap'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('notification_time_close')));
        await tester.pumpAndSettle();
        expect(find.text('오후 9:00'), findsOneWidget);
        expect(key('permission_banner'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );
  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size scale $scale banner and last row remain accessible', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final header = tester.getRect(key('header'));
        await tester.tap(key('permission_settings'));
        await tester.pumpAndSettle();
        expect(find.text(notice), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        for (final text in [
          '알림이 꺼져 있어요',
          '기기 설정으로 가기',
          '기기 설정에서 알림을 켜야 급여일과 탈피 예정일을 알려드릴 수 있어요',
        ]) {
          final p = tester.renderObject<RenderParagraph>(find.text(text));
          expect(p.didExceedMaxLines, isFalse);
          // Wrapped trailing spaces can extend beyond layout width without ink.
          for (var i = 0; i < text.length; i++) {
            if (text[i].trim().isEmpty) continue;
            for (final box in p.getBoxesForSelection(
              TextSelection(baseOffset: i, extentOffset: i + 1),
            )) {
              expect(box.right, lessThanOrEqualTo(p.size.width + .1));
            }
          }
        }
        await tester.ensureVisible(key('quiet_tap'));
        await tester.pumpAndSettle();
        expect(key('quiet_tap').hitTestable(), findsOneWidget);
        await tester.tap(key('quiet_tap'));
        await tester.pumpAndSettle();
        expect(find.text('방해 금지 시간 변경 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
        expect(tester.getRect(key('header')), header);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'preview disclaimer before permission example and safe header back',
    (tester) async {
      await open(tester, home: const NotificationPermissionOffPreviewHost());
      expect(find.text(notificationPermissionOffPreviewNotice), findsOneWidget);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(key('permission_banner'), findsOneWidget);
      await tester.tap(key('back'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(key('permission_banner'), findsNothing);
    },
  );
  testWidgets('system root back returns to login', (tester) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
  testWidgets('original 09-1 preview has no new banner or asset changes', (
    tester,
  ) async {
    await open(tester, home: const NotificationSettingsScreen.preview());
    expect(key('permission_banner'), findsNothing);
    expect(
      tester.getRect(key('care_group')),
      const Rect.fromLTWH(24, 158, 342, 235),
    );
    expect(
      (tester.widget<Image>(key('switch_feeding')).image as AssetImage)
          .assetName,
      'assets/images/notification_time_switch_on.png',
    );
    expect(
      (tester.widget<Image>(key('switch_growth')).image as AssetImage)
          .assetName,
      'assets/images/notification_settings_switch_on.png',
    );
  });
}
