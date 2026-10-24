import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';

void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(
  PetRegistrationScreen screen, {
  double textScale = 1,
  double bottomInset = 0,
}) {
  return MaterialApp(
    theme: AppTheme.mist,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: bottomInset),
        ),
        child: screen,
      ),
    ),
  );
}

Finder _textField(String key) {
  return find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextFormField),
  );
}

void main() {
  testWidgets('Figma 기준 등록 화면의 핵심 요소와 크기를 표시한다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    expect(find.text('새 친구 등록'), findsOneWidget);
    expect(find.text('이름'), findsOneWidget);
    expect(find.text('종'), findsOneWidget);
    expect(find.text('모프 / 특징'), findsOneWidget);
    expect(find.text('성별'), findsOneWidget);
    expect(find.text('해칭일'), findsOneWidget);
    expect(find.text('급여 주기'), findsOneWidget);
    expect(find.text('메모'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const ValueKey('pet_registration_background'))),
      const Size(390, 844),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('pet_registration_navigation_bar')),
      ),
      const Size(342, 44),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('pet_registration_back_button')),
      ),
      const Size(44, 44),
    );
  });

  testWidgets('이름과 메모를 입력하면 글자 수를 실시간으로 표시하고 최대 길이를 제한한다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    await tester.enterText(_textField('pet_name_field'), '1234567890' * 4);
    await tester.pump();
    expect(find.text('30/30'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(_textField('pet_name_field'))
          .controller!
          .text,
      hasLength(30),
    );

    await tester.enterText(_textField('pet_memo_field'), '메' * 305);
    await tester.pump();
    expect(find.text('300/300'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(_textField('pet_memo_field'))
          .controller!
          .text,
      hasLength(300),
    );
  });

  testWidgets('성별 선택을 변경하면 선택 상태가 갱신된다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    final female = find.byKey(const ValueKey('pet_gender_female'));
    await tester.tap(female);
    await tester.pump();

    expect(
      tester.getSemantics(female).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('pet_gender_unspecified')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isFalse,
    );
  });

  testWidgets('해칭일을 선택하면 날짜를 표시하고 취소하면 기존 값을 유지한다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    var pickCount = 0;
    await tester.pumpWidget(
      _host(
        PetRegistrationScreen(
          datePicker: (_, currentDate) async {
            pickCount++;
            return pickCount == 1 ? DateTime(2024, 7, 12) : null;
          },
        ),
      ),
    );

    final dateField = find.byKey(const ValueKey('pet_hatching_date_field'));
    await tester.tap(
      find.descendant(of: dateField, matching: find.byType(InkWell)),
    );
    await tester.pump();
    expect(find.text('2024.07.12'), findsOneWidget);

    await tester.tap(
      find.descendant(of: dateField, matching: find.byType(InkWell)),
    );
    await tester.pump();
    expect(find.text('2024.07.12'), findsOneWidget);
  });

  testWidgets('급여 주기에는 숫자만 입력된다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    final feedingField = _textField('pet_feeding_cycle_field');
    await tester.enterText(feedingField, '12ab3');
    await tester.pump();

    expect(tester.widget<TextFormField>(feedingField).controller!.text, '123');
    expect(find.text('일'), findsOneWidget);
  });

  testWidgets('종 선택과 저장은 준비 중 안내를 표시하고 필수 입력을 안내한다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    final speciesField = find.byKey(const ValueKey('pet_species_field'));
    await tester.tap(
      find.descendant(of: speciesField, matching: find.byType(InkWell)),
    );
    await tester.pump();
    expect(find.text('종 선택 기능은 준비 중입니다.'), findsOneWidget);

    final saveButton = find.byKey(
      const ValueKey('pet_registration_save_button'),
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('이름을 입력해 주세요.'), findsOneWidget);
    expect(find.text('종을 선택해 주세요.'), findsOneWidget);
    expect(find.text('급여 주기를 입력해 주세요.'), findsOneWidget);
    expect(find.text('저장 기능은 준비 중입니다.'), findsOneWidget);
  });

  testWidgets('저장을 시도해도 입력 중인 내용을 삭제하지 않는다', (tester) async {
    _setViewSize(tester, const Size(390, 974));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    await tester.enterText(_textField('pet_name_field'), '꾸미');
    await tester.enterText(_textField('pet_memo_field'), '입력 중인 메모');
    await tester.tap(
      find.byKey(const ValueKey('pet_registration_save_button')),
    );
    await tester.pump();

    expect(
      tester
          .widget<TextFormField>(_textField('pet_name_field'))
          .controller!
          .text,
      '꾸미',
    );
    expect(
      tester
          .widget<TextFormField>(_textField('pet_memo_field'))
          .controller!
          .text,
      '입력 중인 메모',
    );
  });

  testWidgets('키보드가 나타나면 하단 저장 버튼이 키보드 위에 유지된다', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _host(const PetRegistrationScreen(), bottomInset: 300),
    );

    final saveButton = find.byKey(
      const ValueKey('pet_registration_save_button'),
    );
    expect(tester.getBottomRight(saveButton).dy, lessThanOrEqualTo(544));
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 Android 화면에서 모든 필드와 저장 버튼으로 스크롤할 수 있다', (tester) async {
    _setViewSize(tester, const Size(320, 640));
    await tester.pumpWidget(_host(const PetRegistrationScreen()));

    for (final key in const [
      'pet_name_field',
      'pet_species_field',
      'pet_morph_field',
      'pet_hatching_date_field',
      'pet_feeding_cycle_field',
      'pet_memo_field',
      'pet_registration_save_button',
    ]) {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.pump();
      expect(target, findsOneWidget);
      expect(tester.takeException(), isNull, reason: key);
    }
  });

  testWidgets('텍스트를 150%와 200%로 확대해도 overflow가 발생하지 않는다', (tester) async {
    _setViewSize(tester, const Size(320, 640));

    for (final textScale in const [1.5, 2.0]) {
      await tester.pumpWidget(
        _host(const PetRegistrationScreen(), textScale: textScale),
      );
      await tester.pump();

      for (final key in const [
        'pet_name_field',
        'pet_species_field',
        'pet_morph_field',
        'pet_hatching_date_field',
        'pet_feeding_cycle_field',
        'pet_memo_field',
        'pet_registration_footer_message',
        'pet_registration_save_button',
      ]) {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$textScale $key');
      }
    }
  });
}
