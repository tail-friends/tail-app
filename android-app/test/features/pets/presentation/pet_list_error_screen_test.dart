import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_list_error_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_list_error_preview.dart' as preview;

Finder _key(String key) => find.byKey(ValueKey('pet_list_error_$key'));
Finder _tab(AppTab tab) =>
    find.byKey(ValueKey('app_bottom_navigation_${tab.name}_touch_target'));

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetListErrorScreen(),
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
  final rect = tester.getRect(finder);
  expect(rect.left, closeTo(expected.left, .1));
  expect(rect.top, closeTo(expected.top, .1));
  expect(rect.width, closeTo(expected.width, .1));
  expect(rect.height, closeTo(expected.height, .1));
}

void _errorState() {
  expect(find.byType(PetListErrorScreen), findsOneWidget);
  expect(find.text('등록순 · 불러올 수 없음'), findsOneWidget);
  expect(find.text('목록을 불러오지 못했어요'), findsOneWidget);
  expect(find.text('잠시 후 다시 시도해 주세요'), findsOneWidget);
  expect(find.text('등록순 · 7마리'), findsNothing);
  expect(find.byType(HomeScreen), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('오류 제목·설명·중립 마릿수와 빈 캐릭터만 표시한다', (tester) async {
    await _open(tester);
    _errorState();
    for (final text in ['목록을 불러오지 못했어요', '잠시 후 다시 시도해 주세요', '다시 시도']) {
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    final character = tester.widget<SizedBox>(_key('character'));
    expect(character.child, isNull);
    expect(character.width, 36);
    expect(character.height, 54);
    expect(find.text('9:41'), findsNothing);
    expect(find.text('욱이'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('390×844 오류 영역·버튼·토스트·고정 탭이 Figma 좌표와 크기를 유지한다', (tester) async {
    await _open(tester);
    _rect(tester, _key('header'), const Rect.fromLTWH(24, 58, 342, 44));
    _rect(tester, _key('add_surface'), const Rect.fromLTWH(330, 62, 36, 36));
    _rect(tester, _key('content'), const Rect.fromLTWH(24, 116, 342, 322));
    _rect(
      tester,
      _key('character_slot'),
      const Rect.fromLTWH(147, 226, 96, 96),
    );
    _rect(tester, _key('retry'), const Rect.fromLTWH(95, 390, 200, 48));
    _rect(
      tester,
      _key('network_toast'),
      const Rect.fromLTWH(103.5, 701, 170, 39),
    );
    _rect(tester, _key('navigation'), const Rect.fromLTWH(24, 766, 342, 54));
    final retry = tester.widget<AppButton>(_key('retry'));
    expect(retry.variant, AppButtonVariant.secondary);
    expect(retry.foregroundColor, const Color(0xFF2B2A26));
    final surface = tester.widget<AppGlassSurface>(
      find.descendant(
        of: _key('retry'),
        matching: find.byType(AppGlassSurface),
      ),
    );
    expect(surface.borderColor, Colors.white);
    expect(surface.gradient, AppColors.glassStrongGradient);
    expect(surface.blur, 18);
    expect(surface.borderRadius, BorderRadius.circular(AppRadius.full));
  });

  testWidgets('원본 배경과 SVG를 정확한 크기로 표시하고 임의 캐릭터 이미지는 없다', (tester) async {
    await _open(tester);
    final image = tester.widget<Image>(_key('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/pet_registration_complete_background.png',
    );
    expect(image.excludeFromSemantics, isTrue);
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.widget<CustomPaint>(_key('character_slot')).painter,
      isNotNull,
    );
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
    expect(
      (tester.widget<SvgPicture>(plus).bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/pet_list_error_plus.svg',
    );
    expect(tester.getSize(plus), const Size(16, 16));
  });

  testWidgets('목록·휠 전환 및 시간 경과로 오류 상태가 성공으로 바뀌지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(_selected(tester, _key('mode_list')), isTrue);
      for (final mode in ['wheel', 'list', 'wheel']) {
        await tester.tap(_key('mode_$mode'));
        await tester.pumpAndSettle();
        expect(_selected(tester, _key('mode_$mode')), isTrue);
        expect(_selected(tester, _tab(AppTab.pets)), isTrue);
        _errorState();
      }
      await tester.pump(const Duration(minutes: 5));
      _errorState();
      expect(tester.binding.hasScheduledFrame, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('재시도는 미연결 안내만 표시하며 반복 실행해도 가짜 목록이 생기지 않는다', (tester) async {
    await _open(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(_key('retry'));
      await tester.pumpAndSettle();
      expect(find.text(petListErrorRetryNotice), findsOneWidget);
      expect(_key('retry').hitTestable(), findsOneWidget);
      expect(_key('network_toast'), findsOneWidget);
      _errorState();
    }
  });

  testWidgets('주입된 재시도 콜백은 클릭마다 한 번 호출하며 화면 데이터는 바꾸지 않는다', (tester) async {
    var attempts = 0;
    await _open(tester, home: PetListErrorScreen(onRetry: () => attempts++));
    expect(attempts, 0);
    await tester.tap(_key('retry'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text(petListErrorRetryNotice), findsNothing);
    _errorState();
    await tester.tap(_key('mode_wheel'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
  });

  testWidgets('기본 미리보기와 재시도는 HTTP 클라이언트를 생성하지 않는다', (tester) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await _open(tester);
        await tester.tap(_key('retry'));
        await tester.pumpAndSettle();
        await tester.tap(_key('mode_wheel'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(minutes: 5));
        await tester.pumpAndSettle();
        _errorState();
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Unexpected HTTP client in static preview');
      },
    );
    expect(requests, 0);
  });

  testWidgets('네트워크 토스트는 지정한 색과 문구의 진단 없는 디자인 예시다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(find.text('인터넷 연결을 확인해 주세요'), findsOneWidget);
      final toast = tester.widget<Container>(_key('network_toast'));
      expect(
        (toast.decoration as BoxDecoration).color,
        const Color(0xFF2B2A26),
      );
      expect(
        (toast.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(AppRadius.full),
      );
      expect(
        tester.widget<Text>(find.text('인터넷 연결을 확인해 주세요')).style?.color,
        Colors.white,
      );
      expect(
        find.bySemanticsLabel(
          '네트워크 안내 토스트 디자인 예시입니다. 실제 인터넷 연결 상태를 진단하지 않았습니다.',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final exit in ['system_back', 'back_button']) {
    testWidgets('등록 화면 $exit 복귀 시 오류 상태·선택을 보존한다', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _open(tester);
        await tester.tap(_key('mode_wheel'));
        await tester.pumpAndSettle();
        final original = tester.element(find.byType(PetListErrorScreen));
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
        expect(tester.element(find.byType(PetListErrorScreen)), same(original));
        expect(_selected(tester, _key('mode_wheel')), isTrue);
        expect(find.text('모모'), findsNothing);
        _errorState();
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('등록 저장 안내는 기존 동작을 유지하고 오류 화면으로 누출되지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('retry'));
    await tester.pumpAndSettle();
    await tester.tap(_key('add'));
    await tester.pumpAndSettle();
    expect(find.text(petListErrorRetryNotice), findsNothing);
    final save = find.byKey(const ValueKey('pet_registration_save_button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsNothing);
    _errorState();
  });

  testWidgets('연속 + 실행으로 등록 화면을 중복해서 열지 않는다', (tester) async {
    await _open(tester);
    final action = tester.widget<InkWell>(_key('add')).onTap!;
    action();
    action();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsNothing);
    _errorState();
  });

  testWidgets('다른 하단 탭은 준비 중 안내만 제공하고 내 아이들 선택을 유지한다', (tester) async {
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
        _errorState();
      }
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(_tab(AppTab.pets));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final exit in ['cancel', 'back']) {
    testWidgets('사전 안내 $exit 시 진입하지 않는다', (tester) async {
      await _open(tester, home: const LoginScreen());
      final original = tester.element(find.byType(LoginScreen));
      final future = showPetListErrorPreview(original);
      await tester.pumpAndSettle();
      expect(find.textContaining(petListErrorPreviewNotice), findsOneWidget);
      expect(find.textContaining('실제 연결 상태와 무관한 디자인 예시'), findsOneWidget);
      expect(find.byType(PetListErrorScreen), findsNothing);
      if (exit == 'cancel') {
        await tester.tap(find.text('취소'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      await future;
      expect(tester.element(find.byType(LoginScreen)), same(original));
    });
  }

  testWidgets('독립 Debug 진입점은 사전 안내 확인 후 열리고 로그인으로 복귀한다', (tester) async {
    await _open(tester, home: const preview.PetListErrorPreviewHost());
    expect(find.textContaining(petListErrorPreviewNotice), findsOneWidget);
    expect(find.byType(PetListErrorScreen), findsNothing);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    _errorState();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('루트 오류 화면도 시스템 뒤로가기로 로그인에 복귀한다', (tester) async {
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
        '${size.width}×${size.height} 글자 $scale 배에서 스크롤·고정 토스트·탭과 터치 영역을 유지한다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          final nav = tester.getRect(_key('navigation'));
          final toast = tester.getRect(_key('network_toast'));
          expect(nav.bottom, size.height - 24);
          expect(toast.bottom, closeTo(nav.top - 26, .1));
          expect(toast.left, greaterThanOrEqualTo(24));
          expect(toast.right, lessThanOrEqualTo(size.width - 24));
          for (final control in [
            _key('add'),
            _key('mode_list'),
            _key('mode_wheel'),
            _key('retry'),
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
            expect(tester.getRect(_key('navigation')), nav);
            expect(tester.getRect(_key('network_toast')), toast);
            expect(tester.takeException(), isNull);
          }
          await tester.ensureVisible(_key('retry'));
          await tester.tap(_key('retry'));
          await tester.pumpAndSettle();
          expect(find.text(petListErrorRetryNotice), findsOneWidget);
          _errorState();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('큰 SafeArea에서도 오류 버튼·토스트·내비게이션에 접근한다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      scale: 2,
      top: 75,
      bottom: 60,
    );
    expect(tester.getRect(_key('header')).top, 79);
    expect(tester.getRect(_key('navigation')).bottom, 580);
    await tester.ensureVisible(_key('retry'));
    await tester.pumpAndSettle();
    expect(_key('retry').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('접근성은 빈 자리·선택 토글·추가 버튼과 현재 탭을 구분한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(find.bySemanticsLabel('오류 화면의 빈 캐릭터 자리'), findsOneWidget);
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

  testWidgets('일반 앱은 로그인에서 시작하고 오류 미리보기 라우트를 노출하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetListErrorScreen), findsNothing);
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
