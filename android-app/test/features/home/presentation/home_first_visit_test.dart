import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/home_first_visit_preview.dart' as preview;
import 'package:tail_friends/main.dart';

const _featureTitles = ['기록하면 캐릭터가 반응해요', '돌봄 주기를 알려드려요', '성장을 한눈에'];
const _featureDetails = [
  '급여·탈피·체중을 남겨 보세요',
  '급여일과 탈피 예정일 알림',
  '체중 변화를 그래프로 확인',
];
Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _register => _key('home_first_visit_register_button');
Finder get _nav => _key('home_bottom_navigation');

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool designPreview = false,
  EdgeInsets safeArea = const EdgeInsets.only(top: 54, bottom: 24),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: safeArea,
          viewPadding: safeArea,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: designPreview
          ? const HomeScreen.firstVisitPreview()
          : HomeScreen(now: DateTime(2026, 10, 27)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('일반 첫 방문은 오늘 날짜와 중립적인 인사말만 표시한다', (tester) async {
    await _open(tester);
    expect(find.text('10월 27일 화요일'), findsOneWidget);
    expect(find.text('반가워요, 어서 오세요'), findsOneWidget);
    expect(find.textContaining('민준'), findsNothing);
    expect(find.textContaining('욱이'), findsNothing);
    expect(find.text('52'), findsNothing);
    expect(find.text('12'), findsNothing);
    expect(find.text('아직 함께하는 친구가 없어요'), findsOneWidget);
    expect(find.text('캐릭터 생성 기능은 준비 중이에요'), findsOneWidget);
    expect(find.text('사진 한 장이면 우리 아이 캐릭터가 만들어져요'), findsNothing);
    expect(find.byType(AppRecordRow), findsNothing);
    expect(_key('home_hero_card'), findsNothing);
    final slot = _key('home_first_visit_character_slot');
    expect(
      find.descendant(of: slot, matching: find.byType(Image)),
      findsNothing,
    );
    expect(
      find.descendant(of: slot, matching: find.byType(SvgPicture)),
      findsNothing,
    );
  });

  testWidgets('Debug 디자인 미리보기만 Figma 예시 이름·날짜·캐릭터 생성 시안 문구를 사용한다', (
    tester,
  ) async {
    await _open(tester, designPreview: true);
    expect(find.text('반가워요, 민준님'), findsOneWidget);
    expect(find.text('10월 20일 화요일'), findsOneWidget);
    expect(find.text('사진 한 장이면 우리 아이 캐릭터가 만들어져요'), findsOneWidget);
    expect(find.text('캐릭터 생성 기능은 준비 중이에요'), findsNothing);
    for (var i = 0; i < 3; i++) {
      expect(find.text(_featureTitles[i]), findsOneWidget);
      expect(find.text(_featureDetails[i]), findsOneWidget);
    }
  });

  testWidgets('390×844에서 원본 카드·빈 슬롯·버튼·아이콘의 배치와 크기를 유지한다', (tester) async {
    await _open(tester, designPreview: true);
    expect(
      tester.getRect(_key('home_first_visit_card')),
      const Rect.fromLTWH(24, 130, 342, 266),
    );
    expect(
      tester.getRect(_key('home_first_visit_character_slot')),
      const Rect.fromLTWH(151, 167, 88, 88),
    );
    expect(tester.getRect(_register), const Rect.fromLTWH(49, 323, 292, 48));
    expect(
      tester.getRect(_key('home_first_visit_features')),
      const Rect.fromLTWH(24, 414, 342, 174),
    );
    expect(tester.getRect(_nav), const Rect.fromLTWH(24, 766, 342, 54));
    expect(tester.getTopLeft(find.text('10월 20일 화요일')), const Offset(24, 54));
    expect(tester.getTopLeft(find.text('반가워요, 민준님')), const Offset(24, 68));
    final notification = _key('home_notification_button');
    expect(tester.getSize(notification), const Size(44, 44));
    expect(
      tester.getRect(
        find.descendant(
          of: notification,
          matching: find.byType(AppGlassSurface),
        ),
      ),
      const Rect.fromLTWH(330, 54, 36, 36),
    );
    for (final svg in find.byType(SvgPicture).evaluate()) {
      final finder = find.byWidget(svg.widget);
      // The shared bell uses FittedBox: measure its rendered transform as well.
      expect(
        tester.getBottomRight(finder) - tester.getTopLeft(finder),
        const Offset(16, 16),
      );
    }
    expect(tester.getSize(_key('home_background')), const Size(390, 844));
    final button = tester.widget<AppButton>(_register);
    expect(button.backgroundColor, const Color(0xFF2F6B57));
    expect(button.textStyle!.fontFamily, 'Jua');
    final nav = tester.widget<AppBottomNavigation>(_nav);
    expect(nav.iconAssets.length, 4);
    expect(nav.selectedLabelColor, const Color(0xFF2B2A26));
    expect(nav.unselectedLabelColor, const Color(0xFF6B675E));
    expect(nav.selectedBackgroundColor, Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets('등록 버튼은 기존 화면으로 이동하고 상단·시스템 뒤로가기로 복귀한다', (tester) async {
    await _open(tester);
    for (final systemBack in [false, true]) {
      await tester.tap(_register);
      await tester.pumpAndSettle();
      expect(find.byType(PetRegistrationScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('pet_registration_back_button'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PetRegistrationScreen), findsNothing);
      expect(find.text('반가워요, 어서 오세요'), findsOneWidget);
      expect(_register, findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('알림·미구현 탭은 준비 중 안내만 표시하고 사육장 선택을 유지한다', (tester) async {
    await _open(tester);
    for (final target in [
      _key('home_notification_button'),
      for (final tab in [AppTab.records, AppTab.pets, AppTab.profile])
        _key('app_bottom_navigation_${tab.name}_touch_target'),
    ]) {
      ScaffoldMessenger.of(
        tester.element(find.byType(HomeScreen)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('기능은 준비 중입니다.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<AppBottomNavigation>(_nav).currentTab,
        AppTab.habitat,
      );
    }
    for (final tab in AppTab.values) {
      final target = _key('app_bottom_navigation_${tab.name}_touch_target');
      expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      expect(
        tester.getSemantics(target).flagsCollection.isSelected,
        tab == AppTab.habitat ? ui.Tristate.isTrue : ui.Tristate.isFalse,
      );
    }
  });

  testWidgets('기본 앱 시작은 로그인이고 기존 홈 샘플은 첫 방문으로 대체하지 않는다', (tester) async {
    await _open(tester);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    Navigator.of(
      tester.element(find.byType(LoginScreen)),
    ).pushNamed('/home-preview');
    await tester.pumpAndSettle();
    expect(find.text('욱이의 하루'), findsOneWidget);
    expect(_register, findsNothing);
    expect(tester.widget<AppBottomNavigation>(_nav).iconAssets, isEmpty);
    expect(
      tester.widget<AppBottomNavigation>(_nav).unselectedLabelColor,
      AppColors.textTertiary,
    );
  });

  testWidgets('별도 Debug 진입점으로 첫 방문 시안을 실행할 수 있다', (tester) async {
    await _open(tester);
    preview.main();
    await tester.pumpAndSettle();
    expect(find.text('반가워요, 민준님'), findsOneWidget);
    expect(_register, findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(360, 800), Size(320, 640)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale배에서 등록 버튼·소개 카드에 접근하고 하단 탭을 고정한다', (
        tester,
      ) async {
        await _open(tester, size: size, scale: scale);
        final initialNav = tester.getRect(_nav);
        expect(tester.takeException(), isNull);
        final scroll = tester
            .state<ScrollableState>(
              find.descendant(
                of: _key('home_scroll_view'),
                matching: find.byType(Scrollable),
              ),
            )
            .position;
        scroll.jumpTo(scroll.maxScrollExtent);
        await tester.pumpAndSettle();
        for (final title in _featureTitles) {
          final rect = tester.getRect(find.text(title));
          expect(rect.left, greaterThanOrEqualTo(24));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
        }
        final last = tester.getRect(find.text(_featureDetails.last));
        expect(last.bottom, lessThanOrEqualTo(initialNav.top));
        expect(tester.getRect(_nav), initialNav);
        await tester.ensureVisible(_register);
        await tester.pumpAndSettle();
        expect(tester.getSize(_register).height, greaterThanOrEqualTo(44));
        await tester.tap(_register);
        await tester.pumpAndSettle();
        expect(find.byType(PetRegistrationScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.getRect(_nav), initialNav);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('큰 글자와 노치·하단 SafeArea에서도 소개 끝까지 스크롤한다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      scale: 2,
      safeArea: const EdgeInsets.fromLTRB(12, 60, 12, 34),
    );
    final nav = tester.getRect(_nav);
    expect(nav.left, 36);
    expect(nav.bottom, 606);
    final scroll = tester
        .state<ScrollableState>(
          find.descendant(
            of: _key('home_scroll_view'),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(scroll.maxScrollExtent, greaterThan(0));
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text(_featureDetails.last)).bottom,
      lessThan(nav.top),
    );
    expect(tester.getRect(_nav), nav);
    expect(tester.takeException(), isNull);
  });
}
