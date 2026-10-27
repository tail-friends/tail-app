import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_photo_add_sheet.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_photo_add_preview.dart' as preview;

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _field(String key) =>
    find.descendant(of: _key(key), matching: find.byType(TextFormField));
Finder get _sheet => _key('pet_photo_add_sheet');
const _notice = '사진 선택 기능은 준비 중입니다. 실제 사진은 선택하거나 저장하지 않습니다.';

Future<void> _open(
  WidgetTester tester, {
  bool designPreview = true,
  Size size = const Size(390, 844),
  double scale = 1,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 34);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: designPreview
          ? const PetRegistrationScreen.photoAddPreview()
          : PetRegistrationScreen(
              datePicker: (_, _) async => DateTime(2024, 7, 12),
            ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  await tester.ensureVisible(_field(key));
  await tester.enterText(_field(key), value);
  await tester.pumpAndSettle();
}

Future<void> _fillForm(WidgetTester tester) async {
  await _enter(tester, 'pet_name_field', '모모');
  await tester.ensureVisible(_key('pet_species_field'));
  await tester.tap(
    find.descendant(
      of: _key('pet_species_field'),
      matching: find.byType(InkWell),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(_key('pet_species_search_field'), '레오파드 게코');
  await tester.pumpAndSettle();
  await tester.tap(_key('pet_species_option_레오파드 게코'));
  await tester.pumpAndSettle();
  await tester.tap(_key('pet_species_confirm_button'));
  await tester.pumpAndSettle();
  await _enter(tester, 'pet_morph_field', '내가 입력한 특징');
  await tester.ensureVisible(_key('pet_gender_female'));
  await tester.tap(_key('pet_gender_female'));
  await tester.ensureVisible(_key('pet_hatching_date_field'));
  await tester.tap(
    find.descendant(
      of: _key('pet_hatching_date_field'),
      matching: find.byType(InkWell),
    ),
  );
  await tester.pumpAndSettle();
  await _enter(tester, 'pet_feeding_cycle_field', '4');
  await _enter(tester, 'pet_memo_field', '닫아도 남아야 하는 메모');
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(_key('pet_registration_save_button'));
  await tester.tap(_key('pet_registration_save_button'));
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

  testWidgets('기존 등록 화면 위 실제 모달에 Figma 핵심 요소를 표시한다', (tester) async {
    await _open(tester);
    expect(find.byType(PetPhotoAddSheet), findsOneWidget);
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    for (final text in [
      '사진 추가',
      '캐릭터는 이 사진을 바탕으로 만들어져요',
      '카메라로 촬영',
      '앨범에서 선택',
      '잘 나오는 사진',
      '위에서 내려다본 전신이 보이게',
      '밝은 곳에서 그림자 없이',
      '배경은 단순할수록 좋아요',
      '취소',
    ]) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    final route =
        ModalRoute.of(tester.element(_sheet))! as ModalBottomSheetRoute<void>;
    expect(route.barrierColor, const Color(0x332F6B57));
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 원본 시트·카드·팁·취소 버튼 배치를 유지한다', (tester) async {
    await _open(tester);
    _expectRect(tester, _sheet, const Rect.fromLTWH(0, 394, 390, 450));
    _expectRect(
      tester,
      _key('pet_photo_grabber'),
      const Rect.fromLTWH(179, 405, 32, 4),
    );
    _expectRect(
      tester,
      _key('pet_photo_camera'),
      const Rect.fromLTWH(41, 495, 144, 81),
    );
    _expectRect(
      tester,
      _key('pet_photo_album'),
      const Rect.fromLTWH(205, 495, 144, 81),
    );
    _expectRect(
      tester,
      _key('pet_photo_tips'),
      const Rect.fromLTWH(25, 606, 340, 135),
    );
    _expectRect(
      tester,
      _key('pet_photo_cancel'),
      const Rect.fromLTWH(25, 761, 340, 48),
    );
    _expectRect(
      tester,
      find.descendant(
        of: _key('pet_photo_camera'),
        matching: find.byType(SvgPicture),
      ),
      const Rect.fromLTWH(102, 510, 22, 22),
    );
    _expectRect(
      tester,
      find.descendant(
        of: _key('pet_photo_album'),
        matching: find.byType(SvgPicture),
      ),
      const Rect.fromLTWH(266, 516, 22, 22),
    );
    final checks = find.descendant(
      of: _key('pet_photo_tips'),
      matching: find.byType(SvgPicture),
    );
    expect(checks, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      _expectRect(
        tester,
        checks.at(i),
        Rect.fromLTWH(42, 648.5 + i * 29, 16, 16),
      );
    }
    _expectRect(
      tester,
      find.descendant(
        of: _key('pet_photo_close'),
        matching: find.byType(SvgPicture),
      ),
      const Rect.fromLTWH(339, 439, 16, 16),
    );
  });

  for (final action in ['camera', 'album']) {
    testWidgets('$action 카드는 준비 중 안내만 표시하고 실제 사진·저장·진행 상태를 만들지 않는다', (
      tester,
    ) async {
      await _open(tester);
      final before = tester.element(_sheet);
      await tester.tap(_key('pet_photo_$action'));
      await tester.pumpAndSettle();
      expect(find.text(_notice), findsOneWidget);
      expect(find.text('사진 추가 미리보기'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('등록 완료'), findsNothing);
      expect(find.text('캐릭터 생성 중'), findsNothing);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(tester.element(_sheet), same(before));
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('카메라·앨범·닫기·취소 버튼은 최소 44×44이며 접근성 이름을 제공한다', (tester) async {
    await _open(tester);
    for (final key in [
      'pet_photo_camera',
      'pet_photo_album',
      'pet_photo_close',
      'pet_photo_cancel',
    ]) {
      final size = tester.getSize(_key(key));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(tester.getSemantics(_key(key)).label, isNotEmpty);
    }
    expect(tester.getSemantics(_key('pet_photo_camera')).label, '카메라로 촬영');
    expect(tester.getSemantics(_key('pet_photo_album')).label, '앨범에서 선택');
  });

  for (final dismiss in ['close', 'cancel', 'outside', 'back', 'drag']) {
    testWidgets('$dismiss 닫기 및 다시 열기 후 등록 폼의 실제 입력값을 모두 보존한다', (tester) async {
      await _open(tester, designPreview: false);
      await _fillForm(tester);
      final form = tester.element(find.byType(PetRegistrationScreen));
      await _save(tester);
      expect(_sheet, findsOneWidget);
      if (dismiss == 'close' || dismiss == 'cancel') {
        await tester.tap(_key('pet_photo_$dismiss'));
      } else if (dismiss == 'outside') {
        await tester.tapAt(const Offset(10, 120));
      } else if (dismiss == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.drag(_key('pet_photo_grabber'), const Offset(0, 450));
      }
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
      for (final (key, value) in [
        ('pet_name_field', '모모'),
        ('pet_morph_field', '내가 입력한 특징'),
        ('pet_feeding_cycle_field', '4'),
        ('pet_memo_field', '닫아도 남아야 하는 메모'),
      ]) {
        expect(
          tester.widget<TextFormField>(_field(key)).controller!.text,
          value,
        );
      }
      expect(find.text('레오파드 게코'), findsOneWidget);
      expect(find.text('2024.07.12'), findsOneWidget);
      expect(
        tester
            .getSemantics(_key('pet_gender_female'))
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      await _save(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text('등록 완료'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('필수 입력이 없으면 기존 오류와 저장 미연결 안내를 유지하고 시트는 열지 않는다', (tester) async {
    await _open(tester, designPreview: false);
    await _save(tester);
    expect(find.text('이름을 입력해 주세요.'), findsOneWidget);
    expect(find.text('종을 선택해 주세요.'), findsOneWidget);
    expect(find.text('급여 주기를 입력해 주세요.'), findsOneWidget);
    expect(find.text('저장 기능은 준비 중입니다.'), findsOneWidget);
    expect(_sheet, findsNothing);
  });

  for (final invalid in ['0', '999999999999999999999999999999']) {
    testWidgets('급여 주기 $invalid 입력은 사진 시트로 진행하지 않는다', (tester) async {
      await _open(tester, designPreview: false);
      await _fillForm(tester);
      await _enter(tester, 'pet_feeding_cycle_field', invalid);
      await _save(tester);
      expect(find.text('1 이상의 숫자를 입력해 주세요.'), findsOneWidget);
      expect(_sheet, findsNothing);
      expect(
        tester
            .widget<TextFormField>(_field('pet_feeding_cycle_field'))
            .controller!
            .text,
        invalid,
      );
    });
  }

  testWidgets('일반 등록은 샘플 없이 시작하고 앱 시작 화면은 로그인을 유지한다', (tester) async {
    await _open(tester, designPreview: false);
    expect(_sheet, findsNothing);
    expect(find.text('욱이'), findsNothing);
    expect(find.text('레오파드 게코'), findsNothing);
    for (final key in [
      'pet_name_field',
      'pet_morph_field',
      'pet_feeding_cycle_field',
      'pet_memo_field',
    ]) {
      expect(
        tester.widget<TextFormField>(_field(key)).controller!.text,
        isEmpty,
      );
    }
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetRegistrationScreen), findsNothing);
  });

  testWidgets('독립 Debug 진입점은 기존 등록 화면과 사진 시트만 연다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    preview.main();
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    expect(_sheet, findsOneWidget);
    expect(find.text('욱이'), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(360, 800), Size(320, 640)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale 배에서 카드·안내·취소 버튼을 스크롤로 확인한다', (tester) async {
        await _open(tester, size: size, scale: scale);
        expect(tester.takeException(), isNull);
        for (final key in [
          'pet_photo_camera',
          'pet_photo_album',
          'pet_photo_tip_0',
          'pet_photo_tip_1',
          'pet_photo_tip_2',
        ]) {
          await tester.ensureVisible(_key(key));
          await tester.pumpAndSettle();
          final rect = tester.getRect(_key(key));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(tester.takeException(), isNull);
        }
        expect(
          tester.getBottomRight(_key('pet_photo_cancel')).dy,
          lessThanOrEqualTo(size.height - 34),
        );
        await tester.tap(_key('pet_photo_cancel'));
        await tester.pumpAndSettle();
        expect(_sheet, findsNothing);
      });
    }
  }

  testWidgets('320×640 글자 2배·키보드 상태에서도 시트와 취소 버튼이 가려지지 않는다', (tester) async {
    await _open(tester, size: const Size(320, 640), scale: 2, keyboard: 250);
    for (final key in [
      'pet_photo_camera',
      'pet_photo_album',
      'pet_photo_tip_2',
    ]) {
      await tester.ensureVisible(_key(key));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(
      tester.getBottomRight(_key('pet_photo_cancel')).dy,
      lessThanOrEqualTo(390),
    );
    await tester.tap(_key('pet_photo_cancel'));
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
  });
}
