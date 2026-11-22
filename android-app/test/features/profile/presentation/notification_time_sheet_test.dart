import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/notification_time_preview_screen.dart';
import 'package:tail_friends/features/profile/presentation/notification_time_sheet.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/notification_time_preview.dart';

Finder key(String name) => find.byKey(ValueKey('notification_time_$name'));
Finder get timeRow => find.byKey(const ValueKey('notification_preview_time'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const NotificationTimePreviewScreen(),
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

Future<void> adjust(
  WidgetTester tester,
  String name,
  ui.SemanticsAction action,
) async {
  final node = tester.getSemantics(key(name));
  tester.binding.performSemanticsAction(
    ui.SemanticsActionEvent(
      type: action,
      viewId: tester.view.viewId,
      nodeId: node.id,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets('Figma baseline modal geometry and wheel pills', (tester) async {
    await open(tester);
    expect(key('sheet'), findsOneWidget);
    expect(tester.getRect(key('sheet')), const Rect.fromLTWH(0, 375, 390, 469));
    expect(tester.getSize(key('grabber')), const Size(32, 4));
    expect(tester.getSize(key('period_pill')), const Size(80, 41));
    expect(tester.getSize(key('hour_pill')), const Size(70, 41));
    expect(tester.getSize(key('minute_pill')), const Size(70, 41));
    expect(tester.getSize(key('close')), const Size(44, 44));
    expect(tester.getSize(key('confirm')).height, 48);
    expect(find.text('급여 알림을 받을 시간'), findsOneWidget);
  });

  testWidgets('accessible period hour minute changes commit local selection', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await open(tester);
      expect(tester.getSemantics(key('period')).value, '오후');
      expect(tester.getSemantics(key('hour')).value, '8');
      expect(tester.getSemantics(key('minute')).value, '00');
      await adjust(tester, 'period', ui.SemanticsAction.decrease);
      await adjust(tester, 'hour', ui.SemanticsAction.increase);
      await adjust(tester, 'minute', ui.SemanticsAction.increase);
      await tester.tap(key('confirm'));
      await tester.pumpAndSettle();
      expect(find.text('오전 9:05'), findsOneWidget);
      expect(find.text('UI 미리보기입니다. 실제 알림은 예약되거나 저장되지 않았습니다.'), findsOneWidget);
      await tester.tap(timeRow);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(key('period')).value, '오전');
      expect(tester.getSemantics(key('hour')).value, '9');
      expect(tester.getSemantics(key('minute')).value, '05');
    } finally {
      handle.dispose();
    }
  });

  testWidgets('wheel drag and tap select values', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await open(tester);
      await tester.drag(key('hour_list'), const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(key('hour')).value, '9');
      final minuteRect = tester.getRect(key('minute_list'));
      await tester.tapAt(minuteRect.center + const Offset(0, 39));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(key('minute')).value, '05');
    } finally {
      handle.dispose();
    }
  });

  for (final hour in [0, 12, 23]) {
    testWidgets('12-hour boundary round trip $hour', (tester) async {
      await open(
        tester,
        home: NotificationTimePreviewScreen(
          initialTime: TimeOfDay(hour: hour, minute: 55),
        ),
      );
      await tester.tap(key('confirm'));
      await tester.pumpAndSettle();
      final label = '${hour >= 12 ? '오후' : '오전'} ${(hour + 11) % 12 + 1}:55';
      expect(find.text(label), findsOneWidget);
    });
  }

  for (final method in ['close', 'outside', 'back', 'drag']) {
    testWidgets('$method dismiss preserves earlier time', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await open(tester);
        await adjust(tester, 'minute', ui.SemanticsAction.increase);
        switch (method) {
          case 'close':
            await tester.tap(key('close'));
          case 'outside':
            await tester.tapAt(const Offset(195, 200));
          case 'back':
            await tester.binding.handlePopRoute();
          case 'drag':
            await tester.drag(key('grabber'), const Offset(0, 600));
        }
        await tester.pumpAndSettle();
        expect(key('sheet'), findsNothing);
        expect(find.text('오후 8:00'), findsOneWidget);
        await tester.tap(timeRow);
        await tester.pumpAndSettle();
        expect(tester.getSemantics(key('minute')).value, '00');
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('modal blocks backdrop switches and duplicate opening', (
    tester,
  ) async {
    await open(tester);
    final old = tester
        .widget<Semantics>(
          find
              .ancestor(
                of: find.text('급여 알림'),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .toggled;
    await tester.tapAt(const Offset(320, 190));
    await tester.pumpAndSettle();
    expect(key('sheet'), findsNothing);
    final now = tester
        .widget<Semantics>(
          find
              .ancestor(
                of: find.text('급여 알림'),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .toggled;
    expect(now, old);
    final ink = tester.widget<InkWell>(timeRow);
    ink.onTap!();
    ink.onTap!();
    await tester.pumpAndSettle();
    expect(key('sheet'), findsOneWidget);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('scrollable sheet $size text $scale', (tester) async {
        await open(tester, size: size, scale: scale);
        await tester.ensureVisible(key('confirm'));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('confirm')).left, 25);
        expect(tester.getRect(key('confirm')).right, size.width - 25);
        await tester.tap(key('confirm'));
        await tester.pumpAndSettle();
        expect(key('sheet'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('preview disclaimer, cancellation and normal login', (
    tester,
  ) async {
    await open(tester, home: const NotificationTimePreviewHost());
    expect(find.text(notificationTimePreviewNotice), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('preview entry and two backs return safely to login', (
    tester,
  ) async {
    await open(tester, home: const NotificationTimePreviewHost());
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(key('sheet'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationTimePreviewScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('no HTTP and duplicate show helper returns null', (tester) async {
    var requests = 0;
    TimeOfDay? result;
    TimeOfDay? duplicate;
    await HttpOverrides.runZoned(
      () async {
        await open(
          tester,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final first = showNotificationTimePreviewSheet(context);
                  duplicate = await showNotificationTimePreviewSheet(context);
                  result = await first;
                },
                child: const Text('열기'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        expect(key('sheet'), findsOneWidget);
        await tester.tap(key('confirm'));
        await tester.pumpAndSettle();
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Unexpected HTTP');
      },
    );
    expect(duplicate, isNull);
    expect(result, const TimeOfDay(hour: 20, minute: 0));
    expect(requests, 0);
  });
}
