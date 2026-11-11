import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_list_loading_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_list_loading_preview.dart' as preview;

Finder _key(String key) => find.byKey(ValueKey('pet_list_loading_$key'));
Finder _tab(AppTab tab) =>
    find.byKey(ValueKey('app_bottom_navigation_${tab.name}_touch_target'));

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetListLoadingScreen(),
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

void _fullTabLabels(WidgetTester tester) {
  for (final entry in {
    AppTab.habitat: '사육장',
    AppTab.records: '기록',
    AppTab.pets: '내 아이들',
    AppTab.profile: '마이',
  }.entries) {
    final label = find.descendant(
      of: _tab(entry.key),
      matching: find.text(entry.value),
    );
    final paragraph = tester.renderObject<RenderParagraph>(label);
    expect(paragraph.didExceedMaxLines, isFalse, reason: entry.value);
    final bounds = Offset.zero & paragraph.size;
    for (var i = 0; i < entry.value.length; i++) {
      if (entry.value[i] == ' ') continue;
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      expect(boxes, isNotEmpty, reason: '${entry.value} 문자 $i');
      for (final box in boxes) {
        expect(box.left, greaterThanOrEqualTo(bounds.left - .1));
        expect(box.right, lessThanOrEqualTo(bounds.right + .1));
        expect(box.top, greaterThanOrEqualTo(bounds.top - .1));
        expect(box.bottom, lessThanOrEqualTo(bounds.bottom + .1));
      }
    }
  }
}

void _rect(WidgetTester tester, Finder finder, Rect expected) {
  final actual = tester.getRect(finder);
  expect(actual.left, closeTo(expected.left, .1));
  expect(actual.top, closeTo(expected.top, .1));
  expect(actual.width, closeTo(expected.width, .1));
  expect(actual.height, closeTo(expected.height, .1));
}

void _sixCards(WidgetTester tester) {
  for (var i = 0; i < 6; i++) {
    expect(_key('card_$i'), findsOneWidget);
    expect(tester.getSize(_key('card_$i')).height, 78);
  }
  expect(_key('card_6'), findsNothing);
  expect(find.text('등록순 · 불러오는 중'), findsOneWidget);
  expect(find.text('등록순 · 7마리'), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('실제 데이터 없이 Jua 로딩 문구와 스켈레톤 6개를 표시한다', (tester) async {
    await _open(tester);
    _sixCards(tester);
    expect(find.text('내 아이들'), findsNWidgets(2));
    expect(find.text('9:41'), findsNothing);
    expect(find.text('욱이'), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(
      tester.widget<Text>(find.text('등록순 · 불러오는 중')).style?.fontFamily,
      'Jua',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 헤더·카드 6개와 탭바의 Figma 좌표·간격·Glass를 유지한다', (
    tester,
  ) async {
    await _open(tester);
    _rect(tester, _key('header'), const Rect.fromLTWH(24, 58, 342, 44));
    _rect(tester, _key('add_surface'), const Rect.fromLTWH(330, 62, 36, 36));
    _rect(tester, _key('skeletons'), const Rect.fromLTWH(24, 116, 342, 508));
    _rect(tester, _key('navigation'), const Rect.fromLTWH(24, 766, 342, 54));
    for (var i = 0; i < 6; i++) {
      final y = 116.0 + i * 86;
      _rect(tester, _key('card_$i'), Rect.fromLTWH(24, y, 342, 78));
      _rect(tester, _key('placeholder_$i'), Rect.fromLTWH(41, y + 15, 48, 48));
      _rect(tester, _key('name_$i'), Rect.fromLTWH(101, y + 25, 90, 10));
      _rect(tester, _key('detail_$i'), Rect.fromLTWH(101, y + 43, 150, 10));
      final surface = tester.widget<AppGlassSurface>(
        find.descendant(
          of: _key('card_$i'),
          matching: find.byType(AppGlassSurface),
        ),
      );
      expect(surface.borderRadius, BorderRadius.circular(22));
      expect(surface.gradient, AppColors.glassSoftGradient);
      expect(surface.borderColor, Colors.white);
      expect(surface.blur, 18);
      final line = tester.widget<Container>(_key('name_$i'));
      final decoration = line.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x99E6E1D6));
      expect(decoration.borderRadius, BorderRadius.circular(5));
    }
  });

  testWidgets('Figma 배경·원형 SVG·각 아이콘을 원본 슬롯 크기로 재사용한다', (tester) async {
    await _open(tester);
    final image = tester.widget<Image>(_key('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/pet_registration_complete_background.png',
    );
    expect(image.excludeFromSemantics, isTrue);
    expect(find.byType(Image), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      final svg = tester.widget<SvgPicture>(_key('placeholder_$i'));
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/icons/pet_list_loading_placeholder.svg',
      );
      expect(tester.getSize(_key('placeholder_$i')), const Size(48, 48));
    }
    final nav = tester.widget<AppBottomNavigation>(_key('navigation'));
    expect(nav.currentTab, AppTab.pets);
    expect(nav.iconAssets.length, 4);
    for (final entry in nav.iconAssets.entries) {
      final svg = find.descendant(
        of: _tab(entry.key),
        matching: find.byType(SvgPicture),
      );
      expect(
        (tester.widget<SvgPicture>(svg).bytesLoader as SvgAssetLoader)
            .assetName,
        entry.value,
      );
      expect(tester.getSize(svg), const Size(16, 16));
    }
    final plus = find.descendant(
      of: _key('add'),
      matching: find.byType(SvgPicture),
    );
    expect(tester.getSize(plus), const Size(16, 16));
    expect(
      (tester.widget<SvgPicture>(plus).bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/pet_list_loading_plus.svg',
    );
  });

  testWidgets('목록과 휠은 로컬 선택만 바꾸고 장시간 지나도 로딩을 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(_selected(tester, _key('mode_list')), isTrue);
      for (final mode in ['wheel', 'list', 'wheel']) {
        await tester.tap(_key('mode_$mode'));
        await tester.pumpAndSettle();
        expect(_selected(tester, _key('mode_$mode')), isTrue);
        expect(_selected(tester, _tab(AppTab.pets)), isTrue);
        _sixCards(tester);
      }
      await tester.pump(const Duration(minutes: 5));
      _sixCards(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('카드 탭으로 개체 상세나 가짜 완료 화면을 만들지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('card_0'));
    await tester.pumpAndSettle();
    _sixCards(tester);
    expect(find.byType(PetRegistrationScreen), findsNothing);
  });

  for (final exit in ['system_back', 'back_button']) {
    testWidgets('등록 화면 $exit 복귀 시 로컬 모드·로딩 상태를 유지한다', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _open(tester);
        await tester.tap(_key('mode_wheel'));
        await tester.pumpAndSettle();
        final original = tester.element(find.byType(PetListLoadingScreen));
        await tester.tap(_key('add'));
        await tester.pumpAndSettle();
        expect(find.byType(PetRegistrationScreen), findsOneWidget);
        final name = find.descendant(
          of: find.byKey(const ValueKey('pet_name_field')),
          matching: find.byType(TextFormField),
        );
        expect(tester.widget<TextFormField>(name).controller!.text, isEmpty);
        await tester.enterText(name, '모모');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        if (exit == 'system_back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.bySemanticsLabel('뒤로가기'));
        }
        await tester.pumpAndSettle();
        expect(
          tester.element(find.byType(PetListLoadingScreen)),
          same(original),
        );
        expect(_selected(tester, _key('mode_wheel')), isTrue);
        _sixCards(tester);
        expect(find.text('모모'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('등록 저장은 기존 준비 중 안내만 표시하며 복귀 후 안내와 데이터가 남지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('add'));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('pet_registration_save_button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsNothing);
    _sixCards(tester);
  });

  testWidgets('연속 등록 진입 요청으로 화면이 중복되지 않는다', (tester) async {
    await _open(tester);
    final open = tester.widget<InkWell>(_key('add')).onTap!;
    open();
    open();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsNothing);
    _sixCards(tester);
  });

  testWidgets('하단 탭은 준비 중 안내만 띄우고 내 아이들 선택과 로딩을 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      for (final tab in [AppTab.habitat, AppTab.records, AppTab.profile]) {
        await tester.tap(_tab(tab));
        await tester.pumpAndSettle();
        expect(find.textContaining('기능은 준비 중입니다.'), findsOneWidget);
        expect(_selected(tester, _tab(AppTab.pets)), isTrue);
        expect(_selected(tester, _tab(tab)), isFalse);
        expect(_tab(tab).hitTestable(), findsOneWidget);
        _sixCards(tester);
      }
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(_tab(AppTab.pets));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final exit in ['cancel', 'back']) {
    testWidgets('사전 안내 $exit 시 진입하지 않는다', (tester) async {
      await _open(tester, home: const LoginScreen());
      final original = tester.element(find.byType(LoginScreen));
      final opening = showPetListLoadingPreview(original);
      await tester.pumpAndSettle();
      expect(find.text(petListLoadingPreviewNotice), findsOneWidget);
      expect(find.byType(PetListLoadingScreen), findsNothing);
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

  testWidgets('독립 Debug 진입점은 사전 안내 확인 후 열리고 로그인으로 복귀한다', (tester) async {
    await _open(tester, home: const preview.PetListLoadingPreviewHost());
    expect(find.text(petListLoadingPreviewNotice), findsOneWidget);
    expect(find.byType(PetListLoadingScreen), findsNothing);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    _sixCards(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('루트로 직접 열어도 시스템 뒤로가기는 로그인으로 복귀한다', (tester) async {
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
        '${size.width}×${size.height} 글자 $scale 배에서 스크롤·고정 탭·44px 터치 영역을 유지한다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          final nav = tester.getRect(_key('navigation'));
          _fullTabLabels(tester);
          if (size.width == 320 && scale == 2) {
            final petsLabel = find.descendant(
              of: _tab(AppTab.pets),
              matching: find.text('내 아이들'),
            );
            final paragraph = tester.renderObject<RenderParagraph>(petsLabel);
            final lines = paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 5),
            );
            expect(lines.map((box) => box.top).toSet().length, 2);
          }
          expect(nav.bottom, size.height - 24);
          _sixCards(tester);
          for (var i = 0; i < 6; i++) {
            await tester.ensureVisible(_key('card_$i'));
            await tester.pumpAndSettle();
            expect(_key('card_$i').hitTestable(), findsOneWidget);
            final card = tester.getRect(_key('card_$i'));
            expect(card.left, 24);
            expect(card.right, size.width - 24);
            expect(tester.getSize(_key('detail_$i')), const Size(150, 10));
            expect(tester.getRect(_key('navigation')), nav);
            expect(tester.takeException(), isNull);
          }
          for (final control in [
            _key('add'),
            _key('mode_list'),
            _key('mode_wheel'),
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
          }
          await tester.ensureVisible(_key('mode_wheel'));
          await tester.tap(_key('mode_wheel'));
          await tester.pumpAndSettle();
          _sixCards(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('큰 SafeArea에서도 마지막 카드와 하단 탭에 접근할 수 있다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      scale: 2,
      top: 75,
      bottom: 60,
    );
    expect(tester.getRect(_key('header')).top, 79);
    expect(tester.getRect(_key('navigation')).bottom, 580);
    _fullTabLabels(tester);
    await tester.ensureVisible(_key('card_5'));
    await tester.pumpAndSettle();
    expect(_key('card_5').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('접근성은 개체 데이터 대신 로딩 상태와 선택된 컨트롤을 알린다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(
        find.bySemanticsLabel('개체 목록을 불러오는 중입니다. 디자인 미리보기입니다.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('개체 추가'), findsOneWidget);
      expect(find.bySemanticsLabel('목록 보기'), findsOneWidget);
      expect(find.bySemanticsLabel('휠 보기'), findsOneWidget);
      expect(_selected(tester, _key('mode_list')), isTrue);
      expect(_selected(tester, _tab(AppTab.pets)), isTrue);
      expect(
        tester
            .getSemantics(_key('mode_list'))
            .flagsCollection
            .isInMutuallyExclusiveGroup,
        isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('일반 앱은 로그인에서 시작하고 로딩 미리보기 라우트를 노출하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetListLoadingScreen), findsNothing);
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
