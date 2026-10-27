import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/notifications/presentation/notification_screen.dart';
import 'package:tail_friends/main.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
const _titles = [
  '욱이 급여할 시간이에요',
  '치토 탈피 예정일이 다가와요',
  '레오 체중을 재 볼까요?',
  '욱이 캐릭터가 한 단계 자랐어요',
  '루비 급여 기록이 저장됐어요',
];
const _details = [
  '마지막 급여 후 4일이 지났어요',
  '습도를 평소보다 높여 주세요',
  '마지막 측정 후 7일 지났어요',
  '기록 30회 달성',
  '냉동 마우스 1마리',
];

Future<void> _open(
  WidgetTester tester, {
  Widget screen = const NotificationScreen.preview(),
  Size size = const Size(390, 844),
  double scale = 1,
  double topInset = 54,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: topInset, bottom: 24);
  tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 24);
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
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

void _expectRect(WidgetTester tester, Finder finder, Rect expected) {
  final rect = tester.getRect(finder);
  expect(rect.left, closeTo(expected.left, 1));
  expect(rect.top, closeTo(expected.top, 1));
  expect(rect.width, closeTo(expected.width, 1));
  expect(rect.height, closeTo(expected.height, 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('Debug 미리보기만 오늘 3건과 이번 주 2건의 시안 문구를 표시한다', (tester) async {
    await _open(tester);
    expect(find.text('알림'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('이번 주'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.text(_titles[i]), findsOneWidget);
      expect(find.text(_details[i]), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(_titles[i])).style!.fontFamily,
        'Jua',
      );
    }
    expect(find.text('오전 9:00'), findsOneWidget);
    expect(find.text('오전 8:30'), findsOneWidget);
    expect(find.text('오전 8:00'), findsOneWidget);
    expect(find.text('10월 18일'), findsOneWidget);
    expect(find.text('10월 17일'), findsOneWidget);
    expect(find.text('9:41'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 원본 헤더·그룹·아이콘·구분선 배치를 유지한다', (tester) async {
    await _open(tester);
    _expectRect(
      tester,
      _key('notification_header'),
      const Rect.fromLTWH(24, 58, 342, 44),
    );
    _expectRect(
      tester,
      _key('notification_group_today'),
      const Rect.fromLTWH(24, 154, 342, 201),
    );
    _expectRect(
      tester,
      _key('notification_group_week'),
      const Rect.fromLTWH(24, 405, 342, 137),
    );
    _expectRect(
      tester,
      _key('notification_badge_0'),
      const Rect.fromLTWH(41, 173, 34, 34),
    );
    _expectRect(
      tester,
      _key('notification_unread_0'),
      const Rect.fromLTWH(343, 173, 6, 6),
    );
    final back = find.descendant(
      of: _key('notification_back'),
      matching: find.byType(AppGlassSurface),
    );
    _expectRect(tester, back, const Rect.fromLTWH(24, 62, 36, 36));
    final pill = find.descendant(
      of: _key('notification_mark_all'),
      matching: find.byType(AppGlassSurface),
    );
    _expectRect(tester, pill, const Rect.fromLTWH(293, 63, 73, 34));
    expect(find.byType(Divider), findsNWidgets(3));
    expect(
      tester.widget<Image>(_key('notification_background')).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'asset',
        'assets/images/home_first_visit_background.png',
      ),
    );
    for (var i = 0; i < 5; i++) {
      final svg = find.descendant(
        of: _key('notification_badge_$i'),
        matching: find.byType(SvgPicture),
      );
      expect(svg, findsOneWidget);
      final rect = tester.getRect(svg);
      expect(rect.width, closeTo(16, 0.1));
      expect(rect.height, closeTo(16, 0.1));
    }
    final dot = tester.widget<SvgPicture>(_key('notification_unread_0'));
    expect(
      dot.colorFilter,
      const ColorFilter.mode(Color(0xFF2F6B57), BlendMode.srcIn),
    );
  });

  testWidgets('읽지 않은 두 알림을 접근성 상태로 구분하고 개별 읽음은 해당 항목만 갱신한다', (tester) async {
    await _open(tester);
    final before = tester.getSemantics(_key('notification_semantics_0'));
    expect(before.label, contains(_titles[0]));
    expect(before.label, contains(_details[0]));
    expect(before.label, contains('오전 9:00'));
    expect(before.value, '읽지 않음');
    expect(before.flagsCollection.isButton, isTrue);
    expect(tester.getSemantics(_key('notification_semantics_2')).value, '읽음');

    await tester.tap(_key('notification_item_0'));
    await tester.pump();
    expect(_key('notification_unread_0'), findsNothing);
    expect(_key('notification_unread_1'), findsOneWidget);
    expect(tester.getSemantics(_key('notification_semantics_0')).value, '읽음');
    expect(find.text(_titles[0]), findsOneWidget);
    expect(find.byType(NotificationScreen), findsOneWidget);
    // Read state is idempotent and does not navigate or remove the item.
    await tester.tap(_key('notification_item_0'));
    await tester.pump();
    expect(_key('notification_unread_1'), findsOneWidget);
    expect(find.text(_titles[0]), findsOneWidget);
  });

  testWidgets('모두 읽음은 표시된 알림을 즉시 읽음 처리하고 재실행을 비활성화한다', (tester) async {
    await _open(tester);
    await tester.tap(_key('notification_mark_all'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      expect(_key('notification_unread_$i'), findsNothing);
      expect(
        tester.getSemantics(_key('notification_semantics_$i')).value,
        '읽음',
      );
    }
    expect(tester.widget<InkWell>(_key('notification_mark_all')).onTap, isNull);
    expect(find.byType(NotificationScreen), findsOneWidget);
  });

  testWidgets('일반 실행은 예시 알림과 그룹 대신 빈 상태를 표시한다', (tester) async {
    await _open(tester, screen: const NotificationScreen());
    expect(find.text('아직 알림이 없어요'), findsOneWidget);
    expect(find.text('새로운 알림이 도착하면 여기에서 확인할 수 있어요'), findsOneWidget);
    for (final title in _titles) {
      expect(find.text(title), findsNothing);
    }
    expect(find.text('오늘'), findsNothing);
    expect(find.text('이번 주'), findsNothing);
    expect(tester.widget<InkWell>(_key('notification_mark_all')).onTap, isNull);
  });

  testWidgets('주요 버튼과 알림 행은 최소 44×44 터치 영역을 제공한다', (tester) async {
    await _open(tester);
    for (final name in [
      'notification_back',
      'notification_mark_all',
      for (var i = 0; i < 5; i++) 'notification_item_$i',
    ]) {
      final size = tester.getSize(_key(name));
      expect(size.width, greaterThanOrEqualTo(44), reason: name);
      expect(size.height, greaterThanOrEqualTo(44), reason: name);
    }
  });

  for (final (index, home) in [
    const HomeScreen.preview(),
    const HomeScreen.firstVisitPreview(),
    const HomeScreen(),
  ].indexed) {
    for (final systemBack in [false, true]) {
      testWidgets(
        '홈 진입 $index에서 알림 이동 후 ${systemBack ? '시스템' : '헤더'} 뒤로가기로 같은 홈에 복귀한다',
        (tester) async {
          await _open(tester, screen: home);
          final original = tester.element(find.byType(HomeScreen));
          await tester.tap(_key('home_notification_button'));
          await tester.pumpAndSettle();
          expect(find.byType(NotificationScreen), findsOneWidget);
          if (index == 2) {
            expect(find.text('아직 알림이 없어요'), findsOneWidget);
          } else {
            expect(find.text(_titles[0]), findsOneWidget);
          }
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(_key('notification_back'));
          }
          await tester.pumpAndSettle();
          expect(find.byType(NotificationScreen), findsNothing);
          expect(tester.element(find.byType(HomeScreen)), same(original));
          expect(
            tester
                .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
                .currentTab,
            AppTab.habitat,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('홈에서 다시 열면 로컬 읽음 변경을 저장된 데이터로 취급하지 않는다', (tester) async {
    await _open(tester, screen: const HomeScreen.preview());
    await tester.tap(_key('home_notification_button'));
    await tester.pumpAndSettle();
    await tester.tap(_key('notification_mark_all'));
    await tester.pump();
    expect(_key('notification_unread_0'), findsNothing);
    await tester.tap(_key('notification_back'));
    await tester.pumpAndSettle();
    await tester.tap(_key('home_notification_button'));
    await tester.pumpAndSettle();
    expect(_key('notification_unread_0'), findsOneWidget);
    expect(_key('notification_unread_1'), findsOneWidget);
  });

  testWidgets('기본 앱 시작은 로그인이고 Debug 알림 경로로만 예시 알림을 바로 확인한다', (tester) async {
    await _open(tester);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(NotificationScreen), findsNothing);
    Navigator.of(
      tester.element(find.byType(LoginScreen)),
    ).pushNamed('/notifications-preview');
    await tester.pumpAndSettle();
    expect(find.text(_titles[0]), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  for (final systemBack in [false, true]) {
    testWidgets(
      '단독 실행에서 ${systemBack ? '시스템' : '헤더'} 뒤로가기는 빈 화면 대신 로그인으로 돌아간다',
      (tester) async {
        await _open(tester);
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(_key('notification_back'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(NotificationScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  }

  testWidgets('상단 시스템 영역이 큰 기기에서도 헤더가 SafeArea 아래에 위치한다', (tester) async {
    await _open(tester, topInset: 72);
    expect(tester.getTopLeft(_key('notification_header')).dy, 76);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(390, 844), Size(360, 800), Size(320, 640)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale 배에서 목록·날짜를 잘라내지 않고 스크롤·읽음 처리를 지원한다', (
        tester,
      ) async {
        await _open(tester, size: size, scale: scale);
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 5; i++) {
          final item = _key('notification_item_$i');
          await tester.ensureVisible(item);
          await tester.pumpAndSettle();
          final rect = tester.getRect(item);
          expect(rect.left, greaterThanOrEqualTo(24));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
          expect(tester.widget<Text>(find.text(_titles[i])).maxLines, isNull);
          expect(tester.widget<Text>(find.text(_details[i])).maxLines, isNull);
          expect(tester.takeException(), isNull, reason: '$i');
        }
        await tester.tap(_key('notification_mark_all'));
        await tester.pump();
        expect(
          tester.getSemantics(_key('notification_semantics_0')).value,
          '읽음',
        );
        final header = tester.getRect(_key('notification_header'));
        expect(header.top, 58);
        expect(header.bottom, lessThan(size.height - 24));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('빈 상태도 320×640 글자 2배에서 내용과 뒤로가기 버튼이 잘리지 않는다', (tester) async {
    await _open(
      tester,
      screen: const NotificationScreen(),
      size: const Size(320, 640),
      scale: 2,
    );
    await tester.ensureVisible(_key('notification_empty'));
    expect(tester.takeException(), isNull);
    final semantics = tester.getSemantics(_key('notification_mark_all'));
    expect(semantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
  });
}
