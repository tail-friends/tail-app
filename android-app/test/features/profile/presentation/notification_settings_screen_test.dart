import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/notification_settings_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/notification_settings_preview.dart';

Finder key(String name) => find.byKey(ValueKey('notification_settings_$name'));
Finder timeKey(String name) => find.byKey(ValueKey('notification_time_$name'));
const defaults = {
  'feeding': true,
  'shedding': true,
  'weight': false,
  'growth': true,
  'events': false,
};
const labels = {
  'feeding': '급여 알림',
  'shedding': '탈피 예정 알림',
  'weight': '체중 측정 알림',
  'growth': '캐릭터 성장 소식',
  'events': '이벤트·혜택',
};
const quietNotice = '방해 금지 시간 변경 기능은 아직 연결되지 않았습니다.';

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const NotificationSettingsScreen.preview(),
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
    tester.getSemantics(key('toggle_$name')).flagsCollection.isToggled ==
    ui.Tristate.isTrue;
Future<void> action(
  WidgetTester tester,
  Finder target,
  ui.SemanticsAction action,
) async {
  final node = tester.getSemantics(target);
  tester.binding.performSemanticsAction(
    ui.SemanticsActionEvent(
      type: action,
      viewId: tester.view.viewId,
      nodeId: node.id,
    ),
  );
  await tester.pumpAndSettle();
}

void fullText(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  expect(p.didExceedMaxLines, isFalse, reason: text);
  final bearing = (p.text.style?.letterSpacing ?? 0).abs() / 2 + .01;
  for (final word in RegExp(r'\S+').allMatches(text)) {
    for (final box in p.getBoxesForSelection(
      TextSelection(baseOffset: word.start, extentOffset: word.end),
    )) {
      expect(box.left, greaterThanOrEqualTo(-bearing), reason: text);
      expect(
        box.right,
        lessThanOrEqualTo(p.size.width + bearing),
        reason: text,
      );
      expect(box.bottom, lessThanOrEqualTo(p.size.height + .1), reason: text);
    }
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Figma geometry, headings and exact default assets', (
    tester,
  ) async {
    await open(tester);
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(
      tester.getRect(key('care_group')),
      const Rect.fromLTWH(24, 158, 342, 235),
    );
    expect(
      tester.getRect(key('news_group')),
      const Rect.fromLTWH(24, 447, 342, 107),
    );
    expect(
      tester.getRect(key('quiet_group')),
      const Rect.fromLTWH(24, 608, 342, 63),
    );
    for (final name in ['돌봄 알림', '소식', '방해 금지']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('오후 8:00'), findsOneWidget);
    expect(find.text('22:00 – 08:00'), findsOneWidget);
    expect(timeKey('sheet'), findsNothing);
    expect(find.text('권한 꺼짐'), findsNothing);
    for (final name in defaults.keys) {
      expect(tester.getSize(key('switch_$name')), const Size(40, 24));
      final asset =
          tester.widget<Image>(key('switch_$name')).image as AssetImage;
      final expected = defaults[name]!
          ? (name == 'feeding'
                ? 'notification_time_switch_on.png'
                : 'notification_settings_switch_on.png')
          : 'notification_time_switch_off.png';
      expect(asset.assetName, 'assets/images/$expected');
    }
    final glass = tester.widget<AppGlassSurface>(key('care_group'));
    expect(glass.gradient, AppColors.glassSoftGradient);
    expect(glass.borderRadius, BorderRadius.circular(22));
    expect(tester.widget<Text>(find.text('알림 설정')).style!.fontFamily, 'Jua');
  });

  for (final name in defaults.keys) {
    testWidgets('$name label and switch taps change only its local state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await open(tester);
        for (final other in defaults.keys) {
          expect(value(tester, other), defaults[other]);
        }
        final node = tester.getSemantics(key('toggle_$name'));
        expect(node.label, labels[name]);
        expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
        await tester.tap(find.text(labels[name]!));
        await tester.pumpAndSettle();
        expect(value(tester, name), !defaults[name]!);
        for (final other in defaults.keys.where((n) => n != name)) {
          expect(value(tester, other), defaults[other]);
        }
        await tester.tap(key('switch_$name'));
        await tester.pumpAndSettle();
        expect(value(tester, name), defaults[name]);
        expect(
          tester.getSize(key('toggle_$name')).height,
          greaterThanOrEqualTo(44),
        );
        expect(
          tester.getSize(key('toggle_$name')).width,
          greaterThanOrEqualTo(44),
        );
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('TalkBack tap action changes each toggle exactly once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await open(tester);
      for (final name in defaults.keys) {
        await action(tester, key('toggle_$name'), ui.SemanticsAction.tap);
        expect(value(tester, name), !defaults[name]!);
        expect(tester.getSemantics(key('toggle_$name')).label, labels[name]);
      }
      expect(
        tester.getSemantics(key('time_action')).flagsCollection.isButton,
        isTrue,
      );
      expect(
        tester.getSemantics(key('quiet_action')).flagsCollection.isButton,
        isTrue,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'existing 09-12 sheet confirms time and preserves toggle values',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await open(tester);
        await tester.tap(key('toggle_weight'));
        await tester.pumpAndSettle();
        await action(tester, key('time_action'), ui.SemanticsAction.tap);
        expect(timeKey('sheet'), findsOneWidget);
        await action(tester, timeKey('period'), ui.SemanticsAction.decrease);
        await action(tester, timeKey('hour'), ui.SemanticsAction.increase);
        await action(tester, timeKey('minute'), ui.SemanticsAction.increase);
        await tester.tap(timeKey('confirm'));
        await tester.pumpAndSettle();
        expect(find.text('오전 9:05'), findsOneWidget);
        expect(value(tester, 'weight'), isTrue);
        expect(tester.getSemantics(key('time_action')).value, '오전 9:05');
        await tester.tap(key('time_tap'));
        await tester.pumpAndSettle();
        expect(tester.getSemantics(timeKey('period')).value, '오전');
        expect(tester.getSemantics(timeKey('hour')).value, '9');
        expect(tester.getSemantics(timeKey('minute')).value, '05');
      } finally {
        handle.dispose();
      }
    },
  );

  for (final method in ['close', 'outside', 'back', 'drag']) {
    testWidgets('$method cancels changed time and keeps earlier selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await open(tester);
        await tester.tap(key('time_tap'));
        await tester.pumpAndSettle();
        await action(tester, timeKey('minute'), ui.SemanticsAction.increase);
        switch (method) {
          case 'close':
            await tester.tap(timeKey('close'));
          case 'outside':
            await tester.tapAt(const Offset(195, 200));
          case 'back':
            await tester.binding.handlePopRoute();
          case 'drag':
            await tester.drag(timeKey('grabber'), const Offset(0, 600));
        }
        await tester.pumpAndSettle();
        expect(timeKey('sheet'), findsNothing);
        expect(find.text('오후 8:00'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('rapid row taps open one modal', (tester) async {
    await open(tester);
    final row = tester.widget<InkWell>(key('time_tap'));
    row.onTap!();
    row.onTap!();
    await tester.pumpAndSettle();
    expect(timeKey('sheet'), findsOneWidget);
    await tester.tap(timeKey('close'));
    await tester.pumpAndSettle();
    expect(timeKey('sheet'), findsNothing);
    expect(key('screen'), findsOneWidget);
  });

  testWidgets('quiet hours unavailable notice replaces repeated messages', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('quiet_tap'));
    await tester.pumpAndSettle();
    expect(find.text(quietNotice), findsOneWidget);
    expect(find.text('22:00 – 08:00'), findsOneWidget);
    final row = tester.widget<InkWell>(key('quiet_tap'));
    row.onTap!();
    row.onTap!();
    await tester.pumpAndSettle();
    expect(find.text(quietNotice), findsOneWidget);
    expect(timeKey('sheet'), findsNothing);
    await tester.tap(key('back'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(quietNotice), findsNothing);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'all labels readable, scroll and time sheet $size text $scale',
        (tester) async {
          await open(tester, size: size, scale: scale);
          final header = tester.getRect(key('header'));
          for (final text in [
            '알림 설정',
            ...labels.values,
            '급여 주기에 맞춰 알려드려요',
            '예상일 3일 전',
            '매주 화요일',
            '오후 8:00',
            '방해 금지 시간',
            '이 시간에는 알림을 보내지 않아요',
            '22:00 – 08:00',
          ]) {
            fullText(tester, text);
          }
          await tester.ensureVisible(key('quiet_tap'));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(key('quiet_tap')).bottom,
            lessThanOrEqualTo(size.height - 24 + .1),
          );
          expect(tester.getRect(key('header')), header);
          expect(tester.getSize(key('back')), const Size(44, 44));
          await tester.ensureVisible(key('time_tap'));
          await tester.tap(key('time_tap'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(timeKey('confirm'));
          await tester.tap(timeKey('confirm'));
          await tester.pumpAndSettle();
          expect(timeKey('sheet'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final systemBack in [false, true]) {
    testWidgets(
      'disclaimer and ${systemBack ? 'system' : 'header'} back returns safely',
      (tester) async {
        await open(tester, home: const NotificationSettingsPreviewHost());
        expect(find.text(notificationSettingsPreviewNotice), findsOneWidget);
        expect(key('screen'), findsNothing);
        await tester.tap(find.text('미리보기 열기'));
        await tester.pumpAndSettle();
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  }

  testWidgets('cancel preserves login and normal app entry', (tester) async {
    await open(tester, home: const NotificationSettingsPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('fresh preview resets toggles and time, no HTTP requests', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var requests = 0;
    try {
      await HttpOverrides.runZoned(
        () async {
          await open(tester);
          for (final name in defaults.keys) {
            await tester.tap(key('toggle_$name'));
            await tester.pumpAndSettle();
          }
          await tester.tap(key('time_tap'));
          await tester.pumpAndSettle();
          await action(tester, timeKey('hour'), ui.SemanticsAction.increase);
          await tester.tap(timeKey('confirm'));
          await tester.pumpAndSettle();
          expect(find.text('오후 9:00'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await open(tester);
          for (final name in defaults.keys) {
            expect(value(tester, name), defaults[name]);
          }
          expect(find.text('오후 8:00'), findsOneWidget);
        },
        createHttpClient: (_) {
          requests++;
          throw StateError('Unexpected HTTP');
        },
      );
      expect(requests, 0);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('preview entry double invocation is guarded', (tester) async {
    await open(
      tester,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showNotificationSettingsPreview(context);
              showNotificationSettingsPreview(context);
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text(notificationSettingsPreviewNotice), findsOneWidget);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsOneWidget);
    await tester.tap(key('back'));
    await tester.pumpAndSettle();
    expect(find.text('열기'), findsOneWidget);
  });
}
