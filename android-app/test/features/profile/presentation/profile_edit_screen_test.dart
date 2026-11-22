import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/profile_edit_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/profile_edit_preview.dart';

Finder key(String name) => find.byKey(ValueKey('profile_edit_$name'));
Finder get input =>
    find.descendant(of: key('nickname'), matching: find.byType(TextFormField));
const error = '닉네임은 2–10자의 한글·영문·숫자로 입력해 주세요.';
const notSaved = 'UI 미리보기입니다. 프로필이 저장되지 않았습니다.';

Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const ProfileEditScreen.preview(),
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

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Figma baseline geometry and sample draft', (tester) async {
    await open(tester);
    expect(find.text('프로필 편집'), findsOneWidget);
    expect(tester.widget<TextFormField>(input).controller!.text, '민준');
    expect(tester.getRect(key('header')), const Rect.fromLTWH(24, 58, 342, 44));
    expect(
      tester.getRect(key('avatar')),
      const Rect.fromLTWH(153, 134, 84, 84),
    );
    expect(tester.getRect(key('photo_surface')).top, 226);
    expect(
      tester.getRect(key('nickname')),
      const Rect.fromLTWH(24, 280, 342, 72),
    );
    expect(tester.getRect(key('save')), const Rect.fromLTWH(24, 760, 342, 50));
    expect(tester.getSize(key('back')), const Size(44, 44));
    expect(tester.getSize(key('photo')).height, greaterThanOrEqualTo(44));
    expect(find.text('2–10자, 한글·영문·숫자'), findsOneWidget);
  });

  for (final name in ['', '민', 'a b', '민준!', '🐢🐢']) {
    testWidgets('rejects invalid local nickname "$name" and preserves input', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(input, name);
      await tester.tap(key('save'));
      await tester.pumpAndSettle();
      expect(find.text(error), findsOneWidget);
      expect(find.text(notSaved), findsNothing);
      expect(tester.widget<TextFormField>(input).controller!.text, name);
      await tester.enterText(input, '정상12');
      await tester.pumpAndSettle();
      expect(find.text(error), findsNothing);
    });
  }

  testWidgets('valid Korean English digits and limit, save preserves draft', (
    tester,
  ) async {
    await open(tester);
    for (final name in ['민준', 'ab', '가나다abc1234']) {
      await tester.enterText(input, name);
      await tester.tap(key('save'));
      await tester.pumpAndSettle();
      expect(find.text(notSaved), findsOneWidget);
      expect(tester.widget<TextFormField>(input).controller!.text, name);
    }
    await tester.enterText(input, '');
    await tester.enterText(input, '12345678901');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(input).controller!.text, '1234567890');
  });

  testWidgets('photo and repeated save do not request or persist data', (
    tester,
  ) async {
    var requests = 0;
    await HttpOverrides.runZoned(
      () async {
        await open(tester);
        await tester.enterText(input, '새이름');
        await tester.tap(key('photo'));
        await tester.pumpAndSettle();
        expect(find.text('사진 변경 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.tap(key('save'));
        }
        await tester.pumpAndSettle();
        expect(find.text(notSaved), findsOneWidget);
        expect(tester.widget<TextFormField>(input).controller!.text, '새이름');
        await tester.pumpWidget(const SizedBox());
        await open(tester);
        expect(tester.widget<TextFormField>(input).controller!.text, '민준');
      },
      createHttpClient: (_) {
        requests++;
        throw StateError('Unexpected HTTP');
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
      testWidgets('scroll and fixed save $size text $scale', (tester) async {
        await open(tester, size: size, scale: scale);
        final save = tester.getRect(key('save'));
        await tester.ensureVisible(input);
        await tester.enterText(input, '새닉네임');
        await tester.drag(key('scroll'), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('save')), save);
        await tester.tap(key('save'));
        await tester.pumpAndSettle();
        expect(find.text(notSaved), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(save.left, 24);
        expect(save.right, size.width - 24);
        expect(save.bottom, lessThanOrEqualTo(size.height - 24));
      });
    }
  }

  testWidgets('keyboard and invalid draft at 320x640 text2', (tester) async {
    await open(tester, size: const Size(320, 640), scale: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.ensureVisible(input);
    await tester.enterText(input, '!');
    await tester.tap(key('save'));
    await tester.pumpAndSettle();
    expect(find.text(error), findsOneWidget);
    expect(tester.getRect(key('save')).bottom, lessThanOrEqualTo(380));
    expect(tester.takeException(), isNull);
  });

  for (final systemBack in [false, true]) {
    testWidgets(
      'disclaimer and ${systemBack ? 'system' : 'header'} return to login',
      (tester) async {
        await open(tester, home: const ProfileEditPreviewHost());
        expect(find.text(profileEditPreviewNotice), findsOneWidget);
        expect(find.byType(ProfileEditScreen), findsNothing);
        await tester.tap(find.text('미리보기 열기'));
        await tester.pumpAndSettle();
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ProfileEditScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  }

  testWidgets('cancel and normal app keep existing login', (tester) async {
    await open(tester, home: const ProfileEditPreviewHost());
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('accessible controls and double entry lock', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await open(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showProfileEditPreview(context);
                showProfileEditPreview(context);
              },
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.text(profileEditPreviewNotice), findsOneWidget);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(
        tester.getSemantics(key('photo')).flagsCollection.isButton,
        isTrue,
      );
      expect(tester.getSemantics(key('back')).label, '뒤로가기');
      await tester.tap(key('back'));
      await tester.pumpAndSettle();
      expect(find.text('열기'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
}
