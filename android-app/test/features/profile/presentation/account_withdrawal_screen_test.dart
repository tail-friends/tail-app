import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/account_withdrawal_preview.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/account_withdrawal_screen.dart';
import 'package:tail_friends/main.dart';

Finder key(String name) => find.byKey(ValueKey('withdrawal_$name'));
const reasonLabels = ['더 이상 파충류를 키우지 않아요', '기록 기능이 부족해요', '다른 앱을 사용해요', '기타'];

Future<void> pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const AccountWithdrawalScreen.preview(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 54, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 24);
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

Future<void> visible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

bool checked(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isChecked ==
    ui.CheckedState.isTrue;

void fullText(WidgetTester tester, String label) {
  final p = tester.renderObject<RenderParagraph>(find.text(label));
  expect(p.didExceedMaxLines, isFalse);
  // Wrapped trailing spaces may have selection boxes outside the line;
  // verify every visible word rather than that invisible whitespace.
  final boxes = RegExp(r'\S+')
      .allMatches(label)
      .expand(
        (word) => p.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        ),
      );
  for (final box in boxes) {
    final bearing = (p.text.style?.letterSpacing ?? 0).abs() / 2 + .01;
    expect(box.left, greaterThanOrEqualTo(-bearing));
    expect(box.right, lessThanOrEqualTo(p.size.width + .11), reason: label);
    expect(box.bottom, lessThanOrEqualTo(p.size.height + .11));
  }
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await loader.load();
  });

  testWidgets('Figma 기준 위치와 빈 캐릭터를 유지하며 초기 확인 및 선택은 비어 있다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pump(tester);
      expect(
        tester.getRect(key('header')),
        const Rect.fromLTWH(24, 58, 342, 44),
      );
      expect(
        tester.getRect(key('character_surface')),
        const Rect.fromLTWH(151, 136, 88, 88),
      );
      expect(tester.getSize(key('empty_character')), const Size(36, 54));
      expect(
        tester.getRect(key('warnings')),
        const Rect.fromLTWH(24, 298, 342, 115),
      );
      expect(tester.getTopLeft(key('reasons')), const Offset(24, 473));
      expect(
        tester.getRect(key('submit')),
        const Rect.fromLTWH(24, 762, 342, 48),
      );
      expect(tester.widget<TextButton>(key('submit')).onPressed, isNull);
      for (final label in reasonLabels) {
        expect(checked(tester, label), isFalse);
      }
      expect(checked(tester, '안내 사항을 모두 확인했어요'), isFalse);
      expect(find.text('9:41'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('선택 사유는 단일 선택·변경·해제되며 필수 확인을 대신하지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pump(tester);
      await tester.tap(key('reason_0'));
      await tester.pumpAndSettle();
      expect(checked(tester, reasonLabels[0]), isTrue);
      await tester.tap(key('reason_2'));
      await tester.pumpAndSettle();
      expect(checked(tester, reasonLabels[0]), isFalse);
      expect(checked(tester, reasonLabels[2]), isTrue);
      await tester.tap(key('reason_2'));
      await tester.pumpAndSettle();
      expect(checked(tester, reasonLabels[2]), isFalse);
      expect(tester.widget<TextButton>(key('submit')).onPressed, isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('사유 없이도 안내 확인만으로 진행 가능하며 미연결 안내 후 화면과 선택을 유지한다', (tester) async {
    await pump(tester);
    final original = tester.element(key('screen'));
    await tester.tap(key('acknowledge'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(key('submit')).onPressed, isNotNull);
    await tester.tap(key('submit'));
    await tester.pumpAndSettle();
    expect(find.text('회원 탈퇴 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
    expect(tester.element(key('screen')), same(original));
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(key('acknowledge'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(key('submit')).onPressed, isNull);
  });

  testWidgets('연속 탈퇴 탭은 안내 한 개만 표시하고 실제 네트워크 요청을 만들지 않는다', (tester) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await pump(tester);
        await tester.tap(key('reason_1'));
        await tester.tap(key('acknowledge'));
        await tester.pumpAndSettle();
        final onTap = tester.widget<TextButton>(key('submit')).onPressed!;
        onTap();
        onTap();
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(key('screen'), findsOneWidget);
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Network is forbidden in UI preview');
      },
    );
    expect(requests, 0);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale에서 전체 문구와 선택·진행 버튼을 스크롤로 확인한다', (
        tester,
      ) async {
        await pump(tester, size: size, scale: scale);
        for (final label in [
          '회원 탈퇴',
          '정말 떠나시나요?',
          '탈퇴 전에 아래 내용을 꼭 확인해 주세요',
          '친구 7마리와 캐릭터가 모두 삭제돼요',
          '기록 128개는 복구할 수 없어요',
          '같은 계정으로 다시 가입해도 이전 기록은 없어요',
          '떠나는 이유를 알려주세요 (선택)',
          ...reasonLabels,
          '안내 사항을 모두 확인했어요',
          '탈퇴하기',
        ]) {
          await visible(tester, find.text(label));
          fullText(tester, label);
          final rect = tester.getRect(find.text(label));
          expect(rect.left, greaterThanOrEqualTo(24));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
        }
        for (var i = 0; i < 4; i++) {
          await visible(tester, key('reason_$i'));
          expect(
            tester.getSize(key('reason_$i')).height,
            greaterThanOrEqualTo(44),
          );
        }
        await visible(tester, key('acknowledge'));
        await tester.tap(key('acknowledge'));
        await tester.pumpAndSettle();
        await visible(tester, key('submit'));
        expect(tester.getSize(key('submit')).height, greaterThanOrEqualTo(44));
        await tester.tap(key('submit'));
        await tester.pumpAndSettle();
        expect(find.text('회원 탈퇴 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('선택 요소는 체크 상태와 배타적 선택 의미를 제공한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pump(tester);
      final node = tester.getSemantics(find.bySemanticsLabel(reasonLabels[0]));
      expect(node.flagsCollection.isChecked, isNot(ui.CheckedState.none));
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      expect(tester.getSize(key('back')), const Size(44, 44));
      expect(
        tester.getSize(key('acknowledge')).height,
        greaterThanOrEqualTo(44),
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final back in ['header', 'system']) {
    testWidgets('$back 뒤로가기는 예시 화면을 닫고 로그인과 이전 상태로 복귀한다', (tester) async {
      await pump(tester, home: const AccountWithdrawalPreviewHost());
      expect(find.text(accountWithdrawalPreviewNotice), findsOneWidget);
      expect(find.text('친구 7마리와 캐릭터가 모두 삭제돼요'), findsNothing);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      await tester.tap(key('reason_1'));
      if (back == 'header') {
        await tester.tap(key('back'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(key('screen'), findsNothing);
    });
  }

  testWidgets('미리보기 사전 안내 취소는 예시 탈퇴 화면을 노출하지 않는다', (tester) async {
    await pump(tester, home: const AccountWithdrawalPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(key('screen'), findsNothing);
  });

  testWidgets('보이는 원본 SVG의 렌더링 슬롯 및 빈 캐릭터 자리를 유지한다', (tester) async {
    await pump(tester);
    for (final element in find.byType(SvgPicture).evaluate()) {
      final svg = element.widget as SvgPicture;
      final asset = (svg.bytesLoader as SvgAssetLoader).assetName;
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      final render = element.renderObject! as RenderBox;
      final a = render.localToGlobal(Offset.zero);
      final b = render.localToGlobal(
        Offset(render.size.width, render.size.height),
      );
      final expected = asset.contains('chevron')
          ? const Size(16, 16)
          : asset.contains('bullet')
          ? const Size(4, 12)
          : const Size(18, 18);
      expect(b.dx - a.dx, closeTo(expected.width, .1));
      expect(b.dy - a.dy, closeTo(expected.height, .1));
    }
    expect(
      find.descendant(of: key('empty_character'), matching: find.byType(Image)),
      findsNothing,
    );
  });

  testWidgets('일반 앱은 로그인에서 시작하며 탈퇴 미리보기 경로를 추가하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(key('screen'), findsNothing);
  });
}
