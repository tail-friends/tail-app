import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/records/presentation/feeding_record_preview_screen.dart';
import 'package:tail_friends/features/records/presentation/feeding_record_sheet.dart';
import 'package:tail_friends/main.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _sheet => _key('feeding_record_sheet');
Finder get _memo => find.byType(TextFormField);
const _saveNotice = 'UI 미리보기입니다. 실제 기록은 저장되지 않았습니다.';

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
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
      home: const FeedingRecordPreviewScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reopen(WidgetTester tester) async {
  unawaited(
    showFeedingRecordSheet(
      tester.element(find.byType(HomeScreen)),
      designPreview: true,
    ),
  );
  await tester.pumpAndSettle();
}

void _expectRect(WidgetTester tester, Finder finder, Rect expected) {
  final actual = tester.getRect(finder);
  expect(actual.left, closeTo(expected.left, 1));
  expect(actual.top, closeTo(expected.top, 1));
  expect(actual.width, closeTo(expected.width, 1));
  expect(actual.height, closeTo(expected.height, 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('기존 HomeScreen.preview 위에 실제 모달과 Figma 초기 입력값을 표시한다', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ModalBarrier), findsWidgets);
    expect(find.text('기록 추가'), findsOneWidget);
    expect(find.text('욱이 · 10월 20일'), findsOneWidget);
    for (final label in ['귀뚜라미', '밀웜', '듀비아', '슈퍼웜', '안 먹음']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '5');
    expect(tester.widget<TextFormField>(_memo).controller!.text, '잘 받아먹음');
    final route =
        ModalRoute.of(tester.element(_sheet))! as ModalBottomSheetRoute<void>;
    expect(route.barrierColor, const Color(0x2E2F6B57));
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 시트 y293와 원본 그랩버·필드·버튼 배치를 유지한다', (tester) async {
    await _open(tester);
    _expectRect(tester, _sheet, const Rect.fromLTWH(0, 293, 390, 551));
    _expectRect(
      tester,
      _key('feeding_grabber'),
      const Rect.fromLTWH(179, 306, 32, 4),
    );
    _expectRect(
      tester,
      _key('feeding_header'),
      const Rect.fromLTWH(25, 326, 340, 44),
    );
    _expectRect(
      tester,
      _key('feeding_record_types'),
      const Rect.fromLTWH(25, 386, 340, 44),
    );
    _expectRect(
      tester,
      _key('feeding_food_0_surface'),
      const Rect.fromLTWH(25, 472, 65, 30),
    );
    _expectRect(
      tester,
      _key('feeding_quantity'),
      const Rect.fromLTWH(25, 522, 340, 48),
    );
    _expectRect(
      tester,
      _key('feeding_not_eaten_surface'),
      const Rect.fromLTWH(25, 590, 340, 59),
    );
    _expectRect(
      tester,
      _key('feeding_memo'),
      const Rect.fromLTWH(25, 669, 340, 72),
    );
    _expectRect(
      tester,
      _key('feeding_save'),
      const Rect.fromLTWH(25, 761, 340, 48),
    );
    final glass = tester.widget<AppGlassSurface>(_sheet);
    expect(glass.blur, 18);
    expect(
      glass.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(32)),
    );
    expect(glass.gradient, AppColors.glassStrongGradient);
    final save = tester.widget<AppButton>(_key('feeding_save'));
    expect(save.backgroundColor, const Color(0xFF2F6B57));
    expect(save.foregroundColor, Colors.white);
    final memo = tester.widget<TextField>(
      find.descendant(of: _memo, matching: find.byType(TextField)),
    );
    expect(memo.style!.fontFamily, 'Jua');
    expect(memo.style!.fontSize, 13);
  });

  testWidgets('선택 칩과 작은 원형 버튼은 외형을 유지하며 44px 터치 영역을 제공한다', (tester) async {
    await _open(tester);
    for (final key in [
      'feeding_close',
      'feeding_decrease',
      'feeding_increase',
      for (var i = 0; i < 4; i++) 'feeding_food_$i',
      for (var i = 0; i < 3; i++) 'feeding_type_$i',
    ]) {
      final size = tester.getSize(_key(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: key);
      expect(size.height, greaterThanOrEqualTo(44), reason: key);
    }
    final icons = find.descendant(
      of: _sheet,
      matching: find.byType(SvgPicture),
    );
    final extents = icons
        .evaluate()
        .map(
          (e) =>
              tester.getBottomRight(find.byWidget(e.widget)) -
              tester.getTopLeft(find.byWidget(e.widget)),
        )
        .toList();
    expect(extents.where((e) => e == const Offset(15, 15)).length, 3);
    expect(extents.where((e) => e == const Offset(12, 12)).length, 2);
    expect(extents, contains(const Offset(16, 16)));
    expect(extents, contains(const Offset(40, 24)));
  });

  testWidgets('먹이를 하나씩 선택하며 다른 입력 상태는 유지한다', (tester) async {
    await _open(tester);
    for (var selected = 0; selected < 4; selected++) {
      await tester.tap(_key('feeding_food_$selected'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        expect(
          tester
              .getSemantics(_key('feeding_food_$i'))
              .flagsCollection
              .isSelected,
          selected == i ? ui.Tristate.isTrue : ui.Tristate.isFalse,
        );
      }
      expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '5');
      expect(tester.widget<TextFormField>(_memo).controller!.text, '잘 받아먹음');
    }
  });

  testWidgets('탈피·체중 탭은 준비 중 안내만 표시하며 급여 선택과 입력값을 유지한다', (tester) async {
    await _open(tester);
    for (final (i, label) in [(1, '탈피'), (2, '체중')]) {
      await tester.tap(_key('feeding_type_$i'));
      await tester.pumpAndSettle();
      expect(find.text('$label 기록 화면은 후속 구현 예정입니다.'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_key('feeding_type_0')).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_key('feeding_type_$i')).flagsCollection.isSelected,
        ui.Tristate.isFalse,
      );
      expect(_key('feeding_quantity'), findsOneWidget);
      expect(tester.widget<TextFormField>(_memo).controller!.text, '잘 받아먹음');
    }
  });

  testWidgets('수량을 증감하고 0 아래로 내려가지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('feeding_increase'));
    await tester.pump();
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '6');
    for (var i = 0; i < 8; i++) {
      await tester.tap(_key('feeding_decrease'));
      await tester.pump();
    }
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '0');
    await tester.tap(_key('feeding_increase'));
    await tester.pump();
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '1');
  });

  testWidgets('안 먹음은 원본 스위치 ON/OFF 자산과 접근성 상태만 변경한다', (tester) async {
    await _open(tester);
    final toggle = _key('feeding_not_eaten');
    expect(
      tester.getSemantics(toggle).flagsCollection.isToggled,
      ui.Tristate.isFalse,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(toggle).flagsCollection.isToggled,
      ui.Tristate.isTrue,
    );
    final onImage = find.descendant(of: toggle, matching: find.byType(Image));
    expect(tester.getSize(onImage), const Size(40, 24));
    expect(
      (tester.widget<Image>(onImage).image as AssetImage).assetName,
      'assets/images/feeding_switch_on.png',
    );
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '5');
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(toggle).flagsCollection.isToggled,
      ui.Tristate.isFalse,
    );
  });

  testWidgets('메모 수정과 저장 안내 후 입력 및 기존 홈 기록을 보존한다', (tester) async {
    await _open(tester);
    await tester.enterText(_memo, '오늘의 메모');
    await tester.tap(_key('feeding_save'));
    await tester.pumpAndSettle();
    expect(find.text(_saveNotice), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(_memo).controller!.text, '오늘의 메모');
    expect(find.byType(AppRecordRow), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  for (final method in ['X', '바깥 탭', '시스템 뒤로가기', '그랩버 드래그']) {
    testWidgets('$method 닫기는 기존 홈으로 돌아오며 배경 버튼을 실행하지 않는다', (tester) async {
      await _open(tester);
      if (method == 'X') {
        await tester.tap(_key('feeding_close'));
      }
      if (method == '바깥 탭') {
        await tester.tapAt(const Offset(340, 80));
      }
      if (method == '시스템 뒤로가기') {
        await tester.binding.handlePopRoute();
      }
      if (method == '그랩버 드래그') {
        await tester.drag(_key('feeding_grabber'), const Offset(0, 500));
      }
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('욱이의 하루'), findsOneWidget);
      expect(find.text('기능은 준비 중입니다.'), findsNothing);
    });
  }

  testWidgets('다시 열면 저장되지 않은 임시 입력이 초기화된다', (tester) async {
    await _open(tester);
    await tester.tap(_key('feeding_food_2'));
    await tester.tap(_key('feeding_increase'));
    await tester.tap(_key('feeding_not_eaten'));
    await tester.enterText(_memo, '임시 메모');
    await tester.tap(_key('feeding_close'));
    await tester.pumpAndSettle();
    await _reopen(tester);
    expect(tester.widget<TextFormField>(_memo).controller!.text, '잘 받아먹음');
    expect(tester.widget<Text>(_key('feeding_quantity_value')).data, '5');
    expect(
      tester.getSemantics(_key('feeding_not_eaten')).flagsCollection.isToggled,
      ui.Tristate.isFalse,
    );
    expect(
      tester.getSemantics(_key('feeding_food_0')).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
  });

  testWidgets('일반 호출에는 Figma 예시 개체·날짜·메모를 주입하지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_key('feeding_close'));
    await tester.pumpAndSettle();
    unawaited(showFeedingRecordSheet(tester.element(find.byType(HomeScreen))));
    await tester.pumpAndSettle();
    expect(find.text('급여 기록 미리보기'), findsOneWidget);
    expect(find.text('욱이 · 10월 20일'), findsNothing);
    expect(tester.widget<TextFormField>(_memo).controller!.text, isEmpty);
  });

  testWidgets('앱 시작은 로그인이고 Debug 경로에서만 미리보기 모달을 연다', (tester) async {
    await _open(tester);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(_sheet, findsNothing);
    Navigator.of(
      tester.element(find.byType(LoginScreen)),
    ).pushNamed('/feeding-record-preview');
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(360, 800), Size(320, 640)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale배에서 스크롤과 모든 입력·고정 저장 버튼에 접근한다', (
        tester,
      ) async {
        await _open(tester, size: size, scale: scale);
        final rect = tester.getRect(_sheet);
        expect(rect.top, greaterThanOrEqualTo(54));
        expect(rect.height, lessThan(size.height));
        expect(tester.takeException(), isNull);
        final saveRect = tester.getRect(_key('feeding_save'));
        for (final key in [
          'feeding_type_1',
          'feeding_food_3',
          'feeding_quantity',
          'feeding_not_eaten',
          'feeding_memo',
        ]) {
          await tester.ensureVisible(_key(key));
          await tester.pumpAndSettle();
          final element = tester.getRect(_key(key));
          expect(element.left, greaterThanOrEqualTo(25));
          expect(element.right, lessThanOrEqualTo(size.width - 25));
          expect(tester.getRect(_key('feeding_save')), saveRect);
          expect(tester.takeException(), isNull, reason: key);
        }
        await tester.enterText(_memo, '큰 글자 입력');
        await tester.tap(_key('feeding_save'));
        await tester.pumpAndSettle();
        expect(find.text(_saveNotice), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('작은 화면·200% 글자·키보드에서도 메모와 저장 버튼이 가려지지 않는다', (tester) async {
    await _open(tester, size: const Size(320, 640), scale: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_memo);
    await tester.pumpAndSettle();
    final saveRect = tester.getRect(_key('feeding_save'));
    final fieldRect = tester.getRect(_memo);
    expect(saveRect.bottom, lessThanOrEqualTo(390));
    expect(
      fieldRect.top,
      greaterThanOrEqualTo(tester.getRect(_key('feeding_header')).bottom),
    );
    expect(fieldRect.bottom, lessThanOrEqualTo(saveRect.top));
    await tester.enterText(_memo, '키보드 입력');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(_memo).controller!.text, '키보드 입력');
    expect(tester.takeException(), isNull);
  });
}
