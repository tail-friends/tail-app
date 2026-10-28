import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/records/presentation/feeding_record_preview_screen.dart';
import 'package:tail_friends/features/records/presentation/feeding_record_sheet.dart';
import 'package:tail_friends/features/records/presentation/record_sheet_controls.dart';
import 'package:tail_friends/features/records/presentation/weight_record_sheet.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _sheet => _key('weight_record_sheet');
const _notice = 'UI 미리보기입니다. 실제 체중 기록은 저장되지 않았습니다.';
const _comparison = '지난 측정보다 +1.4g · 10월 13일 52.0g';
String _value(WidgetTester tester) =>
    tester.widget<Text>(_key('weight_value')).data!;

Future<void> _open(
  WidgetTester tester, {
  bool designPreview = true,
  Size size = const Size(390, 844),
  double scale = 1,
  RecordDateTimePicker? picker,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 34);
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
      home: designPreview && picker == null
          ? const FeedingRecordPreviewScreen()
          : const HomeScreen(),
    ),
  );
  await tester.pumpAndSettle();
  if (picker != null) {
    unawaited(
      showModalBottomSheet<void>(
        context: tester.element(find.byType(HomeScreen)),
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => WeightRecordSheet(
          designPreview: designPreview,
          dateTimePicker: picker,
          onRecordTypeSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  } else {
    if (!designPreview) {
      unawaited(
        showFeedingRecordSheet(tester.element(find.byType(HomeScreen))),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(_key('feeding_type_2'));
    await tester.pumpAndSettle();
  }
}

Future<void> _press(WidgetTester tester, String key) async {
  final index = key == '.'
      ? 9
      : key == '⌫'
      ? 11
      : key == '0'
      ? 10
      : int.parse(key) - 1;
  await tester.ensureVisible(_key('weight_key_$index'));
  await tester.pumpAndSettle();
  await tester.tap(_key('weight_key_$index'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  for (final key in text.split('')) {
    await _press(tester, key);
  }
}

void _rect(WidgetTester tester, String key, Rect expected) {
  final rect = tester.getRect(_key(key));
  expect(rect.left, closeTo(expected.left, 1), reason: '$key left');
  expect(rect.top, closeTo(expected.top, 1), reason: '$key top');
  expect(rect.width, closeTo(expected.width, 1), reason: '$key width');
  expect(rect.height, closeTo(expected.height, 1), reason: '$key height');
}

List<String?> _homeTexts() => find
    .descendant(of: find.byType(HomeScreen), matching: find.byType(Text))
    .evaluate()
    .map((e) => (e.widget as Text).data)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('급여에서 같은 모달의 체중 탭으로 이동하고 Debug 시안만 표시한다', (tester) async {
    await _open(tester);
    expect(_sheet, findsOneWidget);
    expect(_key('feeding_record_sheet'), findsNothing);
    expect(_value(tester), '53.4');
    expect(find.text(_comparison), findsOneWidget);
    expect(find.text('욱이 · 10월 20일'), findsOneWidget);
    expect(find.text('10월 20일 오전 9:12'), findsOneWidget);
    expect(
      tester.getSemantics(_key('weight_type_2')).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(
      (ModalRoute.of(tester.element(_sheet)) as ModalBottomSheetRoute<void>)
          .barrierColor,
      const Color(0x332F6B57),
    );
  });

  testWidgets('390×844의 시트 y173·671과 원본 카드·키패드·날짜·저장 배치를 유지한다', (tester) async {
    await _open(tester);
    _rect(tester, 'weight_record_sheet', const Rect.fromLTWH(0, 173, 390, 671));
    _rect(tester, 'weight_grabber', const Rect.fromLTWH(179, 184, 32, 4));
    _rect(tester, 'weight_header', const Rect.fromLTWH(25, 204, 340, 44));
    _rect(tester, 'weight_record_types', const Rect.fromLTWH(25, 264, 340, 44));
    _rect(
      tester,
      'weight_type_2_surface',
      const Rect.fromLTWH(249, 268, 112, 36),
    );
    _rect(tester, 'weight_display', const Rect.fromLTWH(25, 328, 340, 98));
    _rect(tester, 'weight_keypad', const Rect.fromLTWH(25, 446, 340, 226));
    for (var index = 0; index < 12; index++) {
      _rect(
        tester,
        'weight_key_$index',
        Rect.fromLTWH(
          25 + (index % 3) * (340 / 3 + 2),
          446 + (index ~/ 3) * 58,
          (340 - 12) / 3,
          52,
        ),
      );
    }
    _rect(tester, 'weight_date_surface', const Rect.fromLTWH(25, 692, 340, 49));
    _rect(tester, 'weight_save', const Rect.fromLTWH(25, 761, 340, 48));
    final glass = tester.widget<AppGlassSurface>(_sheet);
    expect(glass.blur, 12);
    expect(
      glass.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(32)),
    );
    final number = tester.widget<Text>(_key('weight_value'));
    expect(number.style!.fontFamily, 'Jua');
    expect(number.style!.fontSize, 40);
    expect(number.style!.letterSpacing, -1.2);
    expect(
      tester.getRect(_key('weight_unit')).top -
          tester.getRect(_key('weight_value')).top,
      closeTo(23, 0.1),
    );
  });

  testWidgets('일반 호출은 빈 입력·현재 시각이며 가짜 체중이나 이전 비교가 없다', (tester) async {
    final today = DateTime.now();
    await _open(tester, designPreview: false);
    expect(_value(tester), '—');
    expect(find.text(_comparison), findsNothing);
    expect(find.text('체중을 입력해 주세요'), findsOneWidget);
    expect(find.text('욱이 · 10월 20일'), findsNothing);
    expect(
      tester.widget<Text>(_key('weight_date_value')).data,
      startsWith('${today.month}월 ${today.day}일'),
    );
  });

  testWidgets('0부터 9까지 키를 입력하고 문자열 값 그대로 표시한다', (tester) async {
    await _open(tester, designPreview: false);
    await _type(tester, '1234567890');
    expect(_value(tester), '1234567890');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('빈 값의 소수점은 0.으로 시작하며 중복 소수점을 무시한다', (tester) async {
    await _open(tester, designPreview: false);
    await _type(tester, '.12..30');
    expect(_value(tester), '0.1230');
  });

  testWidgets('선행 0을 정리하면서 소수부 0과 미완성 소수점을 보존한다', (tester) async {
    await _open(tester, designPreview: false);
    await _type(tester, '000');
    expect(_value(tester), '0');
    await _type(tester, '7.');
    expect(_value(tester), '7.');
    await _type(tester, '00010');
    expect(_value(tester), '7.00010');
  });

  testWidgets('빈 지우기·숫자와 소수점 삭제를 안전하게 처리한다', (tester) async {
    await _open(tester, designPreview: false);
    await _press(tester, '⌫');
    expect(_value(tester), '—');
    await _type(tester, '12.3');
    for (final expected in ['12.', '12', '1', '—', '—']) {
      await _press(tester, '⌫');
      expect(_value(tester), expected);
    }
  });

  testWidgets('큰 정수와 긴 소수부를 반올림하거나 제한하지 않는다', (tester) async {
    await _open(tester, designPreview: false);
    const input = '9007199254740993.000000000000000001';
    await _type(tester, input);
    expect(_value(tester), input);
    await tester.ensureVisible(_key('weight_display'));
    await tester.pumpAndSettle();
    expect(find.text('g').hitTestable(), findsOneWidget);
    await tester.drag(_key('weight_number_scroll'), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(_value(tester), input);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Debug 입력 수정 시 고정 비교 예시를 계산 결과로 남기지 않는다', (tester) async {
    await _open(tester);
    await _press(tester, '5');
    expect(_value(tester), '53.45');
    expect(find.text(_comparison), findsNothing);
  });

  testWidgets('세 탭의 로컬 폼과 동일한 홈·모달을 보존한다', (tester) async {
    await _open(tester);
    final home = tester.element(find.byType(HomeScreen));
    final route = ModalRoute.of(tester.element(_sheet));
    await _press(tester, '8');
    await tester.tap(_key('weight_type_0'));
    await tester.pumpAndSettle();
    await tester.tap(_key('feeding_increase'));
    await tester.tap(_key('feeding_food_2'));
    await tester.enterText(find.byType(TextFormField), '급여 메모 유지');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('feeding_type_1'));
    await tester.pumpAndSettle();
    await tester.tap(_key('feeding_type_1'));
    await tester.pumpAndSettle();
    await tester.tap(_key('shedding_status_1'));
    await tester.tap(_key('shedding_part_2'));
    await tester.enterText(find.byType(TextFormField), '탈피 메모 유지');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('shedding_type_2'));
    await tester.pumpAndSettle();
    await tester.tap(_key('shedding_type_2'));
    await tester.pumpAndSettle();
    expect(_value(tester), '53.48');
    expect(ModalRoute.of(tester.element(_sheet)), same(route));
    await tester.tap(_key('weight_type_1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '탈피 메모 유지',
    );
    expect(
      tester.getSemantics(_key('shedding_status_1')).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(
      tester.getSemantics(_key('shedding_part_2')).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    await tester.tap(_key('shedding_type_0'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '급여 메모 유지',
    );
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '6');
    expect(
      tester.getSemantics(_key('feeding_food_2')).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(tester.element(find.byType(HomeScreen)), same(home));
  });

  for (final type in [0, 1]) {
    testWidgets('체중에서 $type 탭 복귀 후 보이지 않는 체중 영역이 바깥 터치를 막지 않는다', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(_key('weight_type_$type'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 230));
      await tester.pumpAndSettle();
      expect(find.byType(FeedingRecordSheet), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }

  for (final result in [DateTime(2025, 2, 3, 0, 5), null]) {
    testWidgets('측정 시각 로컬 ${result == null ? '취소' : '변경'}는 입력을 유지한다', (
      tester,
    ) async {
      await _open(
        tester,
        picker: (_, current) async {
          expect(current, DateTime(2024, 10, 20, 9, 12));
          return result;
        },
      );
      await _press(tester, '7');
      await tester.tap(_key('weight_date'));
      await tester.pumpAndSettle();
      expect(
        find.text(result == null ? '10월 20일 오전 9:12' : '2월 3일 오전 12:05'),
        findsOneWidget,
      );
      expect(_value(tester), '53.47');
    });
  }

  testWidgets('측정 시각 기본 날짜 선택 후 시간 취소는 날짜까지 변경하지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('weight_date'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('10월 20일 오전 9:12'), findsOneWidget);
  });

  testWidgets('저장은 안내만 표시하고 현재 입력·홈 체중·이전 기록을 변경하지 않는다', (tester) async {
    await _open(tester);
    final before = _homeTexts();
    await _press(tester, '9');
    await tester.tap(_key('weight_save'));
    await tester.pumpAndSettle();
    expect(find.text(_notice), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(_value(tester), '53.49');
    expect(_homeTexts(), before);
    expect(find.byType(AppRecordRow), findsNWidgets(2));
    expect(_sheet, findsOneWidget);
  });

  for (final method in ['X', '바깥 탭', '시스템 뒤로가기', '그랩버 드래그']) {
    testWidgets('$method 닫기는 같은 홈으로 복귀한다', (tester) async {
      await _open(tester);
      final home = tester.element(find.byType(HomeScreen));
      if (method == 'X') await tester.tap(_key('weight_close'));
      if (method == '바깥 탭') await tester.tapAt(const Offset(340, 80));
      if (method == '시스템 뒤로가기') await tester.binding.handlePopRoute();
      if (method == '그랩버 드래그') {
        await tester.drag(_key('weight_grabber'), const Offset(0, 700));
      }
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(tester.element(find.byType(HomeScreen)), same(home));
      expect(find.text('기능은 준비 중입니다.'), findsNothing);
    });
  }

  for (final preview in [true, false]) {
    testWidgets('모달 재진입 시 입력은 ${preview ? 'Debug 예시' : '빈 값'}으로 초기화한다', (
      tester,
    ) async {
      await _open(tester, designPreview: preview);
      await _press(tester, '9');
      await tester.tap(_key('weight_close'));
      await tester.pumpAndSettle();
      unawaited(
        showFeedingRecordSheet(
          tester.element(find.byType(HomeScreen)),
          designPreview: preview,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_key('feeding_type_2'));
      await tester.pumpAndSettle();
      expect(_value(tester), preview ? '53.4' : '—');
    });
  }

  testWidgets('12개 키의 터치 영역과 숫자·단위·소수점·지우기 접근성 및 SVG 슬롯을 검증한다', (tester) async {
    await _open(tester);
    for (final key in [
      'weight_close',
      'weight_date',
      'weight_save',
      for (var i = 0; i < 12; i++) 'weight_key_$i',
    ]) {
      final size = tester.getSize(_key(key));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    expect(find.bySemanticsLabel('체중, 단위 그램(g)'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('체중, 단위 그램(g)')).value,
      '53.4',
    );
    expect(find.bySemanticsLabel('소수점'), findsOneWidget);
    expect(find.bySemanticsLabel('마지막 숫자 지우기'), findsOneWidget);
    final icons = find
        .descendant(of: _sheet, matching: find.byType(SvgPicture))
        .evaluate()
        .map((e) => find.byWidget(e.widget))
        .toList();
    final sizes = icons
        .map((f) => tester.getBottomRight(f) - tester.getTopLeft(f))
        .toList();
    expect(sizes.where((s) => s == const Offset(15, 15)).length, 3);
    expect(sizes, contains(const Offset(14, 14)));
    expect(sizes, contains(const Offset(16, 16)));
  });

  for (final size in const [Size(390, 844), Size(360, 800), Size(320, 640)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale배에서 키패드·날짜 스크롤과 고정 저장 버튼에 접근한다', (
        tester,
      ) async {
        await _open(tester, size: size, scale: scale);
        final save = tester.getRect(_key('weight_save'));
        expect(save.bottom, lessThanOrEqualTo(size.height - 34));
        expect(tester.getRect(_sheet).top, greaterThanOrEqualTo(54));
        for (final key in [
          'weight_record_types',
          'weight_display',
          'weight_key_11',
          'weight_date',
        ]) {
          await tester.ensureVisible(_key(key));
          await tester.pumpAndSettle();
          final rect = tester.getRect(_key(key));
          expect(rect.left, greaterThanOrEqualTo(25));
          expect(rect.right, lessThanOrEqualTo(size.width - 25));
          expect(tester.getRect(_key('weight_save')), save);
          expect(tester.takeException(), isNull, reason: key);
        }
        await _press(tester, '0');
        await tester.tap(_key('weight_save'));
        await tester.pumpAndSettle();
        expect(find.text(_notice), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
