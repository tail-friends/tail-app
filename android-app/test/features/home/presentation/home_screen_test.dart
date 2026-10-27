import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/main.dart';

void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(Widget child, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.mist,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('Figma Preview는 홈 화면의 핵심 요소와 기준 크기를 표시한다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(_host(const HomeScreen.preview()));

    expect(find.text('욱이의 하루'), findsOneWidget);
    expect(find.text('레오파드 게코 · 2살 3개월'), findsOneWidget);
    expect(find.text('배고파요'), findsOneWidget);
    expect(find.text('오늘 급여할 차례예요'), findsOneWidget);
    expect(find.text('52'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.byType(AppRecordRow), findsNWidgets(2));
    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(tester.widget<Text>(find.text('배고파요')).style?.fontFamily, 'Jua');
    expect(tester.widget<Text>(find.text('급여')).style?.fontFamily, 'Jua');
    expect(tester.widget<Text>(find.text('사육장')).style?.fontFamily, 'Jua');

    expect(
      tester.getSize(find.byKey(const ValueKey('home_background'))),
      const Size(390, 844),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home_hero_card'))),
      const Size(342, 214),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home_character_slot'))),
      const Size(92, 80),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home_feeding_cta'))),
      const Size(342, 59),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home_weight_card'))),
      const Size(167, 140),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home_shed_card'))),
      const Size(167, 140),
    );
  });

  testWidgets('일반 홈은 예시 수치 대신 첫 방문 빈 상태를 표시한다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(_host(HomeScreen(now: DateTime(2026, 10, 25))));

    expect(find.text('10월 25일 일요일'), findsOneWidget);
    expect(find.text('반가워요, 어서 오세요'), findsOneWidget);
    expect(find.text('아직 함께하는 친구가 없어요'), findsOneWidget);
    expect(find.text('첫 친구 등록하기'), findsOneWidget);
    expect(find.text('민준'), findsNothing);
    expect(find.text('욱이'), findsNothing);
    expect(find.text('52'), findsNothing);
    expect(find.text('12'), findsNothing);
    expect(find.byType(AppRecordRow), findsNothing);
  });

  testWidgets('미구현 버튼은 화면을 이동하지 않고 준비 중 안내를 표시한다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(_host(const HomeScreen.preview()));

    for (final key in const [
      'home_feeding_cta',
      'home_weight_card',
      'home_shed_card',
      'home_all_records_button',
      'app_bottom_navigation_records_touch_target',
    ]) {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      expect(find.text('기능은 준비 중입니다.'), findsOneWidget, reason: key);
      expect(find.byType(HomeScreen), findsOneWidget);
    }
  });

  testWidgets('주요 버튼과 하단 탭은 44px 이상 터치 영역을 제공한다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(_host(const HomeScreen.preview()));

    for (final key in const [
      'home_notification_button',
      'home_feeding_cta',
      'home_weight_card',
      'home_shed_card',
      'home_all_records_button',
    ]) {
      final target = find.byKey(ValueKey(key));
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(44), reason: key);
      expect(size.height, greaterThanOrEqualTo(44), reason: key);
    }

    for (final tab in AppTab.values) {
      final size = tester.getSize(
        find.byKey(ValueKey('app_bottom_navigation_${tab.name}_touch_target')),
      );
      expect(size.width, greaterThanOrEqualTo(44), reason: tab.name);
      expect(size.height, greaterThanOrEqualTo(44), reason: tab.name);
    }

    final habitat = tester.getSemantics(
      find.byKey(const ValueKey('app_bottom_navigation_habitat_touch_target')),
    );
    expect(habitat.flagsCollection.isSelected, ui.Tristate.isTrue);
  });

  testWidgets('Debug Preview 경로는 홈을 표시하지만 기본 시작은 로그인을 유지한다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(const TailFriendsApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    final context = tester.element(find.byType(LoginScreen));
    Navigator.of(context).pushNamed('/home-preview');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('욱이의 하루'), findsOneWidget);
  });

  testWidgets('작은 Android 화면에서 최근 기록까지 스크롤하고 하단 탭을 유지한다', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(360, 800), Size(320, 640)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_host(const HomeScreen.preview()));

      final recent = find.byKey(const ValueKey('home_recent_card'));
      await tester.ensureVisible(recent);
      await tester.pump();

      expect(recent, findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('텍스트를 150%와 200%로 확대해도 가로 overflow가 발생하지 않는다', (tester) async {
    _setViewSize(tester, const Size(320, 640));

    for (final textScale in const [1.5, 2.0]) {
      await tester.pumpWidget(
        _host(const HomeScreen.preview(), textScale: textScale),
      );

      for (final key in const [
        'home_header',
        'home_hero_card',
        'home_feeding_cta',
        'home_metrics',
        'home_recent_card',
        'home_bottom_navigation',
      ]) {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.pump();
        expect(target, findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$textScale $key');
      }
    }
  });
}
