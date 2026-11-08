import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_list_empty_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_list_empty_preview.dart' as preview;

Finder _key(String key) => find.byKey(ValueKey('pet_list_empty_$key'));
Finder _tab(AppTab tab) =>
    find.byKey(ValueKey('app_bottom_navigation_${tab.name}_touch_target'));
Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey('pet_${key}_field')),
  matching: find.byType(TextFormField),
);

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetListEmptyScreen(),
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 24,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
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

bool _selected(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).flagsCollection.isSelected ==
    ui.Tristate.isTrue;
void _rect(WidgetTester tester, Finder finder, Rect expected) {
  final actual = tester.getRect(finder);
  expect(actual.left, closeTo(expected.left, .1));
  expect(actual.top, closeTo(expected.top, .1));
  expect(actual.width, closeTo(expected.width, .1));
  expect(actual.height, closeTo(expected.height, .1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('빈 상태 문구와 0마리를 Jua로 표시하고 가짜 데이터를 만들지 않는다', (tester) async {
    await _open(tester);
    for (final text in [
      '내 아이들',
      '등록순 · 0마리',
      '목록',
      '휠',
      '첫 개체를 등록해 보세요',
      '이름·종·급여 주기만 있으면 시작할 수 있어요',
      '개체 등록하기',
    ]) {
      expect(
        find.text(text),
        text == '내 아이들' ? findsNWidgets(2) : findsOneWidget,
      );
    }
    for (final text in ['등록순 · 0마리', '첫 개체를 등록해 보세요', '개체 등록하기']) {
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    expect(find.text('등록순 · 7마리'), findsNothing);
    expect(find.text('욱이'), findsNothing);
    expect(find.text('9:41'), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 빈 영역·원형 자리·등록 버튼·하단 탭의 Figma 크기와 위치를 유지한다', (
    tester,
  ) async {
    await _open(tester);
    _rect(tester, _key('header'), const Rect.fromLTWH(24, 58, 342, 44));
    _rect(tester, _key('add_surface'), const Rect.fromLTWH(330, 62, 36, 36));
    _rect(tester, _key('content'), const Rect.fromLTWH(24, 116, 342, 322));
    _rect(
      tester,
      _key('character_slot'),
      const Rect.fromLTWH(147, 226, 96, 96),
    );
    _rect(tester, _key('register'), const Rect.fromLTWH(95, 390, 200, 48));
    _rect(tester, _key('navigation'), const Rect.fromLTWH(24, 766, 342, 54));
    final add = tester.widget<Container>(_key('add_surface'));
    expect((add.decoration as BoxDecoration).color, const Color(0xFF2F6B57));
    expect(tester.getSize(_key('add')), const Size(44, 44));
    final cta = tester.widget<AppButton>(_key('register'));
    expect(cta.backgroundColor, const Color(0xFF2F6B57));
    expect(cta.foregroundColor, Colors.white);
  });

  testWidgets('원본 배경과 아이콘만 사용하고 점선 원 안의 캐릭터는 비어 있다', (tester) async {
    await _open(tester);
    final image = tester.widget<Image>(_key('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/pet_registration_complete_background.png',
    );
    expect(image.excludeFromSemantics, isTrue);
    expect(tester.getSize(_key('background')), const Size(390, 844));
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.widget<CustomPaint>(_key('character_slot')).painter,
      isNotNull,
    );
    final character = tester.widget<SizedBox>(_key('character'));
    expect(character.child, isNull);
    expect(character.width, 36);
    expect(character.height, 54);
    final nav = tester.widget<AppBottomNavigation>(_key('navigation'));
    expect(nav.currentTab, AppTab.pets);
    expect(nav.iconAssets.length, 4);
    for (final svg in find.byType(SvgPicture).evaluate()) {
      expect(
        tester.getRect(find.byWidget(svg.widget)).size,
        const Size(16, 16),
      );
    }
  });

  testWidgets('목록 기본 선택과 휠 전환은 빈 상태와 하단 선택을 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(_selected(tester, _key('mode_list')), isTrue);
      expect(_selected(tester, _key('mode_wheel')), isFalse);
      for (final mode in ['wheel', 'list', 'wheel']) {
        await tester.tap(_key('mode_$mode'));
        await tester.pumpAndSettle();
        expect(_selected(tester, _key('mode_$mode')), isTrue);
        expect(_selected(tester, _tab(AppTab.pets)), isTrue);
        expect(find.text('등록순 · 0마리'), findsOneWidget);
        expect(find.text('첫 개체를 등록해 보세요'), findsOneWidget);
        expect(tester.widget<SizedBox>(_key('character')).child, isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  for (final entry in ['add', 'register']) {
    for (final exit in ['back_button', 'system_back']) {
      testWidgets('$entry 등록 화면 진입과 $exit 복귀 후 선택·빈 상태를 보존한다', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _open(tester);
          await tester.tap(_key('mode_wheel'));
          await tester.pumpAndSettle();
          final original = tester.element(find.byType(PetListEmptyScreen));
          await tester.tap(_key(entry));
          await tester.pumpAndSettle();
          expect(find.byType(PetRegistrationScreen), findsOneWidget);
          expect(
            tester.widget<TextFormField>(_field('name')).controller!.text,
            isEmpty,
          );
          await tester.enterText(_field('name'), '모모');
          await tester.ensureVisible(_field('memo'));
          await tester.enterText(_field('memo'), '미리보기 메모');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          if (exit == 'system_back') {
            await tester.binding.handlePopRoute();
          } else {
            await tester.ensureVisible(find.bySemanticsLabel('뒤로가기'));
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel('뒤로가기'));
          }
          await tester.pumpAndSettle();
          expect(
            tester.element(find.byType(PetListEmptyScreen)),
            same(original),
          );
          expect(_selected(tester, _key('mode_wheel')), isTrue);
          expect(find.text('등록순 · 0마리'), findsOneWidget);
          expect(find.text('모모'), findsNothing);
          expect(find.byType(HomeScreen), findsNothing);
          expect(_selected(tester, _tab(AppTab.pets)), isTrue);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('미연결 등록 저장 시 성공으로 전환하지 않으며 안내도 빈 목록에 남지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('register'));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('pet_registration_save_button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsOneWidget);
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsNothing);
    expect(find.text('등록순 · 0마리'), findsOneWidget);
  });

  testWidgets('등록 버튼 연속 실행으로 화면을 중복해서 쌓지 않는다', (tester) async {
    await _open(tester);
    final press = tester.widget<AppButton>(_key('register')).onPressed!;
    press();
    press();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsNothing);
    expect(find.byType(PetListEmptyScreen), findsOneWidget);
  });

  testWidgets('다른 탭은 안내만 표시하고 내 아이들 선택 및 로컬 모드를 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      await tester.tap(_key('mode_wheel'));
      await tester.pumpAndSettle();
      for (final tab in [AppTab.habitat, AppTab.records, AppTab.profile]) {
        await tester.tap(_tab(tab));
        await tester.pumpAndSettle();
        expect(find.textContaining('기능은 준비 중입니다.'), findsOneWidget);
        expect(_selected(tester, _tab(AppTab.pets)), isTrue);
        expect(_selected(tester, _tab(tab)), isFalse);
        expect(_tab(tab).hitTestable(), findsOneWidget);
        expect(_selected(tester, _key('mode_wheel')), isTrue);
      }
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(_tab(AppTab.pets));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(PetListEmptyScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final exit in ['cancel', 'back']) {
    testWidgets('사전 안내 $exit 시 빈 화면을 열지 않는다', (tester) async {
      await _open(tester, home: const LoginScreen());
      final original = tester.element(find.byType(LoginScreen));
      final opening = showPetListEmptyPreview(original);
      await tester.pumpAndSettle();
      expect(
        find.text(
          '이 화면은 Figma 디자인 미리보기입니다. 실제 개체 목록 조회, 등록 저장 및 서버 데이터 변경은 실행되지 않습니다.',
        ),
        findsOneWidget,
      );
      expect(find.byType(PetListEmptyScreen), findsNothing);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('취소'));
      }
      await tester.pumpAndSettle();
      await opening;
      expect(tester.element(find.byType(LoginScreen)), same(original));
    });
  }

  testWidgets('독립 Debug 진입은 안내 확인 후 열리고 뒤로가면 로그인으로 돌아온다', (tester) async {
    await _open(tester, home: const preview.PetListEmptyPreviewHost());
    expect(find.text('디자인 미리보기'), findsOneWidget);
    expect(find.byType(PetListEmptyScreen), findsNothing);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(PetListEmptyScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('직접 연 루트에서도 시스템 뒤로가기는 로그인으로 안전하게 복귀한다', (tester) async {
    await _open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '${size.width}×${size.height} 글자 $scale 배에서 스크롤·선택·44px 타깃과 고정 탭을 유지한다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          final nav = tester.getRect(_key('navigation'));
          expect(nav.bottom, size.height - 24);
          final petsLabel = find.descendant(
            of: _tab(AppTab.pets),
            matching: find.text('내 아이들'),
          );
          final paragraph = tester.renderObject<RenderParagraph>(petsLabel);
          for (final box in paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 5),
          )) {
            expect(box.right, lessThanOrEqualTo(paragraph.size.width + .1));
            expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .1));
          }
          for (final control in [
            _key('add'),
            _key('mode_list'),
            _key('mode_wheel'),
            _key('register'),
            for (final tab in AppTab.values) _tab(tab),
          ]) {
            await tester.ensureVisible(control);
            await tester.pumpAndSettle();
            final rect = tester.getRect(control);
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, greaterThanOrEqualTo(24));
            expect(rect.right, lessThanOrEqualTo(size.width - 24));
            expect(control.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await tester.ensureVisible(_key('mode_wheel'));
          await tester.tap(_key('mode_wheel'));
          await tester.pumpAndSettle();
          expect(find.text('등록순 · 0마리'), findsOneWidget);
          expect(tester.getRect(_key('navigation')), nav);
          await tester.ensureVisible(_key('register'));
          await tester.tap(_key('register'));
          await tester.pumpAndSettle();
          expect(find.byType(PetRegistrationScreen), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(tester.getRect(_key('navigation')), nav);
          expect(find.text('등록순 · 0마리'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('큰 SafeArea에서도 내비게이션과 내용에 접근할 수 있다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      top: 75,
      bottom: 60,
      scale: 2,
    );
    expect(tester.getRect(_key('header')).top, 79);
    expect(tester.getRect(_key('navigation')).bottom, 580);
    await tester.ensureVisible(_key('register'));
    await tester.pumpAndSettle();
    expect(_key('register').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TalkBack은 추가·빈 자리·토글과 현재 하단 탭을 구분한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(find.bySemanticsLabel('개체 추가'), findsOneWidget);
      expect(find.bySemanticsLabel('등록된 개체가 없는 빈 캐릭터 자리'), findsOneWidget);
      expect(find.bySemanticsLabel('목록 보기'), findsOneWidget);
      expect(find.bySemanticsLabel('휠 보기'), findsOneWidget);
      expect(
        tester
            .getSemantics(_key('mode_list'))
            .flagsCollection
            .isInMutuallyExclusiveGroup,
        isTrue,
      );
      expect(_selected(tester, _key('mode_list')), isTrue);
      expect(_selected(tester, _tab(AppTab.pets)), isTrue);
      await tester.tap(_key('mode_wheel'));
      await tester.pumpAndSettle();
      expect(_selected(tester, _key('mode_wheel')), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('일반 앱의 로그인과 라우트는 그대로다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetListEmptyScreen), findsNothing);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routes
          ?.keys
          .any((r) => r.contains('pet-list')),
      isFalse,
    );
  });
}
