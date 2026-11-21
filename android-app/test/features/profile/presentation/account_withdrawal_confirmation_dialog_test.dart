import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/account_withdrawal_confirmation_preview.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/account_withdrawal_confirmation_dialog.dart';
import 'package:tail_friends/features/profile/presentation/account_withdrawal_screen.dart';
import 'package:tail_friends/main.dart';

Finder dialogKey(String name) =>
    find.byKey(ValueKey('withdrawal_confirmation_$name'));
Finder formKey(String name) => find.byKey(ValueKey('withdrawal_$name'));

class _Harness extends StatefulWidget {
  const _Harness({super.key});
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final input = TextEditingController(text: '기존 입력');
  final results = <AccountWithdrawalConfirmationResult>[];
  int taps = 0;

  Future<AccountWithdrawalConfirmationResult> open() async {
    final result = await showAccountWithdrawalConfirmationDialog(context);
    if (mounted) results.add(result);
    return result;
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => taps++,
      child: Column(
        children: [
          const Text('이전 화면'),
          TextField(controller: input),
          TextButton(onPressed: open, child: const Text('열기')),
        ],
      ),
    ),
  );
}

Future<void> pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 24,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
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
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<_HarnessState> _harness(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 24,
  double keyboard = 0,
}) async {
  final key = GlobalKey<_HarnessState>();
  await pump(
    tester,
    _Harness(key: key),
    size: size,
    scale: scale,
    top: top,
    bottom: bottom,
    keyboard: keyboard,
  );
  return key.currentState!;
}

Future<void> enterPreview(WidgetTester tester) async {
  await pump(tester, const AccountWithdrawalConfirmationPreviewHost());
  expect(find.text(accountWithdrawalPreviewNotice), findsOneWidget);
  expect(formKey('screen'), findsNothing);
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
  expect(tester.widget<TextButton>(formKey('submit')).onPressed, isNull);
  await tester.tap(formKey('reason_1'));
  await tester.tap(formKey('acknowledge'));
  await tester.pumpAndSettle();
}

void fullText(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  expect(p.didExceedMaxLines, isFalse);
  final boxes = RegExp(r'\S+')
      .allMatches(text)
      .expand(
        (word) => p.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        ),
      );
  for (final box in boxes) {
    final bearing = (p.text.style?.letterSpacing ?? 0).abs() / 2 + .01;
    expect(box.left, greaterThanOrEqualTo(-bearing));
    expect(box.right, lessThanOrEqualTo(p.size.width + .11));
    expect(box.bottom, lessThanOrEqualTo(p.size.height + .11));
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('기준 390×844에서 중앙 310×148 팝업과 130×48 버튼 및 원본 색을 사용한다', (
    tester,
  ) async {
    final h = await _harness(tester);
    final result = h.open();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(dialogKey('surface')),
      const Rect.fromLTWH(40, 348, 310, 148),
    );
    expect(
      tester.getRect(dialogKey('cancel')),
      const Rect.fromLTWH(61, 431, 130, 48),
    );
    expect(
      tester.getRect(dialogKey('confirm')),
      const Rect.fromLTWH(199, 431, 130, 48),
    );
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      accountWithdrawalConfirmationScrim,
    );
    final surface =
        tester.widget<Container>(dialogKey('surface')).decoration!
            as BoxDecoration;
    expect(surface.color, Colors.white);
    expect(surface.borderRadius, BorderRadius.circular(28));
    expect(surface.boxShadow!.single.blurRadius, 40);
    final confirm = tester.widget<AppGlassSurface>(
      dialogKey('confirm_surface'),
    );
    expect((confirm.gradient as LinearGradient).colors, [
      const Color(0xFFC0463A),
      const Color(0xFFC0463A),
    ]);
    expect(confirm.borderColor, const Color(0xFFE6E1D6));
    expect(
      tester
          .widget<TextButton>(dialogKey('confirm'))
          .style!
          .foregroundColor!
          .resolve({}),
      Colors.white,
    );
    expect(find.text('모든 기록과 캐릭터가 즉시 삭제돼요.'), findsOneWidget);
    await tester.tap(dialogKey('cancel'));
    await tester.pumpAndSettle();
    expect(await result, AccountWithdrawalConfirmationResult.cancel);
  });

  for (final action in ['cancel', 'confirm', 'barrier', 'back']) {
    testWidgets('$action 결과만 반환하고 이전 입력·라우트와 배경을 보존한다', (tester) async {
      final h = await _harness(tester);
      final original = tester.element(find.byType(_Harness));
      final pending = h.open();
      await tester.pumpAndSettle();
      if (action == 'barrier') {
        await tester.tapAt(const Offset(195, 700));
      } else if (action == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(dialogKey(action));
      }
      await tester.pumpAndSettle();
      expect(
        await pending,
        action == 'confirm'
            ? AccountWithdrawalConfirmationResult.confirm
            : AccountWithdrawalConfirmationResult.cancel,
      );
      expect(h.input.text, '기존 입력');
      expect(h.taps, 0);
      expect(tester.element(find.byType(_Harness)), same(original));
      expect(h.results, hasLength(1));
    });
  }

  testWidgets('중복 요청 및 종료 애니메이션 중 재요청은 단일 모달을 유지한다', (tester) async {
    final h = await _harness(tester);
    final first = h.open();
    final duplicate = h.open();
    await tester.pumpAndSettle();
    expect(await duplicate, AccountWithdrawalConfirmationResult.cancel);
    expect(find.byType(AccountWithdrawalConfirmationDialog), findsOneWidget);
    await tester.tap(dialogKey('confirm'));
    final exiting = h.open();
    expect(await exiting, AccountWithdrawalConfirmationResult.cancel);
    await tester.pumpAndSettle();
    expect(await first, AccountWithdrawalConfirmationResult.confirm);
    final reopened = h.open();
    await tester.pumpAndSettle();
    await tester.tap(dialogKey('cancel'));
    await tester.pumpAndSettle();
    expect(await reopened, AccountWithdrawalConfirmationResult.cancel);
  });

  testWidgets('연속 확인 및 취소 콜백은 한 번만 pop하고 닫힌 뒤 저장된 콜백은 무시한다', (tester) async {
    final h = await _harness(tester);
    final pending = h.open();
    await tester.pumpAndSettle();
    final confirm = tester.widget<TextButton>(dialogKey('confirm')).onPressed!;
    final cancel = tester.widget<TextButton>(dialogKey('cancel')).onPressed!;
    confirm();
    confirm();
    cancel();
    await tester.pumpAndSettle();
    expect(await pending, AccountWithdrawalConfirmationResult.confirm);
    confirm();
    expect(h.results, [AccountWithdrawalConfirmationResult.confirm]);
    expect(find.byType(_Harness), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 제거된 호출자의 context에서는 취소로 안전하게 종료한다', (tester) async {
    final h = await _harness(tester);
    final context = h.context;
    await tester.pumpWidget(const SizedBox());
    expect(
      await showAccountWithdrawalConfirmationDialog(context),
      AccountWithdrawalConfirmationResult.cancel,
    );
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale에서 중앙·전체 문구·44px 터치 영역을 유지한다', (
        tester,
      ) async {
        final h = await _harness(tester, size: size, scale: scale);
        final pending = h.open();
        await tester.pumpAndSettle();
        final rect = tester.getRect(dialogKey('surface'));
        expect(rect.center.dx, closeTo(size.width / 2, .1));
        expect(rect.center.dy, closeTo(size.height / 2, .1));
        expect(rect.width, lessThanOrEqualTo(size.width - 48));
        expect(rect.top, greaterThanOrEqualTo(54));
        for (final button in ['cancel', 'confirm']) {
          final r = tester.getRect(dialogKey(button));
          expect(r.width, greaterThanOrEqualTo(44));
          expect(r.height, greaterThanOrEqualTo(44));
        }
        for (final text in ['탈퇴할까요?', '모든 기록과 캐릭터가 즉시 삭제돼요.', '취소', '탈퇴']) {
          fullText(tester, text);
        }
        expect(tester.takeException(), isNull);
        await tester.tap(dialogKey('cancel'));
        await tester.pumpAndSettle();
        await pending;
      });
    }
  }

  testWidgets('큰 SafeArea와 키보드에서도 스크롤로 확인 버튼에 접근할 수 있다', (tester) async {
    final h = await _harness(
      tester,
      size: const Size(320, 640),
      scale: 2,
      keyboard: 400,
    );
    final pending = h.open();
    await tester.pumpAndSettle();
    final rect = tester.getRect(dialogKey('surface'));
    expect(rect.top, greaterThanOrEqualTo(54));
    expect(rect.bottom, lessThanOrEqualTo(240 - 54));
    await tester.ensureVisible(dialogKey('confirm'));
    await tester.pumpAndSettle();
    await tester.tap(dialogKey('confirm'));
    await tester.pumpAndSettle();
    expect(await pending, AccountWithdrawalConfirmationResult.confirm);
    expect(tester.takeException(), isNull);
  });

  testWidgets('접근성 버튼·탭 동작 및 모달 내부 키보드 포커스를 제공한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final h = await _harness(tester);
      final pending = h.open();
      await tester.pumpAndSettle();
      for (final label in ['취소', '탈퇴']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.flagsCollection.isButton, isTrue);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
      }
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus!.context!
              .findAncestorWidgetOfExactType<
                AccountWithdrawalConfirmationDialog
              >(),
          isNotNull,
        );
      }
      await tester.tap(dialogKey('cancel'));
      await tester.pumpAndSettle();
      await pending;
    } finally {
      semantics.dispose();
    }
  });

  for (final action in ['cancel', 'barrier', 'back', 'confirm']) {
    testWidgets('09-6 $action 후 기존 사유·확인 체크·화면을 유지하고 성공을 가장하지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await enterPreview(tester);
        final original = tester.element(formKey('screen'));
        await tester.tap(formKey('submit'));
        await tester.pumpAndSettle();
        expect(
          find.byType(AccountWithdrawalConfirmationDialog),
          findsOneWidget,
        );
        if (action == 'barrier') {
          await tester.tapAt(const Offset(195, 700));
        } else if (action == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(dialogKey(action));
        }
        await tester.pumpAndSettle();
        expect(tester.element(formKey('screen')), same(original));
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('기록 기능이 부족해요'))
              .flagsCollection
              .isChecked,
          ui.CheckedState.isTrue,
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('안내 사항을 모두 확인했어요'))
              .flagsCollection
              .isChecked,
          ui.CheckedState.isTrue,
        );
        expect(find.byType(LoginScreen), findsNothing);
        expect(
          find.text('회원 탈퇴 기능은 아직 연결되지 않았습니다.'),
          action == 'confirm' ? findsOneWidget : findsNothing,
        );
        await tester.tap(formKey('back'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Debug 연속 진입은 하나의 팝업·안내만 만들며 HTTP 요청이 없다', (tester) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await enterPreview(tester);
        final open = tester.widget<TextButton>(formKey('submit')).onPressed!;
        open();
        open();
        await tester.pumpAndSettle();
        expect(
          find.byType(AccountWithdrawalConfirmationDialog),
          findsOneWidget,
        );
        await tester.tap(dialogKey('confirm'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(formKey('screen'), findsOneWidget);
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Network is forbidden in UI preview');
      },
    );
    expect(requests, 0);
  });

  testWidgets('사전 안내 취소 및 일반 앱 진입에서는 예시와 최종 확인을 노출하지 않는다', (tester) async {
    await pump(tester, const AccountWithdrawalConfirmationPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(formKey('screen'), findsNothing);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AccountWithdrawalConfirmationDialog), findsNothing);
  });
}
