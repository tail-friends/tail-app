import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/account_management_preview.dart' as preview;
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/account_management_screen.dart';
import 'package:tail_friends/main.dart';

Finder _key(String key) => find.byKey(ValueKey('account_management_$key'));
const _sample = '연결됨 · 2025년 9월 6일 가입';

class _Routes extends NavigatorObserver {
  final events = <String>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('push');
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('pop');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      events.add('replace');
}

Future<void> _open(
  WidgetTester tester, {
  Widget home = const AccountManagementScreen.preview(),
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 24,
  List<NavigatorObserver> observers = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      navigatorObservers: observers,
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

void _rect(WidgetTester tester, Finder finder, Rect expected) {
  final actual = tester.getRect(finder);
  expect(actual.left, closeTo(expected.left, .1));
  expect(actual.top, closeTo(expected.top, .1));
  expect(actual.width, closeTo(expected.width, .1));
  expect(actual.height, closeTo(expected.height, .1));
}

void _fullText(WidgetTester tester, String value) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
  expect(paragraph.didExceedMaxLines, isFalse, reason: value);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: value.length),
  );
  expect(boxes, isNotEmpty, reason: value);
  for (final box in boxes) {
    expect(box.left, greaterThanOrEqualTo(-.1));
    expect(box.right, lessThanOrEqualTo(paragraph.size.width + .1));
    expect(box.top, greaterThanOrEqualTo(-.1));
    expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Jua 제목·로그인 정보·카카오 예시와 두 액션만 표시한다', (tester) async {
    await _open(tester);
    for (final text in ['계정 관리', '로그인 정보', '카카오', _sample, '로그아웃', '회원 탈퇴']) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    expect(find.text('9:41'), findsNothing);
    expect(find.byType(AppBottomNavigation), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844에서 중앙 제목·카드·구분선과 44px 터치 영역이 Figma 배치를 유지한다', (
    tester,
  ) async {
    await _open(tester);
    _rect(tester, _key('header'), const Rect.fromLTWH(24, 58, 342, 44));
    _rect(tester, _key('back'), const Rect.fromLTWH(24, 58, 44, 44));
    _rect(tester, _key('back_surface'), const Rect.fromLTWH(24, 62, 36, 36));
    _rect(tester, _key('right_space'), const Rect.fromLTWH(330, 62, 36, 36));
    expect(tester.getRect(_key('title')).center.dx, 195);
    _rect(tester, _key('section'), const Rect.fromLTWH(24, 122, 342, 16));
    _rect(tester, _key('info'), const Rect.fromLTWH(24, 158, 342, 63));
    _rect(tester, _key('actions'), const Rect.fromLTWH(24, 241, 342, 92));
    _rect(tester, _key('logout'), const Rect.fromLTWH(24, 241, 342, 47));
    _rect(tester, _key('divider'), const Rect.fromLTWH(25, 288, 340, 1));
    _rect(tester, _key('delete'), const Rect.fromLTWH(24, 289, 342, 44));
    expect(tester.getTopLeft(find.text('카카오')), const Offset(41, 173));
    expect(tester.getTopLeft(find.text(_sample)), const Offset(41, 192));
    expect(tester.getTopLeft(find.text('로그아웃')), const Offset(41, 256));
    expect(tester.getTopLeft(find.text('회원 탈퇴')), const Offset(41, 304));
  });

  testWidgets('Glass 카드의 색·테두리·곡률·그림자와 글꼴 계층을 유지한다', (tester) async {
    await _open(tester);
    for (final key in ['info', 'actions']) {
      final surface = tester.widget<AppGlassSurface>(
        find.descendant(of: _key(key), matching: find.byType(AppGlassSurface)),
      );
      expect(surface.gradient, AppColors.glassSoftGradient);
      expect(surface.borderColor, Colors.white);
      expect(surface.borderRadius, BorderRadius.circular(22));
      expect(surface.blur, 18);
      expect(surface.boxShadow.single.offset, const Offset(0, 12));
      expect(surface.boxShadow.single.blurRadius, 32);
    }
    expect(tester.widget<Text>(find.text('계정 관리')).style?.fontSize, 14);
    expect(tester.widget<Text>(find.text('로그인 정보')).style?.fontSize, 12);
    expect(tester.widget<Text>(find.text('카카오')).style?.fontSize, 13);
    expect(tester.widget<Text>(find.text(_sample)).style?.fontSize, 11);
    expect(
      tester.widget<Text>(find.text('회원 탈퇴')).style?.color,
      const Color(0xFFB23B30),
    );
    expect(
      tester.widget<Text>(find.text('로그인 정보')).style?.color,
      const Color(0xFF6B675E),
    );
  });

  testWidgets('동일한 로컬 배경과 Chevron 원본만 사용하고 실제 아이콘 슬롯을 지킨다', (tester) async {
    await _open(tester);
    final image = tester.widget<Image>(_key('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/pet_registration_complete_background.png',
    );
    expect(image.excludeFromSemantics, isTrue);
    expect(find.byType(Image), findsOneWidget);
    final back = tester.widget<SvgPicture>(_key('back_icon'));
    expect(
      (back.bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/terms_chevron_left.svg',
    );
    expect(tester.getSize(_key('back_icon')), const Size(24, 24));
    final render = tester.renderObject<RenderBox>(_key('back_icon'));
    final start = render.localToGlobal(Offset.zero);
    final end = render.localToGlobal(
      Offset(render.size.width, render.size.height),
    );
    expect(end.dx - start.dx, closeTo(16, .1));
    expect(end.dy - start.dy, closeTo(16, .1));
    for (final key in ['logout', 'delete']) {
      final finder = find.descendant(
        of: _key(key),
        matching: find.byType(SvgPicture),
      );
      expect(
        (tester.widget<SvgPicture>(finder).bytesLoader as SvgAssetLoader)
            .assetName,
        'assets/icons/home_metric_chevron_right.svg',
      );
      expect(tester.getSize(finder), const Size(14, 14));
    }
  });

  for (final entry in {'logout': '로그아웃', 'delete': '회원 탈퇴'}.entries) {
    testWidgets('${entry.value}은 안내만 띄우고 화면·계정 예시·라우트를 변경하지 않는다', (
      tester,
    ) async {
      final routes = _Routes();
      await _open(tester, observers: [routes]);
      final original = tester.element(find.byType(AccountManagementScreen));
      final events = List<String>.of(routes.events);
      await tester.tap(_key(entry.key));
      await tester.pumpAndSettle();
      expect(find.text('${entry.value} 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
      expect(
        tester.element(find.byType(AccountManagementScreen)),
        same(original),
      );
      expect(find.text(_sample), findsOneWidget);
      expect(routes.events, events);
      expect(find.byType(LoginScreen), findsNothing);
    });
  }

  testWidgets('반복 클릭은 안내를 쌓지 않고 현재 액션 안내만 유지한다', (tester) async {
    await _open(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(_key('logout'));
      await tester.pumpAndSettle();
      expect(find.text('로그아웃 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
    }
    await tester.tap(_key('delete'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃 기능은 아직 연결되지 않았습니다.'), findsNothing);
    expect(find.text('회원 탈퇴 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('예시 계정 화면과 두 액션은 HTTP 클라이언트를 만들지 않는다', (tester) async {
    var clients = 0;
    await HttpOverrides.runZoned(
      () async {
        await _open(tester);
        for (final key in ['logout', 'delete']) {
          await tester.tap(_key(key));
          await tester.pumpAndSettle();
        }
        await tester.pump(const Duration(minutes: 5));
        await tester.pumpAndSettle();
        expect(find.text(_sample), findsOneWidget);
        expect(find.byType(AccountManagementScreen), findsOneWidget);
      },
      createHttpClient: (_) {
        clients++;
        throw StateError('Unexpected network access in account preview');
      },
    );
    expect(clients, 0);
  });

  for (final exit in ['back_button', 'system_back']) {
    testWidgets('$exit 복귀 시 이전 로그인 인스턴스를 유지하고 안내를 누출하지 않는다', (tester) async {
      await _open(tester, home: const LoginScreen());
      final original = tester.element(find.byType(LoginScreen));
      final opening = showAccountManagementPreview(original);
      await tester.pumpAndSettle();
      expect(find.text(accountManagementPreviewNotice), findsOneWidget);
      expect(find.text(_sample), findsNothing);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      await tester.tap(_key('logout'));
      await tester.pumpAndSettle();
      if (exit == 'system_back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('back'));
      }
      await tester.pumpAndSettle();
      await opening;
      expect(tester.element(find.byType(LoginScreen)), same(original));
      expect(find.byType(AccountManagementScreen), findsNothing);
      expect(find.text('로그아웃 기능은 아직 연결되지 않았습니다.'), findsNothing);
      expect(find.text(_sample), findsNothing);
    });
  }

  for (final exit in ['back_button', 'system_back']) {
    testWidgets('루트 미리보기에서도 $exit 이 안전하게 일반 로그인으로 복귀한다', (tester) async {
      await _open(tester);
      if (exit == 'system_back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('back'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(_sample), findsNothing);
    });
  }

  for (final exit in ['cancel', 'back']) {
    testWidgets('미리보기 안내 $exit 시 예시 데이터 화면에 진입하지 않는다', (tester) async {
      await _open(tester, home: const LoginScreen());
      final original = tester.element(find.byType(LoginScreen));
      final opening = showAccountManagementPreview(original);
      await tester.pumpAndSettle();
      expect(find.text(accountManagementPreviewNotice), findsOneWidget);
      expect(find.text(_sample), findsNothing);
      if (exit == 'cancel') {
        await tester.tap(find.text('취소'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      await opening;
      expect(tester.element(find.byType(LoginScreen)), same(original));
      expect(find.byType(AccountManagementScreen), findsNothing);
    });
  }

  testWidgets('독립 Debug 진입점은 예시 안내 확인 후에만 계정 화면을 연다', (tester) async {
    await _open(tester, home: const preview.AccountManagementPreviewHost());
    expect(find.text(accountManagementPreviewNotice), findsOneWidget);
    expect(find.text(_sample), findsNothing);
    await tester.tap(find.text('미리보기 열기'));
    await tester.pumpAndSettle();
    expect(find.text(_sample), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '${size.width}×${size.height} 글자 $scale 배에서 정보·버튼·44px 타깃이 잘리지 않는다',
        (tester) async {
          await _open(tester, size: size, scale: scale);
          for (final text in [
            '계정 관리',
            '로그인 정보',
            '카카오',
            _sample,
            '로그아웃',
            '회원 탈퇴',
          ]) {
            _fullText(tester, text);
          }
          expect(
            tester.getRect(_key('title')).center.dx,
            closeTo(size.width / 2, .1),
          );
          for (final key in ['back', 'logout', 'delete']) {
            await tester.ensureVisible(_key(key));
            await tester.pumpAndSettle();
            final rect = tester.getRect(_key(key));
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, greaterThanOrEqualTo(24));
            expect(rect.right, lessThanOrEqualTo(size.width - 24));
            expect(_key(key).hitTestable(), findsOneWidget);
          }
          for (final key in ['logout', 'delete']) {
            await tester.tap(_key(key));
            await tester.pumpAndSettle();
            expect(find.byType(AccountManagementScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('큰 SafeArea와 제한된 높이에서는 스크롤해서 모든 컨트롤에 접근한다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      scale: 2,
      top: 150,
      bottom: 150,
    );
    expect(tester.getRect(_key('header')).top, 154);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(of: _key('scroll'), matching: find.byType(Scrollable))
          .first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    for (final key in ['delete', 'logout', 'back']) {
      await tester.ensureVisible(_key(key));
      await tester.pumpAndSettle();
      expect(_key(key).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('TalkBack 의미에 예시 정보와 뒤로·로그아웃·탈퇴 버튼이 명시된다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _open(tester);
      expect(find.bySemanticsLabel(RegExp('Figma 예시 계정 정보')), findsOneWidget);
      for (final label in ['뒤로가기', '로그아웃', '회원 탈퇴']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.flagsCollection.isButton, isTrue);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('일반 앱은 기존 로그인에서 시작하며 계정 예시와 라우트를 노출하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AccountManagementScreen), findsNothing);
    expect(find.text(_sample), findsNothing);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routes
          ?.keys
          .any((r) => r.contains('account')),
      isFalse,
    );
  });
}
