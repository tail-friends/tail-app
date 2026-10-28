import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_character_generation_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_character_generation_preview.dart' as preview;

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _field(String value) =>
    find.descendant(of: _key(value), matching: find.byType(TextFormField));

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetCharacterGenerationScreen(),
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 34,
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

void _rect(WidgetTester tester, String key, Rect expected) {
  final rect = tester.getRect(_key(key));
  expect(rect.left, closeTo(expected.left, 1));
  expect(rect.top, closeTo(expected.top, 1));
  expect(rect.width, closeTo(expected.width, 1));
  expect(rect.height, closeTo(expected.height, 1));
}

Future<void> _launchFromForm(WidgetTester tester) async {
  // Do not await the pushed route before exercising its dismissal.
  showPetCharacterGenerationPreview(
    tester.element(find.byType(PetRegistrationScreen)),
  );
  await tester.pumpAndSettle();
  expect(find.text('디자인 미리보기'), findsOneWidget);
  expect(find.byType(PetCharacterGenerationScreen), findsNothing);
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await loader.load();
  });

  testWidgets('Figma 고정 진행률과 세 단계, Jua를 표시한다', (tester) async {
    await _open(tester);
    for (final text in [
      '68%',
      '사진을 읽는 중…',
      '먼저 사진 색으로 미리보기를 만들었어요',
      '기기에서 주요 색 추출',
      '완료',
      'AI 분석 (체형·무늬·색 4개)',
      '진행 중',
      '캐릭터 생성',
      '대기',
      '취소',
    ]) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844 원본 링·내부 영역·배지·카드·버튼 좌표를 유지한다', (tester) async {
    await _open(tester);
    _rect(
      tester,
      'pet_generation_progress',
      const Rect.fromLTWH(85, 170, 220, 220),
    );
    _rect(
      tester,
      'pet_generation_empty_character',
      const Rect.fromLTWH(111, 196, 168, 168),
    );
    _rect(
      tester,
      'pet_generation_percentage',
      const Rect.fromLTWH(171.5, 366, 52, 29),
    );
    _rect(tester, 'pet_generation_copy', const Rect.fromLTWH(96, 424, 164, 40));
    _rect(
      tester,
      'pet_generation_stages',
      const Rect.fromLTWH(24, 500, 342, 145),
    );
    _rect(
      tester,
      'pet_generation_close_surface',
      const Rect.fromLTWH(24, 62, 36, 36),
    );
    _rect(
      tester,
      'pet_generation_cancel',
      const Rect.fromLTWH(24, 760, 342, 50),
    );
    final empty = tester.widget<Container>(
      _key('pet_generation_empty_character'),
    );
    expect(empty.child, isNull);
    expect(
      find.descendant(
        of: _key('pet_generation_empty_character'),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: _key('pet_generation_empty_character'),
        matching: find.byType(SvgPicture),
      ),
      findsNothing,
    );
  });

  testWidgets('스크린 리더에 실제 분석 미실행과 단계별 고정 시안임을 설명한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    expect(find.bySemanticsLabel('캐릭터 생성 디자인 미리보기'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('캐릭터 생성 디자인 미리보기')).value,
      '68%, 고정 시안. 실제 분석은 실행되지 않습니다.',
    );
    expect(
      find.bySemanticsLabel('기기에서 주요 색 추출, 완료. 디자인 예시, 실제 분석 미실행'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('AI 분석 (체형·무늬·색 4개), 진행 중. 디자인 예시, 실제 분석 미실행'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('캐릭터 생성, 대기. 디자인 예시, 실제 분석 미실행'),
      findsOneWidget,
    );
    expect(tester.getSize(_key('pet_generation_close')), const Size(44, 44));
    expect(
      tester.getSize(_key('pet_generation_cancel')).height,
      greaterThanOrEqualTo(44),
    );
    semantics.dispose();
  });

  testWidgets('5분이 지나도 진행률·단계·화면이 변하지 않는다', (tester) async {
    await _open(tester);
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('진행 중'), findsOneWidget);
    expect(find.text('대기'), findsOneWidget);
    expect(find.byType(PetCharacterGenerationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('미실행 안내를 확인해야 화면을 열며 안내 취소 시 등록 화면을 유지한다', (tester) async {
    await _open(tester, home: const PetRegistrationScreen());
    showPetCharacterGenerationPreview(
      tester.element(find.byType(PetRegistrationScreen)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('실제 사진 분석과 캐릭터 생성은 실행하지 않습니다. 진행률과 단계는 Figma 고정 예시입니다.'),
      findsOneWidget,
    );
    expect(find.byType(PetCharacterGenerationScreen), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    expect(find.byType(PetCharacterGenerationScreen), findsNothing);
  });

  testWidgets('안내 취소 버튼은 미리보기를 열지 않고 등록 폼의 입력값을 보존한다', (tester) async {
    await _open(tester, home: const PetRegistrationScreen());
    final form = tester.element(find.byType(PetRegistrationScreen));
    final values = {'pet_name_field': '모모', 'pet_memo_field': '취소 후에도 유지할 메모'};
    for (final entry in values.entries) {
      await tester.ensureVisible(_field(entry.key));
      await tester.enterText(_field(entry.key), entry.value);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final opening = showPetCharacterGenerationPreview(form);
    await tester.pumpAndSettle();
    expect(find.text('미리보기 열기'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('취소')),
    );
    await tester.pumpAndSettle();
    await opening;

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(PetCharacterGenerationScreen), findsNothing);
    expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
    for (final entry in values.entries) {
      await tester.ensureVisible(_field(entry.key));
      expect(
        tester.widget<TextFormField>(_field(entry.key)).controller!.text,
        entry.value,
      );
    }
    expect(tester.takeException(), isNull);
  });

  for (final exit in ['close', 'cancel', 'back']) {
    testWidgets('$exit 후 기존 등록 폼과 입력값을 보존한다', (tester) async {
      await _open(tester, home: const PetRegistrationScreen());
      final form = tester.element(find.byType(PetRegistrationScreen));
      final values = {
        'pet_name_field': '모모',
        'pet_morph_field': '직접 입력한 특징',
        'pet_feeding_cycle_field': '4',
        'pet_memo_field': '보존할 메모',
      };
      for (final entry in values.entries) {
        await tester.ensureVisible(_field(entry.key));
        await tester.enterText(_field(entry.key), entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('pet_gender_female'));
      await tester.pumpAndSettle();
      await tester.tap(_key('pet_gender_female'));
      await tester.pumpAndSettle();
      await _launchFromForm(tester);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('pet_generation_$exit'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PetCharacterGenerationScreen), findsNothing);
      expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
      for (final entry in values.entries) {
        await tester.ensureVisible(_field(entry.key));
        expect(
          tester.widget<TextFormField>(_field(entry.key)).controller!.text,
          entry.value,
        );
      }
      await tester.ensureVisible(_key('pet_gender_female'));
      expect(
        tester
            .getSemantics(_key('pet_gender_female'))
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('직접 실행한 루트에서도 $exit 시 로그인으로 나간다', (tester) async {
      await _open(tester);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('pet_generation_$exit'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PetCharacterGenerationScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '${size.width}×${size.height} 글자 $scale 배에서 스크롤·고정 버튼·잘림을 확인한다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          final cancel = tester.getRect(_key('pet_generation_cancel'));
          expect(cancel.bottom, closeTo(size.height - 34, 0.1));
          expect(cancel.width, size.width - 48);
          expect(cancel.height, greaterThanOrEqualTo(44));
          for (final key in [
            'pet_generation_progress',
            'pet_generation_copy',
            'pet_generation_stages',
          ]) {
            await tester.ensureVisible(_key(key));
            await tester.pumpAndSettle();
            final rect = tester.getRect(_key(key));
            expect(rect.left, greaterThanOrEqualTo(24));
            expect(rect.right, lessThanOrEqualTo(size.width - 24));
            expect(tester.takeException(), isNull);
          }
          expect(tester.getRect(_key('pet_generation_cancel')), cancel);
          await tester.ensureVisible(find.text('캐릭터 생성'));
          expect(find.text('캐릭터 생성').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('큰 시스템 SafeArea도 헤더와 하단 버튼을 가리지 않는다', (tester) async {
    await _open(tester, top: 70, bottom: 48);
    expect(tester.getRect(_key('pet_generation_close')).top, 74);
    expect(tester.getRect(_key('pet_generation_cancel')).bottom, 796);
    expect(tester.takeException(), isNull);
  });

  testWidgets('독립 Debug 타깃은 안내 후 열리고 취소 후 등록 화면으로 돌아온다', (tester) async {
    await _open(
      tester,
      home: const preview.PetCharacterGenerationPreviewHost(),
    );
    expect(find.text('디자인 미리보기'), findsOneWidget);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(PetCharacterGenerationScreen), findsOneWidget);
    await tester.tap(_key('pet_generation_cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    expect(find.text('디자인 미리보기'), findsNothing);
  });

  testWidgets('일반 앱의 초기 로그인과 경로는 바뀌지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetCharacterGenerationScreen), findsNothing);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.routes?.keys.any((route) => route.contains('generation')),
      isFalse,
    );
  });
}
