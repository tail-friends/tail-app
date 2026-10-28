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
import 'package:tail_friends/features/records/presentation/shedding_record_sheet.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _sheet => _key('shedding_record_sheet');
Finder get _memo => find.descendant(
  of: _key('shedding_memo'),
  matching: find.byType(TextFormField),
);
const _notice = 'UI 미리보기입니다. 실제 탈피 기록은 저장되지 않았습니다.';

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool designPreview = true,
  SheddingDateTimePicker? picker,
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
        builder: (_) => SheddingRecordSheet(
          designPreview: designPreview,
          onFeedingSelected: () {},
          dateTimePicker: picker,
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
    await tester.tap(_key('feeding_type_1'));
    await tester.pumpAndSettle();
  }
}

void _rect(WidgetTester tester, String key, Rect expected) {
  final rect = tester.getRect(_key(key));
  expect(rect.left, closeTo(expected.left, 1), reason: '$key left');
  expect(rect.top, closeTo(expected.top, 1), reason: '$key top');
  expect(rect.width, closeTo(expected.width, 1), reason: '$key width');
  expect(rect.height, closeTo(expected.height, 1), reason: '$key height');
}

bool _selected(WidgetTester tester, String key) =>
    tester.getSemantics(_key(key)).flagsCollection.isSelected ==
    ui.Tristate.isTrue;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('급여에서 탈피를 열고 Figma 기본 상태·로컬 예시만 표시한다', (tester) async {
    await _open(tester);
    expect(_sheet, findsOneWidget);
    expect(_key('feeding_record_sheet'), findsNothing);
    expect(_selected(tester, 'shedding_type_1'), isTrue);
    expect(_selected(tester, 'shedding_status_0'), isTrue);
    expect(_selected(tester, 'shedding_part_0'), isTrue);
    expect(_selected(tester, 'shedding_part_1'), isTrue);
    expect(_selected(tester, 'shedding_part_2'), isFalse);
    expect(find.text('욱이 · 10월 20일'), findsOneWidget);
    expect(find.text('10월 20일 오전 9:12'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_memo).controller!.text,
      '발가락 허물은 미온수로 불려서 제거',
    );
    final route =
        ModalRoute.of(tester.element(_sheet))! as ModalBottomSheetRoute<void>;
    expect(route.barrierColor, const Color(0x332F6B57));
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 원본 y284·560px 시트와 각 영역 배치를 유지한다', (tester) async {
    await _open(tester);
    _rect(
      tester,
      'shedding_record_sheet',
      const Rect.fromLTWH(0, 284, 390, 560),
    );
    _rect(tester, 'shedding_grabber', const Rect.fromLTWH(179, 295, 32, 4));
    _rect(tester, 'shedding_header', const Rect.fromLTWH(25, 315, 340, 44));
    _rect(
      tester,
      'shedding_record_types',
      const Rect.fromLTWH(25, 375, 340, 44),
    );
    _rect(
      tester,
      'shedding_type_1_surface',
      const Rect.fromLTWH(139, 379, 112, 36),
    );
    _rect(
      tester,
      'shedding_status_segment',
      const Rect.fromLTWH(25, 461, 340, 45),
    );
    _rect(
      tester,
      'shedding_part_0_surface',
      const Rect.fromLTWH(25, 548, 57, 32),
    );
    _rect(
      tester,
      'shedding_part_1_surface',
      const Rect.fromLTWH(90, 548, 59, 32),
    );
    _rect(
      tester,
      'shedding_part_2_surface',
      const Rect.fromLTWH(157, 548, 40, 32),
    );
    _rect(
      tester,
      'shedding_part_3_surface',
      const Rect.fromLTWH(205, 548, 50, 32),
    );
    _rect(
      tester,
      'shedding_date_surface',
      const Rect.fromLTWH(25, 600, 340, 49),
    );
    _rect(tester, 'shedding_memo', const Rect.fromLTWH(25, 669, 340, 72));
    _rect(tester, 'shedding_save', const Rect.fromLTWH(25, 761, 340, 48));
    final glass = tester.widget<AppGlassSurface>(_sheet);
    expect(glass.blur, 12);
    expect(
      glass.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(32)),
    );
  });

  testWidgets('상태 3종은 하나만 선택하고 남은 허물 영역은 원본처럼 계속 표시한다', (tester) async {
    await _open(tester);
    for (final selection in [1, 2, 0]) {
      await tester.tap(_key('shedding_status_$selection'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 3; index++) {
        expect(_selected(tester, 'shedding_status_$index'), index == selection);
      }
      expect(find.text('남은 허물 확인 (부분 탈피 시)'), findsOneWidget);
      expect(_selected(tester, 'shedding_part_0'), isTrue);
    }
  });

  testWidgets('부위 다중 선택·개별 해제·없음의 상호 배타성을 처리한다', (tester) async {
    await _open(tester);
    await tester.tap(_key('shedding_part_2'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 3; index++) {
      expect(_selected(tester, 'shedding_part_$index'), isTrue);
    }
    await tester.tap(_key('shedding_part_1'));
    await tester.pumpAndSettle();
    expect(_selected(tester, 'shedding_part_1'), isFalse);
    await tester.tap(_key('shedding_part_3'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index++) {
      expect(_selected(tester, 'shedding_part_$index'), index == 3);
    }
    await tester.tap(_key('shedding_part_0'));
    await tester.pumpAndSettle();
    expect(_selected(tester, 'shedding_part_3'), isFalse);
    expect(_selected(tester, 'shedding_part_0'), isTrue);
    await tester.tap(_key('shedding_part_0'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index++) {
      expect(_selected(tester, 'shedding_part_$index'), isFalse);
    }
  });

  testWidgets('급여↔탈피는 같은 모달·홈을 유지하고 양쪽 폼을 보존한다', (tester) async {
    await _open(tester);
    final home = tester.element(find.byType(HomeScreen));
    final route = ModalRoute.of(tester.element(_sheet));
    await tester.tap(_key('shedding_status_1'));
    await tester.enterText(_memo, '탈피 임시 메모');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('shedding_type_0'));
    await tester.pumpAndSettle();
    await tester.tap(_key('shedding_type_0'));
    await tester.pumpAndSettle();
    expect(
      ModalRoute.of(tester.element(_key('feeding_record_sheet'))),
      same(route),
    );
    expect(
      (route! as ModalBottomSheetRoute<void>).barrierColor,
      const Color(0x2E2F6B57),
    );
    await tester.tap(_key('feeding_increase'));
    await tester.tap(_key('feeding_food_2'));
    await tester.enterText(find.byType(TextFormField), '급여 임시 메모');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('feeding_type_1'));
    await tester.pumpAndSettle();
    await tester.tap(_key('feeding_type_1'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(_memo).controller!.text, '탈피 임시 메모');
    expect(_selected(tester, 'shedding_status_1'), isTrue);
    await tester.tap(_key('shedding_type_0'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '급여 임시 메모',
    );
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '6');
    expect(_selected(tester, 'feeding_food_2'), isTrue);
    expect(tester.element(find.byType(HomeScreen)), same(home));
  });

  testWidgets('체중은 준비 중 안내만 표시하고 탈피 입력을 유지한다', (tester) async {
    await _open(tester);
    await tester.tap(_key('shedding_type_2'));
    await tester.pumpAndSettle();
    expect(find.text('체중 기록 화면은 후속 구현 예정입니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(_selected(tester, 'shedding_type_1'), isTrue);
  });

  testWidgets('일반 호출은 현재 날짜·빈 메모·부위 미선택으로 시작한다', (tester) async {
    final today = DateTime.now();
    await _open(tester, designPreview: false);
    expect(find.text('탈피 기록 미리보기'), findsOneWidget);
    expect(find.text('욱이 · 10월 20일'), findsNothing);
    expect(tester.widget<TextFormField>(_memo).controller!.text, isEmpty);
    expect(
      tester.widget<Text>(_key('shedding_date_value')).data,
      startsWith('${today.month}월 ${today.day}일'),
    );
    for (var index = 0; index < 4; index++) {
      expect(_selected(tester, 'shedding_part_$index'), isFalse);
    }
  });

  for (final entry in [
    (DateTime(2025, 4, 3, 0, 5), '4월 3일 오전 12:05'),
    (DateTime(2025, 4, 3, 12, 9), '4월 3일 오후 12:09'),
  ]) {
    testWidgets('날짜 로컬 선택 ${entry.$2}와 오전·오후를 표시한다', (tester) async {
      await _open(
        tester,
        picker: (_, current) async {
          expect(current, DateTime(2024, 10, 20, 9, 12));
          return entry.$1;
        },
      );
      await tester.tap(_key('shedding_date'));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('욱이 · 4월 3일'), findsOneWidget);
    });
  }

  testWidgets('날짜 선택 취소는 기존 날짜와 메모를 보존한다', (tester) async {
    await _open(tester, picker: (_, _) async => null);
    await tester.enterText(_memo, '날짜 취소 후 유지');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(_key('shedding_date'));
    await tester.pumpAndSettle();
    expect(find.text('10월 20일 오전 9:12'), findsOneWidget);
    expect(tester.widget<TextFormField>(_memo).controller!.text, '날짜 취소 후 유지');
  });

  testWidgets('기본 날짜·시간 선택기를 사용하고 시간 취소 시 전체 변경을 취소한다', (tester) async {
    await _open(tester);
    await tester.tap(_key('shedding_date'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('10월 20일 오전 9:12'), findsOneWidget);
  });

  testWidgets('저장 안내만 표시하고 폼과 기존 홈 기록을 변경하지 않는다', (tester) async {
    await _open(tester);
    await tester.enterText(_memo, '오늘의 탈피 메모');
    await tester.tap(_key('shedding_save'));
    await tester.pumpAndSettle();
    expect(find.text(_notice), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(_memo).controller!.text, '오늘의 탈피 메모');
    expect(find.byType(AppRecordRow), findsNWidgets(2));
    expect(_sheet, findsOneWidget);
  });

  for (final method in ['X', '바깥 탭', '시스템 뒤로가기', '그랩버 드래그']) {
    testWidgets('$method 닫기는 같은 홈으로 돌아오며 실제 기록을 만들지 않는다', (tester) async {
      await _open(tester);
      final home = tester.element(find.byType(HomeScreen));
      if (method == 'X') await tester.tap(_key('shedding_close'));
      if (method == '바깥 탭') await tester.tapAt(const Offset(340, 80));
      if (method == '시스템 뒤로가기') await tester.binding.handlePopRoute();
      if (method == '그랩버 드래그') {
        await tester.drag(_key('shedding_grabber'), const Offset(0, 500));
      }
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(_key('feeding_record_sheet'), findsNothing);
      expect(tester.element(find.byType(HomeScreen)), same(home));
      expect(find.byType(AppRecordRow), findsNWidgets(2));
      expect(find.text('기능은 준비 중입니다.'), findsNothing);
    });
  }

  testWidgets('닫고 다시 열면 임시 탈피 입력이 저장되지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('shedding_status_2'));
    await tester.enterText(_memo, '저장되지 않을 메모');
    await tester.tap(_key('shedding_close'));
    await tester.pumpAndSettle();
    unawaited(
      showFeedingRecordSheet(
        tester.element(find.byType(HomeScreen)),
        designPreview: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_key('feeding_type_1'));
    await tester.pumpAndSettle();
    expect(_selected(tester, 'shedding_status_0'), isTrue);
    expect(
      tester.widget<TextFormField>(_memo).controller!.text,
      '발가락 허물은 미온수로 불려서 제거',
    );
  });

  testWidgets('터치 44px·선택 semantics·원본 아이콘 크기를 유지한다', (tester) async {
    await _open(tester);
    for (final key in [
      'shedding_close',
      'shedding_date',
      'shedding_save',
      for (var i = 0; i < 3; i++) 'shedding_type_$i',
      for (var i = 0; i < 3; i++) 'shedding_status_$i',
      for (var i = 0; i < 4; i++) 'shedding_part_$i',
    ]) {
      final size = tester.getSize(_key(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: key);
      expect(size.height, greaterThanOrEqualTo(44), reason: key);
    }
    final extents = find
        .descendant(of: _sheet, matching: find.byType(SvgPicture))
        .evaluate()
        .map((e) => tester.getSize(find.byWidget(e.widget)))
        .toList();
    expect(extents.where((size) => size == const Size(15, 15)).length, 3);
    expect(extents, contains(const Size(14, 14)));
    // Original root 24×24 is fitted into the Figma 16×16 close slot.
    expect(extents, contains(const Size(24, 24)));
  });

  for (final size in const [Size(390, 844), Size(360, 800), Size(320, 640)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale배에서 스크롤·입력·고정 저장 버튼에 접근한다', (tester) async {
        await _open(tester, size: size, scale: scale);
        final save = tester.getRect(_key('shedding_save'));
        expect(save.bottom, lessThanOrEqualTo(size.height - 34));
        expect(tester.getRect(_sheet).top, greaterThanOrEqualTo(54));
        for (final key in [
          'shedding_record_types',
          'shedding_status_choices',
          'shedding_part_3',
          'shedding_date',
          'shedding_memo',
        ]) {
          await tester.ensureVisible(_key(key));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: key);
          final rect = tester.getRect(_key(key));
          expect(rect.left, greaterThanOrEqualTo(25));
          expect(rect.right, lessThanOrEqualTo(size.width - 25));
          expect(tester.getRect(_key('shedding_save')), save);
        }
        await tester.enterText(_memo, '큰 글자 메모');
        await tester.tap(_key('shedding_save'));
        await tester.pumpAndSettle();
        expect(find.text(_notice), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('320×640·200%·키보드에서도 메모와 저장 버튼이 가려지지 않는다', (tester) async {
    await _open(tester, size: const Size(320, 640), scale: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_memo);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(_key('shedding_save')).bottom,
      lessThanOrEqualTo(390),
    );
    expect(
      tester.getRect(_memo).bottom,
      lessThanOrEqualTo(tester.getRect(_key('shedding_save')).top),
    );
    await tester.enterText(_memo, '키보드 메모');
    expect(tester.widget<TextFormField>(_memo).controller!.text, '키보드 메모');
    expect(tester.takeException(), isNull);
  });
}
