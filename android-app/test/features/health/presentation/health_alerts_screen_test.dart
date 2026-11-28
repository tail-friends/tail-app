import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/health/presentation/health_alerts_screen.dart';
import 'package:tail_friends/health_alerts_preview.dart';
import 'package:tail_friends/main.dart';

Future<void> open(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const HealthAlertsScreen.preview(),
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

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets(
    'current and past fixture warnings render exact sample content and default tab',
    (t) async {
      await open(t);
      expect(find.text('건강 관리'), findsOneWidget);
      expect(find.text('치토 · 체중 12% 감소'), findsOneWidget);
      expect(find.text('최근 30일 468g → 412g'), findsOneWidget);
      expect(find.text('레오 · 습도 범위 밖'), findsOneWidget);
      expect(find.text('38% · 적정 60–80%'), findsOneWidget);
      expect(find.text('욱이 · 거식 3번 연속'), findsOneWidget);
      expect(find.text('9월 2일 · 해제'), findsOneWidget);
      expect(find.text('세라 · 묽은 변 2번 연속'), findsOneWidget);
      expect(find.text('8월 14일 · 해제'), findsOneWidget);
      expect(
        t
            .getSemantics(find.byKey(const ValueKey('health_tab_0')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        t.getSemantics(find.byKey(const ValueKey('health_history'))).label,
        isNot(contains('실제')),
      );
    },
  );
  testWidgets('buttons and unimplemented tabs only show notices', (t) async {
    final h = t.ensureSemantics();
    await open(t);
    await t.tap(find.text('사진 체크'));
    await t.pumpAndSettle();
    expect(find.text('이 화면은 아직 연결되지 않았습니다.'), findsOneWidget);
    await t.tap(find.text('확인').first);
    await t.pumpAndSettle();
    expect(find.textContaining('연결되지 않았습니다.'), findsOneWidget);
    await t.tap(find.text('진료 기록'));
    await t.pumpAndSettle();
    expect(find.text('진료 기록은 아직 연결되지 않았습니다.'), findsOneWidget);
    await t.tap(find.text('사육 가이드'));
    await t.pumpAndSettle();
    expect(find.text('사육 가이드는 아직 연결되지 않았습니다.'), findsOneWidget);
    h.dispose();
  });
  for (final s in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('responsive $s × $scale', (t) async {
        await open(t, size: s, scale: scale);
        expect(t.takeException(), isNull);
        await t.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
        await t.pumpAndSettle();
        expect(find.text('세라 · 묽은 변 2번 연속'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('preview notice and safe back preserve standard login route', (
    t,
  ) async {
    await open(t, home: const HealthAlertsPreviewHost());
    expect(find.text(healthAlertsNotice), findsOneWidget);
    await t.tap(find.text('미리보기 열기'));
    await t.pumpAndSettle();
    expect(find.text('건강 관리'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
  testWidgets('normal app remains on login', (t) async {
    await t.pumpWidget(const TailFriendsApp());
    await t.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
