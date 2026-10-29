import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_character_ai_result_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_character_generation_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_character_ai_result_preview.dart' as preview;

Finder _key(String value) => find.byKey(ValueKey('pet_ai_result_$value'));
Finder _field(String value) => find.descendant(
  of: find.byKey(ValueKey(value)),
  matching: find.byType(TextFormField),
);

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetCharacterAiResultScreen(),
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 31,
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

bool _selected(WidgetTester tester, String key) =>
    tester.getSemantics(_key(key)).flagsCollection.isSelected ==
    ui.Tristate.isTrue;

void _rect(WidgetTester tester, String key, Rect expected) {
  final actual = tester.getRect(_key(key));
  expect(actual.left, closeTo(expected.left, 0.1));
  expect(actual.top, closeTo(expected.top, 0.1));
  expect(actual.width, closeTo(expected.width, 0.1));
  expect(actual.height, closeTo(expected.height, 0.1));
}

Future<void> _launchFromForm(WidgetTester tester) async {
  showPetCharacterAiResultPreview(
    tester.element(find.byType(PetRegistrationScreen)),
  );
  await tester.pumpAndSettle();
  expect(find.text('디자인 미리보기'), findsOneWidget);
  expect(find.byType(PetCharacterAiResultScreen), findsNothing);
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

  testWidgets('Figma 예시 문구와 Jua, 빈 캐릭터 영역 및 원본 색상 견본을 표시한다', (tester) async {
    await _open(tester);
    for (final text in [
      '캐릭터 만들기',
      'AI가 본 모습: 탠저린 레오파드 게코',
      '바꾸는 즉시 사육장 캐릭터에 반영돼요',
      '체형',
      '색',
      '저장',
      '다른 사진 고르기',
    ]) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    final empty = tester.widget<SizedBox>(_key('empty_character'));
    expect(empty.child, isNull);
    expect(empty.width, 60);
    expect(empty.height, 90);
    for (var i = 0; i < 4; i++) {
      final swatch = find.descendant(
        of: _key('color_$i'),
        matching: find.byType(SvgPicture),
      );
      expect(swatch, findsOneWidget);
      expect(tester.getSize(swatch), const Size(26, 26));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844 카드·패널·버튼은 Figma 좌표를 유지한다', (tester) async {
    await _open(tester);
    _rect(tester, 'close_surface', const Rect.fromLTWH(24, 62, 36, 36));
    _rect(tester, 'preview_card', const Rect.fromLTWH(24, 122, 342, 210));
    _rect(tester, 'customize', const Rect.fromLTWH(24, 386, 342, 297));
    _rect(tester, 'save', const Rect.fromLTWH(24, 705, 342, 50));
    _rect(tester, 'photo', const Rect.fromLTWH(24, 763, 342, 50));
  });

  testWidgets('체형 네 개를 단일 선택하고 무늬와 색은 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    for (var selected = 0; selected < 4; selected++) {
      await tester.tap(_key('body_$selected'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 4; index++) {
        expect(_selected(tester, 'body_$index'), index == selected);
      }
      expect(_selected(tester, 'pattern_0'), isTrue);
      expect(_selected(tester, 'color_0'), isTrue);
    }
    semantics.dispose();
  });

  testWidgets('무늬 네 개를 독립적으로 단일 선택한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await tester.tap(_key('body_3'));
    for (var selected = 0; selected < 4; selected++) {
      await tester.tap(_key('pattern_$selected'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 4; index++) {
        expect(_selected(tester, 'pattern_$index'), index == selected);
      }
      expect(_selected(tester, 'body_3'), isTrue);
      expect(_selected(tester, 'color_0'), isTrue);
    }
    semantics.dispose();
  });

  testWidgets('색 네 개는 선택 강조만 바꾸고 새 편집기나 캐릭터를 만들지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    for (var selected = 0; selected < 4; selected++) {
      await tester.tap(_key('color_$selected'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 4; index++) {
        expect(_selected(tester, 'color_$index'), index == selected);
      }
      expect(_selected(tester, 'body_0'), isTrue);
      expect(_selected(tester, 'pattern_0'), isTrue);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(tester.widget<SizedBox>(_key('empty_character')).child, isNull);
    }
    semantics.dispose();
  });

  testWidgets('저장과 다른 사진은 미연결 안내만 표시하고 화면·선택을 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await tester.tap(_key('body_1'));
    await tester.tap(_key('save'));
    await tester.pumpAndSettle();
    expect(find.text('디자인 미리보기입니다. 실제 캐릭터는 저장되지 않았습니다.'), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsOneWidget);
    expect(_selected(tester, 'body_1'), isTrue);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(_key('photo'));
    await tester.pumpAndSettle();
    expect(find.text('사진 선택 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsOneWidget);
    expect(_selected(tester, 'body_1'), isTrue);
    semantics.dispose();
  });

  testWidgets('분석 미실행 안내는 확인 전에 화면을 열지 않으며 취소가 가능하다', (tester) async {
    await _open(tester, home: const PetRegistrationScreen());
    final original = tester.element(find.byType(PetRegistrationScreen));
    await tester.enterText(_field('pet_name_field'), '모모');
    FocusManager.instance.primaryFocus?.unfocus();
    final opening = showPetCharacterAiResultPreview(original);
    await tester.pumpAndSettle();
    expect(find.textContaining('실제 사육장 데이터는 변경되지 않습니다.'), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsNothing);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await opening;
    expect(tester.element(find.byType(PetRegistrationScreen)), same(original));
    expect(
      tester.widget<TextFormField>(_field('pet_name_field')).controller!.text,
      '모모',
    );
  });

  for (final exit in ['close', 'back']) {
    testWidgets('$exit 후 기존 등록 폼과 이름·메모를 보존한다', (tester) async {
      await _open(tester, home: const PetRegistrationScreen());
      final form = tester.element(find.byType(PetRegistrationScreen));
      final values = {'pet_name_field': '모모', 'pet_memo_field': '보존할 메모'};
      for (final entry in values.entries) {
        await tester.ensureVisible(_field(entry.key));
        await tester.enterText(_field(entry.key), entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _launchFromForm(tester);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('close'));
      }
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
      expect(find.byType(PetCharacterAiResultScreen), findsNothing);
      for (final entry in values.entries) {
        await tester.ensureVisible(_field(entry.key));
        expect(
          tester.widget<TextFormField>(_field(entry.key)).controller!.text,
          entry.value,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('직접 연 루트의 $exit 동작도 로그인으로 복귀한다', (tester) async {
      await _open(tester);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('close'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PetCharacterAiResultScreen), findsNothing);
    });
  }

  testWidgets('미리보기를 닫고 다시 열면 로컬 선택만 초기화된다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, home: const PetRegistrationScreen());
    await _launchFromForm(tester);
    await tester.tap(_key('body_3'));
    await tester.tap(_key('pattern_2'));
    await tester.tap(_key('color_1'));
    await tester.tap(_key('save'));
    await tester.pumpAndSettle();
    await tester.tap(_key('close'));
    await tester.pumpAndSettle();
    await _launchFromForm(tester);
    for (final group in ['body', 'pattern', 'color']) {
      expect(_selected(tester, '${group}_0'), isTrue);
    }
    semantics.dispose();
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '${size.width}×${size.height} $scale 배에서 overflow 없이 모든 선택과 고정 버튼에 접근한다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          final save = tester.getRect(_key('save'));
          final photo = tester.getRect(_key('photo'));
          expect(photo.bottom, size.height - 31);
          expect(photo.top - save.bottom, 8);
          for (final group in ['body', 'pattern', 'color']) {
            for (var index = 0; index < 4; index++) {
              final control = _key('${group}_$index');
              await tester.ensureVisible(control);
              await tester.pumpAndSettle();
              final rect = tester.getRect(control);
              expect(rect.width, greaterThanOrEqualTo(44));
              expect(rect.height, greaterThanOrEqualTo(44));
              expect(rect.left, greaterThanOrEqualTo(24));
              expect(rect.right, lessThanOrEqualTo(size.width - 24));
              expect(control.hitTestable(), findsOneWidget);
              await tester.tap(control);
              await tester.pumpAndSettle();
              expect(_selected(tester, '${group}_$index'), isTrue);
              expect(tester.takeException(), isNull);
            }
          }
          expect(tester.getRect(_key('save')), save);
          expect(tester.getRect(_key('photo')), photo);
          expect(_key('save').hitTestable(), findsOneWidget);
          expect(_key('photo').hitTestable(), findsOneWidget);
          expect(tester.getSize(_key('close')), const Size(44, 44));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('큰 SafeArea 안에 헤더와 하단 버튼을 유지한다', (tester) async {
    await _open(tester, top: 70, bottom: 48);
    expect(tester.getRect(_key('close')).top, 74);
    expect(tester.getRect(_key('photo')).bottom, 796);
    expect(tester.takeException(), isNull);
  });

  testWidgets('독립 Debug 타깃은 안내 확인 후 열리고 닫으면 등록 화면으로 돌아온다', (tester) async {
    await _open(tester, home: const preview.PetCharacterAiResultPreviewHost());
    expect(find.text('디자인 미리보기'), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsNothing);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(PetCharacterAiResultScreen), findsOneWidget);
    await tester.tap(_key('close'));
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
  });

  testWidgets('일반 앱의 초기 로그인과 라우트에 AI 결과 화면을 추가하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsNothing);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.routes?.keys.any((route) => route.contains('ai-result')),
      isFalse,
    );
  });

  testWidgets('기존 03-2 화면은 시간이 지나도 결과 화면으로 이동하지 않는다', (tester) async {
    await _open(tester, home: const PetCharacterGenerationScreen());
    await tester.pump(const Duration(minutes: 5));
    expect(find.byType(PetCharacterGenerationScreen), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsNothing);
    expect(find.text('68%'), findsOneWidget);
  });
}
