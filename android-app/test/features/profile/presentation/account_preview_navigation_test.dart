import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/account_management_preview.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/account_management_screen.dart';
import 'package:tail_friends/features/profile/presentation/account_withdrawal_confirmation_dialog.dart';
import 'package:tail_friends/features/profile/presentation/account_withdrawal_screen.dart';
import 'package:tail_friends/features/profile/presentation/logout_confirmation_dialog.dart';

Finder a(String name) => find.byKey(ValueKey('account_management_$name'));
Finder w(String name) => find.byKey(ValueKey('withdrawal_$name'));
Finder l(String name) => find.byKey(ValueKey('logout_confirmation_$name'));
Finder c(String name) => find.byKey(ValueKey('withdrawal_confirmation_$name'));
const sample = '연결됨 · 2025년 9월 6일 가입';
const logoutNotice = '로그아웃 기능은 아직 연결되지 않았습니다.';
const withdrawalNotice = '회원 탈퇴 기능은 아직 연결되지 않았습니다.';

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<Element> enter(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
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
      home: const AccountManagementPreviewHost(),
    ),
  );
  await tester.pumpAndSettle();
  final login = tester.element(find.byType(LoginScreen));
  expect(find.text(accountManagementPreviewNotice), findsOneWidget);
  expect(find.text(sample), findsNothing);
  await tap(tester, find.text('미리보기 열기'));
  expect(find.text(sample), findsOneWidget);
  return login;
}

VoidCallback menu(WidgetTester tester, String action) => tester
    .widget<InkWell>(
      find.descendant(of: a(action), matching: find.byType(InkWell)),
    )
    .onTap!;

Future<void> withdraw(WidgetTester tester) async {
  await tap(tester, a('delete'));
  expect(find.text(accountWithdrawalPreviewNotice), findsOneWidget);
  expect(find.byType(AccountWithdrawalScreen), findsNothing);
  await tap(tester, find.text('미리보기 열기'));
  expect(find.byType(AccountWithdrawalScreen), findsOneWidget);
  expect(tester.widget<TextButton>(w('submit')).onPressed, isNull);
}

Future<void> ready(WidgetTester tester) async {
  await tap(tester, w('reason_1'));
  await tap(tester, w('acknowledge'));
  expect(tester.widget<TextButton>(w('submit')).onPressed, isNotNull);
}

void selectionsPreserved(WidgetTester tester) {
  for (final label in ['기록 기능이 부족해요', '안내 사항을 모두 확인했어요']) {
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(label))
          .flagsCollection
          .isChecked,
      ui.CheckedState.isTrue,
    );
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  for (final action in ['cancel', 'barrier', 'back', 'confirm']) {
    testWidgets('계정 관리 → 로그아웃 $action 후 원래 예시·화면·로그인 인스턴스를 보존한다', (
      tester,
    ) async {
      final login = await enter(tester);
      final account = tester.element(find.byType(AccountManagementScreen));
      await tap(tester, a('logout'));
      expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
      expect(find.byType(AccountWithdrawalScreen), findsNothing);
      if (action == 'barrier') {
        await tester.tapAt(const Offset(195, 700));
      } else if (action == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(l(action == 'confirm' ? 'confirm_button' : 'cancel'));
      }
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(AccountManagementScreen)),
        same(account),
      );
      expect(find.text(sample), findsOneWidget);
      expect(
        find.text(logoutNotice),
        action == 'confirm' ? findsOneWidget : findsNothing,
      );
      expect(find.byType(LoginScreen), findsNothing);
      await tap(tester, a('back'));
      expect(tester.element(find.byType(LoginScreen)), same(login));
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  for (final action in ['cancel', 'back']) {
    testWidgets('탈퇴 사전 안내 $action 후 화면 생성 없이 계정 관리로 복귀하고 잠금을 해제한다', (
      tester,
    ) async {
      await enter(tester);
      final account = tester.element(find.byType(AccountManagementScreen));
      await tap(tester, a('delete'));
      expect(find.text(accountWithdrawalPreviewNotice), findsOneWidget);
      if (action == 'cancel') {
        await tester.tap(find.text('취소'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(AccountWithdrawalScreen), findsNothing);
      expect(
        tester.element(find.byType(AccountManagementScreen)),
        same(account),
      );
      await tap(tester, a('logout'));
      expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
      await tap(tester, l('cancel'));
    });
  }

  for (final action in ['cancel', 'barrier', 'back', 'confirm']) {
    testWidgets('계정 관리 → 탈퇴 → 최종 확인 $action 은 입력 선택을 유지하고 실제 삭제를 하지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await enter(tester);
        final account = tester.element(find.byType(AccountManagementScreen));
        await withdraw(tester);
        final form = tester.element(find.byType(AccountWithdrawalScreen));
        await ready(tester);
        await tap(tester, w('submit'));
        expect(
          find.byType(AccountWithdrawalConfirmationDialog),
          findsOneWidget,
        );
        if (action == 'barrier') {
          await tester.tapAt(const Offset(195, 700));
        } else if (action == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(c(action));
        }
        await tester.pumpAndSettle();
        expect(
          tester.element(find.byType(AccountWithdrawalScreen)),
          same(form),
        );
        selectionsPreserved(tester);
        expect(
          find.text(withdrawalNotice),
          action == 'confirm' ? findsOneWidget : findsNothing,
        );
        expect(find.byType(LoginScreen), findsNothing);
        await tap(tester, w('back'));
        expect(
          tester.element(find.byType(AccountManagementScreen)),
          same(account),
        );
        expect(find.text(sample), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('로그아웃 중 같은 메뉴와 다른 메뉴를 반복 호출해도 다이얼로그 하나만 만든다', (tester) async {
    await enter(tester);
    final logout = menu(tester, 'logout');
    final deletion = menu(tester, 'delete');
    logout();
    logout();
    deletion();
    await tester.pumpAndSettle();
    expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AccountWithdrawalScreen), findsNothing);
    await tap(tester, l('cancel'));
    await withdraw(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(sample), findsOneWidget);
  });

  testWidgets('탈퇴 진입·안내·최종 확인에서 연속 클릭으로 중첩 화면이나 안내를 만들지 않는다', (tester) async {
    await enter(tester);
    final logout = menu(tester, 'logout');
    final deletion = menu(tester, 'delete');
    deletion();
    deletion();
    logout();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tap(tester, find.text('미리보기 열기'));
    deletion();
    logout();
    await tester.pumpAndSettle();
    expect(find.byType(AccountWithdrawalScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(LogoutConfirmationDialog), findsNothing);
    await ready(tester);
    final submit = tester.widget<TextButton>(w('submit')).onPressed!;
    submit();
    submit();
    await tester.pumpAndSettle();
    expect(find.byType(AccountWithdrawalConfirmationDialog), findsOneWidget);
    final confirm = tester.widget<TextButton>(c('confirm')).onPressed!;
    confirm();
    confirm();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tap(tester, w('back'));
    await tap(tester, a('logout'));
    expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
    await tap(tester, l('cancel'));
  });

  testWidgets('시스템 뒤로가기는 최종 확인 → 탈퇴 → 계정 관리 → 로그인 순서로 복귀한다', (tester) async {
    final login = await enter(tester);
    await withdraw(tester);
    await ready(tester);
    await tap(tester, w('submit'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AccountWithdrawalScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(sample), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(LoginScreen)), same(login));
  });

  testWidgets('이미 닫힌 계정 관리 화면의 메뉴 콜백은 새 화면이나 안내를 열지 않는다', (tester) async {
    await enter(tester);
    final logout = menu(tester, 'logout');
    final deletion = menu(tester, 'delete');
    await tap(tester, a('back'));
    logout();
    deletion();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LogoutConfirmationDialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$size 글자 $scale에서 전체 이동·취소·확인·안전 복귀 흐름에 접근한다', (
        tester,
      ) async {
        final login = await enter(tester, size: size, scale: scale);
        await tap(tester, a('logout'));
        await tap(tester, l('cancel'));
        await withdraw(tester);
        await ready(tester);
        await tap(tester, w('submit'));
        await tap(tester, c('cancel'));
        await tap(tester, w('submit'));
        await tap(tester, c('confirm'));
        expect(find.text(withdrawalNotice), findsOneWidget);
        await tap(tester, w('back'));
        await tap(tester, a('logout'));
        await tap(tester, l('confirm_button'));
        expect(find.text(logoutNotice), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tap(tester, a('back'));
        expect(tester.element(find.byType(LoginScreen)), same(login));
      });
    }
  }

  testWidgets('연결된 양쪽 확인 흐름은 HTTP 클라이언트를 만들지 않으며 예시 계정을 유지한다', (tester) async {
    var clients = 0;
    await HttpOverrides.runZoned(
      () async {
        await enter(tester);
        await tap(tester, a('logout'));
        await tap(tester, l('confirm_button'));
        await withdraw(tester);
        await ready(tester);
        await tap(tester, w('submit'));
        await tap(tester, c('confirm'));
        await tap(tester, w('back'));
        expect(find.text(sample), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
      createHttpClient: (_) {
        clients++;
        throw StateError('No network in account preview navigation');
      },
    );
    expect(clients, 0);
  });

  testWidgets('스크린리더 버튼 의미와 키보드 포커스가 실제 로그아웃·탈퇴 팝업에 유지된다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await enter(tester);
      for (final label in ['로그아웃', '회원 탈퇴']) {
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .flagsCollection
              .isButton,
          isTrue,
        );
      }
      await tap(tester, a('logout'));
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus!.context!
              .findAncestorWidgetOfExactType<LogoutConfirmationDialog>(),
          isNotNull,
        );
      }
      await tap(tester, l('cancel'));
      await withdraw(tester);
      await ready(tester);
      await tap(tester, w('submit'));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('탈퇴'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      for (var i = 0; i < 4; i++) {
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
      await tap(tester, c('cancel'));
    } finally {
      semantics.dispose();
    }
  });
}
