import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_hatching_date_sheet.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';

Finder _key(String value) => find.byKey(ValueKey('pet_hatching_$value'));

Future<void> _open(
  WidgetTester tester, {
  HatchingDateSelection? initial = const HatchingDateSelection(
    year: 2024,
    month: 7,
    day: 12,
  ),
  DateTime? today,
  Size size = const Size(390, 844),
  double scale = 1,
  double bottom = 34,
  ValueChanged<HatchingDateSelection?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: 54, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: 54, bottom: bottom);
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await showPetHatchingDateSheet(
                  context: context,
                  initialValue: initial,
                  today: today ?? DateTime(2026, 10, 29),
                );
                onResult?.call(result);
              },
              child: const Text('날짜 열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('날짜 열기'));
  await tester.pumpAndSettle();
}

String _value(WidgetTester tester, String wheel) =>
    tester.getSemantics(_key('${wheel}_wheel')).value;

Future<void> _adjust(
  WidgetTester tester,
  String wheel, {
  bool increase = true,
  int count = 1,
}) async {
  for (var index = 0; index < count; index++) {
    final node = tester.getSemantics(_key('${wheel}_wheel'));
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      node.id,
      increase ? ui.SemanticsAction.increase : ui.SemanticsAction.decrease,
    );
    await tester.pumpAndSettle();
  }
}

void _rect(WidgetTester tester, String key, Rect expected) {
  final actual = tester.getRect(_key(key));
  expect(actual.left, closeTo(expected.left, 0.1));
  expect(actual.top, closeTo(expected.top, 0.1));
  expect(actual.width, closeTo(expected.width, 0.1));
  expect(actual.height, closeTo(expected.height, 0.1));
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late SemanticsHandle semantics;
  setUp(() => semantics = binding.ensureSemantics());
  tearDown(() => semantics.dispose());
  setUpAll(() async {
    final loader = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await loader.load();
  });

  test('월 단위 UI 값은 일자와 DateTime을 생성하지 않는다', () {
    const date = HatchingDateSelection(year: 2024, month: 7);
    expect(date.day, isNull);
    expect(date.exactDate, isNull);
    expect(date.label, '2024.07 (일자 미상)');
    final exact = HatchingDateSelection.fromDate(DateTime(2024, 7, 12, 16, 42));
    expect(exact.label, '2024.07.12');
    expect(exact.exactDate, DateTime(2024, 7, 12));
  });

  testWidgets('Figma 문구·Jua·원본 SVG와 390×844 시트·휠·버튼 좌표', (tester) async {
    await _open(tester);
    for (final text in ['해칭일', '정확하지 않아도 괜찮아요', '정확한 날짜를 몰라요 (월까지만)', '확인']) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    _rect(tester, 'date_sheet', const Rect.fromLTWH(0, 337, 390, 507));
    _rect(tester, 'grabber', const Rect.fromLTWH(179, 348, 32, 4));
    _rect(tester, 'picker', const Rect.fromLTWH(25, 428, 340, 275));
    _rect(tester, 'year_pill', const Rect.fromLTWH(54, 545, 110, 41));
    _rect(tester, 'month_pill', const Rect.fromLTWH(170, 545, 80, 41));
    _rect(tester, 'day_pill', const Rect.fromLTWH(256, 545, 80, 41));
    _rect(tester, 'confirm', const Rect.fromLTWH(25, 761, 340, 48));
    expect(
      tester.getSize(
        find.descendant(
          of: _key('month_only'),
          matching: find.byType(SvgPicture),
        ),
      ),
      const Size(18, 18),
    );
    expect(_value(tester, 'year'), '2024년');
    expect(_value(tester, 'month'), '7월');
    expect(_value(tester, 'day'), '12일');
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('연·월·일을 독립적으로 변경하고 확인해야만 결과를 반환한다', (tester) async {
    final results = <HatchingDateSelection?>[];
    await _open(tester, onResult: results.add);
    await _adjust(tester, 'year', increase: false);
    expect(_value(tester, 'month'), '7월');
    expect(_value(tester, 'day'), '12일');
    await _adjust(tester, 'month');
    await _adjust(tester, 'day');
    expect(_value(tester, 'year'), '2023년');
    expect(_value(tester, 'month'), '8월');
    expect(_value(tester, 'day'), '13일');
    expect(results, isEmpty);
    await tester.tap(_key('confirm'));
    await tester.pumpAndSettle();
    expect(results.single?.label, '2023.08.13');
    expect(_key('date_sheet'), findsNothing);
  });

  for (final wheel in ['year', 'month', 'day']) {
    testWidgets('$wheel 휠은 실제 드래그 후 중앙 항목으로 정렬된다', (tester) async {
      await _open(tester);
      final before = _value(tester, wheel);
      await tester.drag(_key('${wheel}_list'), const Offset(0, -78));
      await tester.pumpAndSettle();
      expect(_value(tester, wheel), isNot(before));
      final scroll = tester.widget<ListWheelScrollView>(
        find.descendant(
          of: _key('${wheel}_list'),
          matching: find.byType(ListWheelScrollView),
        ),
      );
      final controller = scroll.controller! as FixedExtentScrollController;
      expect(
        controller.offset,
        closeTo(controller.selectedItem * scroll.itemExtent, 1.0),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('휠 항목 탭은 해당 항목을 선택한다', (tester) async {
    await _open(tester);
    await tester.tapAt(
      tester.getCenter(_key('month_wheel')) + const Offset(0, 39),
    );
    await tester.pumpAndSettle();
    expect(_value(tester, 'month'), '8월');
    expect(_value(tester, 'day'), '12일');
  });

  for (final year in [1900, 2000, 2023, 2024]) {
    final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    testWidgets('$year년 1월31일→2월은 ${leap ? 29 : 28}일로 보정하고 3월에 복원한다', (
      tester,
    ) async {
      await _open(
        tester,
        initial: HatchingDateSelection(year: year, month: 1, day: 31),
      );
      await _adjust(tester, 'month');
      expect(_value(tester, 'day'), '${leap ? 29 : 28}일');
      await _adjust(tester, 'month');
      expect(_value(tester, 'day'), '31일');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('윤년 2월29일→평년은 28일, 돌아오면 29일로 복원한다', (tester) async {
    await _open(
      tester,
      initial: const HatchingDateSelection(year: 2024, month: 2, day: 29),
    );
    await _adjust(tester, 'year', increase: false);
    expect(_value(tester, 'day'), '28일');
    await _adjust(tester, 'year');
    expect(_value(tester, 'day'), '29일');
  });

  testWidgets('30일인 달로 변경하면 31일 선택을 방지한다', (tester) async {
    await _open(
      tester,
      initial: const HatchingDateSelection(year: 2024, month: 3, day: 31),
    );
    await _adjust(tester, 'month');
    expect(_value(tester, 'day'), '30일');
    expect(
      tester.widget<Semantics>(_key('day_wheel')).properties.onIncrease,
      isNull,
    );
  });

  testWidgets('현재 연도·월·오늘 이후는 선택할 수 없다', (tester) async {
    final today = DateTime(2026, 2, 14);
    await _open(
      tester,
      today: today,
      initial: const HatchingDateSelection(year: 2025, month: 12, day: 31),
    );
    await _adjust(tester, 'year');
    expect(_value(tester, 'year'), '2026년');
    expect(_value(tester, 'month'), '2월');
    expect(_value(tester, 'day'), '14일');
    for (final wheel in ['year', 'month', 'day']) {
      expect(
        tester.widget<Semantics>(_key('${wheel}_wheel')).properties.onIncrease,
        isNull,
      );
      await tester.fling(_key('${wheel}_list'), const Offset(0, -400), 1500);
      await tester.pumpAndSettle();
    }
    expect(_value(tester, 'day'), '14일');
    expect(_value(tester, 'month'), '2월');
    expect(tester.takeException(), isNull);
  });

  testWidgets('이전 선택이 없으면 실행 시점의 오늘을 사용한다', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final results = <HatchingDateSelection?>[];
    await _open(tester, initial: null, today: today, onResult: results.add);
    expect(_value(tester, 'year'), '${today.year}년');
    expect(_value(tester, 'month'), '${today.month}월');
    expect(_value(tester, 'day'), '${today.day}일');
    await tester.tap(_key('confirm'));
    await tester.pumpAndSettle();
    expect(results.single?.exactDate, today);
  });

  testWidgets('1900년 경계를 넘어가지 않는다', (tester) async {
    await _open(
      tester,
      initial: const HatchingDateSelection(year: 1900, month: 1, day: 1),
    );
    for (final wheel in ['year', 'month', 'day']) {
      expect(
        tester.widget<Semantics>(_key('${wheel}_wheel')).properties.onDecrease,
        isNull,
      );
    }
    await tester.fling(_key('year_list'), const Offset(0, 300), 1200);
    await tester.pumpAndSettle();
    expect(_value(tester, 'year'), '1900년');
  });

  testWidgets('월 단위는 일자 선택을 막고 null을 반환한다', (tester) async {
    final results = <HatchingDateSelection?>[];
    await _open(tester, onResult: results.add);
    await tester.tap(_key('month_only'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(_key('month_only')).flagsCollection.isChecked,
      ui.CheckedState.isTrue,
    );
    expect(_value(tester, 'day'), '일자 미상');
    expect(
      tester.widget<Semantics>(_key('day_wheel')).properties.enabled,
      isFalse,
    );
    expect(
      tester.widget<Semantics>(_key('day_wheel')).properties.onIncrease,
      isNull,
    );
    await tester.drag(_key('day_list'), const Offset(0, -78));
    await tester.pumpAndSettle();
    await _adjust(tester, 'month');
    await tester.tap(_key('confirm'));
    await tester.pumpAndSettle();
    expect(results.single?.year, 2024);
    expect(results.single?.month, 8);
    expect(results.single?.day, isNull);
    expect(results.single?.exactDate, isNull);
  });

  testWidgets('월 단위 해제 시 기존 일자를 복원하고 달력 범위를 지킨다', (tester) async {
    await _open(
      tester,
      initial: const HatchingDateSelection(year: 2024, month: 1, day: 31),
    );
    await tester.tap(_key('month_only'));
    await _adjust(tester, 'month');
    await tester.tap(_key('month_only'));
    await tester.pumpAndSettle();
    expect(_value(tester, 'day'), '29일');
    await _adjust(tester, 'month');
    expect(_value(tester, 'day'), '31일');
  });

  testWidgets('월 단위 값을 다시 열어도 일자를 만들지 않는다', (tester) async {
    final results = <HatchingDateSelection?>[];
    await _open(
      tester,
      initial: const HatchingDateSelection(year: 2024, month: 7),
      onResult: results.add,
    );
    expect(_value(tester, 'day'), '일자 미상');
    await tester.tap(_key('confirm'));
    await tester.pumpAndSettle();
    expect(results.single?.label, '2024.07 (일자 미상)');
  });

  for (final exit in ['close', 'outside', 'back', 'drag']) {
    testWidgets('$exit 취소 시 초안은 반환하지 않는다', (tester) async {
      final results = <HatchingDateSelection?>[];
      await _open(tester, onResult: results.add);
      await _adjust(tester, 'month');
      if (exit == 'close') {
        await tester.tap(_key('close'));
      } else if (exit == 'outside') {
        await tester.tapAt(const Offset(12, 150));
      } else if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.dragFrom(
          tester.getCenter(_key('grabber')),
          const Offset(0, 400),
        );
      }
      await tester.pumpAndSettle();
      expect(_key('date_sheet'), findsNothing);
      expect(results, [null]);
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale 배에서 휠·체크·고정 확인 버튼 접근과 overflow', (
        tester,
      ) async {
        await _open(tester, size: size, scale: scale);
        final confirm = tester.getRect(_key('confirm'));
        expect(confirm.bottom, closeTo(size.height - 35, 0.1));
        expect(confirm.height, greaterThanOrEqualTo(44));
        expect(tester.getSize(_key('close')), const Size(44, 44));
        for (final wheel in ['year', 'month', 'day']) {
          await tester.ensureVisible(_key('${wheel}_pill'));
          await tester.pumpAndSettle();
          final rect = tester.getRect(_key('${wheel}_wheel'));
          expect(rect.width, greaterThanOrEqualTo(44));
          expect(rect.left, greaterThanOrEqualTo(25));
          expect(rect.right, lessThanOrEqualTo(size.width - 25));
          await _adjust(tester, wheel, increase: false);
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(_key('month_only'));
        await tester.pumpAndSettle();
        await tester.tap(_key('month_only'));
        await tester.pumpAndSettle();
        expect(_value(tester, 'day'), '일자 미상');
        expect(tester.getRect(_key('confirm')), confirm);
        expect(_key('confirm').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('큰 시스템 하단 SafeArea를 확보한다', (tester) async {
    await _open(tester, bottom: 48);
    expect(tester.getRect(_key('confirm')).bottom, 796);
    await tester.ensureVisible(_key('month_only'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Debug 날짜 시안은 기존 등록 화면 위에 열리고 일반 로그인 진입은 유지된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.mist,
        home: const PetRegistrationScreen.hatchingDatePreview(),
      ),
    );
    await tester.pumpAndSettle();
    expect(_key('date_sheet'), findsOneWidget);
    expect(_value(tester, 'year'), '2024년');
    await tester.tap(_key('close'));
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(_key('date_sheet'), findsNothing);
  });
}
