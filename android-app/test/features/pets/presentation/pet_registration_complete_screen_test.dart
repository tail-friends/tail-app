import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_hatching_date_sheet.dart';
import 'package:tail_friends/features/pets/presentation/pet_photo_add_sheet.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_complete_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_registration_complete_preview.dart' as preview;

const _data = PetRegistrationCompleteData(
  name: '욱이',
  speciesLabel: '레오파드 게코',
  genderLabel: '수컷',
  hatchingDate: HatchingDateSelection(year: 2024, month: 7, day: 12),
  feedingCycleDays: 4,
);
const _notice = '디자인 미리보기입니다. 실제 캐릭터 생성 기능은 연결되지 않았습니다.';
Finder _key(String key) =>
    find.byKey(ValueKey('pet_registration_complete_$key'));
Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey('pet_${key}_field')),
  matching: find.byType(TextFormField),
);

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetRegistrationCompleteScreen(data: _data),
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 30,
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

Future<void> _launch(WidgetTester tester) async {
  showPetRegistrationCompletePreview(
    tester.element(find.byType(PetRegistrationScreen)),
  );
  await tester.pumpAndSettle();
  expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
}

void _rect(WidgetTester tester, String key, Rect expected) {
  final actual = tester.getRect(_key(key));
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

  for (final entry in {'콩': '콩이', '모모': '모모가', '욱이': '욱이가'}.entries) {
    testWidgets('${entry.key} 이름의 조사와 접근성 제목을 함께 표시한다', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _open(
          tester,
          home: PetRegistrationCompleteScreen(
            data: PetRegistrationCompleteData(
              name: entry.key,
              speciesLabel: _data.speciesLabel,
              genderLabel: _data.genderLabel,
              hatchingDate: _data.hatchingDate,
              feedingCycleDays: _data.feedingCycleDays,
            ),
          ),
        );
        final title = '${entry.value} 꼬리친구가 됐어요';
        expect(find.text(title), findsOneWidget);
        final heading = tester.getSemantics(find.text(title));
        expect(heading.flagsCollection.isHeader, isTrue);
        expect(heading.label, 'Figma 예시: $title. 실제 개체 등록은 실행되지 않았습니다.');
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Figma 문구와 요약 네 행을 Jua로 표시한다', (tester) async {
    await _open(tester);
    for (final text in [
      '욱이가 꼬리친구가 됐어요',
      '이제 사진으로 캐릭터를 만들어 볼까요?',
      '종',
      '레오파드 게코',
      '성별',
      '수컷',
      '해칭일',
      '2024.07.12',
      '급여 주기',
      '4일',
      '캐릭터 만들기',
      '홈으로',
    ]) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    expect(find.text('9:41'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844의 원본 위치·크기와 Glass 스타일을 유지한다', (tester) async {
    await _open(tester);
    _rect(tester, 'avatar', const Rect.fromLTWH(135, 150, 120, 120));
    _rect(tester, 'summary', const Rect.fromLTWH(24, 346, 342, 177));
    _rect(tester, 'create_character', const Rect.fromLTWH(24, 706, 342, 50));
    _rect(tester, 'home', const Rect.fromLTWH(24, 764, 342, 50));
    final summary = tester.widget<AppGlassSurface>(_key('summary'));
    expect(summary.borderRadius, BorderRadius.circular(22));
    expect(summary.borderColor, Colors.white);
    expect(summary.blur, 18);
    expect(summary.gradient, AppColors.glassSoftGradient);
    final avatar = tester.widget<AppGlassSurface>(_key('avatar'));
    expect(avatar.borderRadius, BorderRadius.circular(AppRadius.full));
    expect(avatar.boxShadow.single.blurRadius, 32);
    final create = tester.widget<AppButton>(_key('create_character'));
    expect(create.backgroundColor, const Color(0xFF2F6B57));
    expect(
      tester.widget<AppButton>(_key('home')).variant,
      AppButtonVariant.ghost,
    );
  });

  testWidgets('배경 원본만 이미지로 사용하고 캐릭터 자리를 비워 둔다', (tester) async {
    await _open(tester);
    final image = tester.widget<Image>(_key('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/pet_registration_complete_background.png',
    );
    expect(image.fit, BoxFit.cover);
    expect(image.excludeFromSemantics, isTrue);
    expect(tester.getSize(_key('background')), const Size(390, 844));
    expect(find.byType(Image), findsOneWidget);
    final empty = tester.widget<SizedBox>(_key('empty_character'));
    expect(empty.child, isNull);
    expect(empty.width, 50.4);
    expect(empty.height, 75.6);
  });

  testWidgets('월 단위 해칭일을 가짜 1일로 바꾸지 않고 주입한 정보를 표시한다', (tester) async {
    const date = HatchingDateSelection(year: 2024, month: 7);
    const data = PetRegistrationCompleteData(
      name: '모모',
      speciesLabel: '직접 입력한 종',
      genderLabel: '미구분',
      hatchingDate: date,
      feedingCycleDays: null,
    );
    await _open(tester, home: const PetRegistrationCompleteScreen(data: data));
    for (final text in [
      '모모가 꼬리친구가 됐어요',
      '직접 입력한 종',
      '미구분',
      '2024.07 (일자 미상)',
      '미입력',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('2024.07.01'), findsNothing);
    expect(find.text('욱이가 꼬리친구가 됐어요'), findsNothing);
    expect(date.exactDate, isNull);
  });

  testWidgets('해칭일과 주기가 없으면 예시 수치를 채워 넣지 않는다', (tester) async {
    await _open(
      tester,
      home: const PetRegistrationCompleteScreen(
        data: PetRegistrationCompleteData(
          name: '모모',
          speciesLabel: '미입력',
          genderLabel: '미구분',
          hatchingDate: null,
          feedingCycleDays: null,
        ),
      ),
    );
    expect(find.text('2024.07.12'), findsNothing);
    expect(find.text('4일'), findsNothing);
    expect(find.text('미입력'), findsNWidgets(3));
  });

  testWidgets('캐릭터 만들기는 안내만 표시하고 데이터·화면을 유지한다', (tester) async {
    await _open(tester);
    final element = tester.element(find.byType(PetRegistrationCompleteScreen));
    await tester.tap(_key('create_character'));
    await tester.pumpAndSettle();
    expect(find.text(_notice), findsOneWidget);
    expect(
      tester.element(find.byType(PetRegistrationCompleteScreen)),
      same(element),
    );
    expect(
      tester
          .widget<PetRegistrationCompleteScreen>(
            find.byType(PetRegistrationCompleteScreen),
          )
          .data,
      same(_data),
    );
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(PetPhotoAddSheet), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('욱이가 꼬리친구가 됐어요'), findsOneWidget);
  });

  testWidgets('안내를 승인하기 전에는 예시 화면을 표시하지 않고 취소할 수 있다', (tester) async {
    await _open(tester, home: const PetRegistrationScreen());
    final form = tester.element(find.byType(PetRegistrationScreen));
    final opening = showPetRegistrationCompletePreview(form);
    await tester.pumpAndSettle();
    expect(
      find.text(
        '이 화면은 Figma 디자인 미리보기입니다. 실제 개체 등록, 서버 저장, 캐릭터 생성 및 홈 데이터 변경은 실행되지 않습니다.',
      ),
      findsOneWidget,
    );
    expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await opening;
    expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
  });

  for (final exit in ['home', 'back']) {
    testWidgets('$exit 후 기존 등록 폼과 입력값을 보존하고 실제 홈으로 이동하지 않는다', (tester) async {
      await _open(tester, home: const PetRegistrationScreen());
      final form = tester.element(find.byType(PetRegistrationScreen));
      for (final entry in {
        'name': '모모',
        'memo': '보존할 메모',
        'feeding_cycle': '7',
      }.entries) {
        await tester.ensureVisible(_field(entry.key));
        await tester.enterText(_field(entry.key), entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _launch(tester);
      await tester.tap(_key('create_character'));
      await tester.pumpAndSettle();
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('home'));
      }
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
      expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text(_notice), findsNothing);
      for (final entry in {
        'name': '모모',
        'memo': '보존할 메모',
        'feeding_cycle': '7',
      }.entries) {
        expect(
          tester.widget<TextFormField>(_field(entry.key)).controller!.text,
          entry.value,
        );
      }
    });

    testWidgets('직접 루트로 연 경우 $exit 동작은 안전하게 로그인으로 복귀한다', (tester) async {
      await _open(tester);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('home'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '${size.width}×${size.height} 글자 $scale 배에서 스크롤과 고정 버튼을 유지한다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          final home = tester.getRect(_key('home'));
          final create = tester.getRect(_key('create_character'));
          expect(home.bottom, size.height - 30);
          expect(home.top - create.bottom, 8);
          for (final key in ['create_character', 'home']) {
            final rect = tester.getRect(_key(key));
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, 24);
            expect(rect.right, size.width - 24);
            expect(_key(key).hitTestable(), findsOneWidget);
          }
          await tester.scrollUntilVisible(
            find.text('급여 주기'),
            90,
            scrollable: find.descendant(
              of: _key('scroll'),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('급여 주기').hitTestable(), findsOneWidget);
          expect(tester.getRect(_key('home')), home);
          expect(tester.getRect(_key('create_character')), create);
          await tester.tap(_key('create_character'));
          await tester.pumpAndSettle();
          expect(find.text(_notice), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('큰 SafeArea와 긴 표시 값도 잘리지 않고 스크롤된다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      top: 75,
      bottom: 60,
      scale: 2,
      home: const PetRegistrationCompleteScreen(
        data: PetRegistrationCompleteData(
          name: '아주 긴 이름을 가진 작은 친구',
          speciesLabel: '직접 입력한 아주 긴 종 이름 예시',
          genderLabel: '미구분',
          hatchingDate: HatchingDateSelection(year: 2024, month: 7),
          feedingCycleDays: 4,
        ),
      ),
    );
    expect(tester.getRect(_key('home')).bottom, 580);
    await tester.ensureVisible(find.text('2024.07 (일자 미상)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('화면 제목·요약·버튼과 빈 캐릭터에 접근성 정보를 제공한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    expect(find.bySemanticsLabel('종: 레오파드 게코'), findsOneWidget);
    expect(find.bySemanticsLabel('해칭일: 2024.07.12'), findsOneWidget);
    expect(find.bySemanticsLabel('캐릭터 이미지가 없는 Figma 미리보기 자리'), findsOneWidget);
    final heading = tester.getSemantics(find.text('욱이가 꼬리친구가 됐어요'));
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(heading.label, contains('실제 개체 등록은 실행되지 않았습니다.'));
    for (final key in ['create_character', 'home']) {
      final buttonSemantics = find.descendant(
        of: _key(key),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        ),
      );
      final flags = tester.getSemantics(buttonSemantics).flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, ui.Tristate.isTrue);
    }
    semantics.dispose();
  });

  testWidgets('독립 Debug 진입은 사전 안내 후에만 열리고 종료하면 등록 화면으로 돌아온다', (tester) async {
    await _open(
      tester,
      home: const preview.PetRegistrationCompletePreviewHost(),
    );
    expect(find.text('디자인 미리보기'), findsOneWidget);
    expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationCompleteScreen), findsOneWidget);
    await tester.tap(_key('home'));
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    expect(find.text('욱이'), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('기존 저장 버튼을 눌러도 등록 완료 화면으로 이동하지 않는다', (tester) async {
    await _open(tester, home: const PetRegistrationScreen());
    final save = find.byKey(const ValueKey('pet_registration_save_button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('저장 기능은 준비 중입니다.'), findsOneWidget);
    expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
  });

  testWidgets('일반 앱 초기 로그인과 기존 라우트를 유지한다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetRegistrationCompleteScreen), findsNothing);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routes
          ?.keys
          .any((key) => key.contains('registration-complete')),
      isFalse,
    );
  });
}
