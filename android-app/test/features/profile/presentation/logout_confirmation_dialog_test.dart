import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/logout_confirmation_dialog.dart';
import 'package:tail_friends/logout_confirmation_preview.dart' as preview;
import 'package:tail_friends/main.dart';

Finder _key(String name) => find.byKey(ValueKey('logout_confirmation_$name'));
Finder _preview(String name) => find.byKey(ValueKey('logout_preview_$name'));

class _Harness extends StatefulWidget {
  const _Harness({super.key});
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final input = TextEditingController(text: '유지할 입력');
  final results = <LogoutConfirmationResult>[];
  int backgroundTaps = 0;

  Future<LogoutConfirmationResult> open() async {
    final result = await showLogoutConfirmationDialog(context);
    if (mounted) setState(() => results.add(result));
    return result;
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    body: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => backgroundTaps++,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text('기존 화면'),
            TextField(controller: input),
            TextButton(onPressed: open, child: const Text('열기')),
          ],
        ),
      ),
    ),
  );
}

Future<void> _pump(
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
  await _pump(
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

void _rect(WidgetTester tester, Finder finder, Rect expected) {
  final rect = tester.getRect(finder);
  expect(rect.left, closeTo(expected.left, .1));
  expect(rect.top, closeTo(expected.top, .1));
  expect(rect.width, closeTo(expected.width, .1));
  expect(rect.height, closeTo(expected.height, .1));
}

void _fullText(WidgetTester tester, String value) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
  expect(paragraph.didExceedMaxLines, isFalse, reason: value);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: value.length),
  );
  expect(boxes, isNotEmpty);
  for (final box in boxes) {
    expect(box.left, greaterThanOrEqualTo(-.1001));
    expect(box.right, lessThanOrEqualTo(paragraph.size.width + .1));
    expect(box.top, greaterThanOrEqualTo(-.1));
    expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .1));
  }
}

Future<void> _enterPreview(WidgetTester tester) async {
  await _pump(tester, const preview.LogoutConfirmationPreviewHost());
  expect(find.text(preview.logoutConfirmationPreviewNotice), findsOneWidget);
  expect(find.text('연결됨 · 2025년 9월 6일 가입'), findsNothing);
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
  expect(_key('surface'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('390×844 전체 프레임 중앙에 310×148 팝업과 130×48 버튼을 배치한다', (tester) async {
    final state = await _harness(tester);
    final pending = state.open();
    await tester.pumpAndSettle();
    _rect(tester, _key('surface'), const Rect.fromLTWH(40, 348, 310, 148));
    _rect(tester, _key('cancel'), const Rect.fromLTWH(61, 431, 130, 48));
    _rect(tester, _key('confirm'), const Rect.fromLTWH(199, 431, 130, 48));
    expect(tester.getRect(_key('title')).top, 373);
    expect(tester.getRect(_key('description')).top, 401);
    expect(tester.widget<Text>(_key('title')).style?.fontFamily, 'Jua');
    expect(tester.widget<Text>(_key('title')).style?.fontSize, 16);
    expect(tester.widget<Text>(_key('description')).style?.fontSize, 11);
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
    expect(await pending, LogoutConfirmationResult.cancel);
  });

  testWidgets('흰 표면·Glass 취소·베이지 확인·테두리·그림자와 28% 스크림을 유지한다', (tester) async {
    final state = await _harness(tester);
    final pending = state.open();
    await tester.pumpAndSettle();
    final box =
        tester.widget<Container>(_key('surface')).decoration as BoxDecoration;
    expect(box.color, Colors.white);
    expect(box.borderRadius, BorderRadius.circular(28));
    expect((box.border! as Border).top.color, AppColors.borderGlass);
    expect(box.boxShadow!.single.offset, const Offset(0, 20));
    expect(box.boxShadow!.single.blurRadius, 40);
    final cancel = tester.widget<AppButton>(_key('cancel'));
    expect(cancel.variant, AppButtonVariant.ghost);
    final surface = tester.widget<AppGlassSurface>(_key('confirm'));
    expect((surface.gradient as LinearGradient).colors, [
      const Color(0xFFF3E2C2),
      const Color(0xFFF3E2C2),
    ]);
    expect(surface.borderColor, const Color(0xFFE6E1D6));
    expect(surface.boxShadow.single.offset, const Offset(0, 2));
    expect(surface.boxShadow.single.blurRadius, 8);
    final barrier = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((b) => b.dismissible)
        .single;
    expect(barrier.color, logoutConfirmationScrim);
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
    await pending;
  });

  for (final action in ['cancel', 'confirm_button']) {
    testWidgets('$action 은 선택 의도만 반환하고 기존 화면과 입력을 유지한다', (tester) async {
      final state = await _harness(tester);
      final pending = state.open();
      await tester.pumpAndSettle();
      await tester.tap(_key(action));
      await tester.pumpAndSettle();
      expect(
        await pending,
        action == 'cancel'
            ? LogoutConfirmationResult.cancel
            : LogoutConfirmationResult.confirm,
      );
      expect(state.results.length, 1);
      expect(state.input.text, '유지할 입력');
      expect(find.text('기존 화면'), findsOneWidget);
      expect(_key('surface'), findsNothing);
    });
  }

  for (final action in ['barrier', 'system_back']) {
    testWidgets('$action 은 취소이며 배경 입력을 실행하지 않는다', (tester) async {
      final state = await _harness(tester);
      final pending = state.open();
      await tester.pumpAndSettle();
      if (action == 'barrier') {
        await tester.tapAt(const Offset(8, 160));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(await pending, LogoutConfirmationResult.cancel);
      expect(state.backgroundTaps, 0);
      expect(state.input.text, '유지할 입력');
      expect(find.text('기존 화면'), findsOneWidget);
    });
  }

  testWidgets('중복 열기 요청은 취소로 무시하며 확인 의도는 한 번만 반환한다', (tester) async {
    final state = await _harness(tester);
    final first = state.open();
    final duplicate = state.open();
    await tester.pumpAndSettle();
    expect(await duplicate, LogoutConfirmationResult.cancel);
    expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
    await tester.tap(_key('confirm_button'));
    await tester.pumpAndSettle();
    expect(await first, LogoutConfirmationResult.confirm);
    expect(
      state.results.where((r) => r == LogoutConfirmationResult.confirm).length,
      1,
    );
  });

  testWidgets('종료 애니메이션 중에는 다시 열리지 않으며 완료 뒤에는 재사용할 수 있다', (tester) async {
    final state = await _harness(tester);
    final first = state.open();
    await tester.pumpAndSettle();
    await tester.tap(_key('cancel'));
    await tester.pump();
    expect(
      await showLogoutConfirmationDialog(state.context),
      LogoutConfirmationResult.cancel,
    );
    await tester.pumpAndSettle();
    await first;
    final second = state.open();
    await tester.pumpAndSettle();
    expect(_key('surface'), findsOneWidget);
    await tester.tap(_key('confirm_button'));
    await tester.pumpAndSettle();
    expect(await second, LogoutConfirmationResult.confirm);
  });

  testWidgets('확인·취소 연속 콜백으로 부모 라우트를 중복 pop하지 않는다', (tester) async {
    final state = await _harness(tester);
    final pending = state.open();
    await tester.pumpAndSettle();
    final confirm = tester
        .widget<TextButton>(_key('confirm_button'))
        .onPressed!;
    final cancel = tester.widget<AppButton>(_key('cancel')).onPressed!;
    confirm();
    confirm();
    cancel();
    await tester.pumpAndSettle();
    expect(await pending, LogoutConfirmationResult.confirm);
    expect(state.results, [LogoutConfirmationResult.confirm]);
    expect(find.text('기존 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('바깥 터치 뒤 늦은 확인 콜백은 취소 결과나 부모 화면을 바꾸지 않는다', (tester) async {
    final state = await _harness(tester);
    final pending = state.open();
    await tester.pumpAndSettle();
    final confirm = tester
        .widget<TextButton>(_key('confirm_button'))
        .onPressed!;
    await tester.tapAt(const Offset(8, 160));
    await tester.pump();
    confirm();
    await tester.pumpAndSettle();
    confirm();
    expect(await pending, LogoutConfirmationResult.cancel);
    expect(state.results, [LogoutConfirmationResult.cancel]);
    expect(find.text('기존 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('해제된 호출자 컨텍스트는 안전하게 취소한다', (tester) async {
    final state = await _harness(tester);
    final oldContext = state.context;
    await tester.pumpWidget(const SizedBox());
    expect(
      await showLogoutConfirmationDialog(oldContext),
      LogoutConfirmationResult.cancel,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('컴포넌트는 HTTP 클라이언트를 생성하지 않고 확인 의도만 반환한다', (tester) async {
    var clients = 0;
    await HttpOverrides.runZoned(
      () async {
        final state = await _harness(tester);
        final pending = state.open();
        await tester.pumpAndSettle();
        await tester.tap(_key('confirm_button'));
        await tester.pumpAndSettle();
        expect(await pending, LogoutConfirmationResult.confirm);
        expect(state.input.text, '유지할 입력');
      },
      createHttpClient: (_) {
        clients++;
        throw StateError('Unexpected HTTP client');
      },
    );
    expect(clients, 0);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        '${size.width}×${size.height} 글자 $scale 배에서 중앙 정렬·전체 문구·버튼을 유지한다',
        (tester) async {
          final state = await _harness(tester, size: size, scale: scale);
          final pending = state.open();
          await tester.pumpAndSettle();
          final surface = tester.getRect(_key('surface'));
          expect(surface.center.dx, closeTo(size.width / 2, .1));
          expect(surface.center.dy, closeTo(size.height / 2, .1));
          expect(
            surface.width,
            closeTo(size.width < 358 ? size.width - 48 : 310, .1),
          );
          for (final text in ['로그아웃할까요?', '기록은 계정에 안전하게 보관돼요.', '취소', '로그아웃']) {
            _fullText(tester, text);
          }
          final cancel = tester.getRect(_key('cancel'));
          final confirm = tester.getRect(_key('confirm'));
          expect(confirm.left - cancel.right, closeTo(8, .1));
          expect(cancel.width, closeTo(confirm.width, .1));
          expect(cancel.height, closeTo(confirm.height, .1));
          for (final key in ['cancel', 'confirm_button']) {
            final rect = tester.getRect(_key(key));
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, greaterThan(surface.left));
            expect(rect.right, lessThan(surface.right));
            expect(_key(key).hitTestable(), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.tap(_key('cancel'));
          await tester.pumpAndSettle();
          expect(await pending, LogoutConfirmationResult.cancel);
        },
      );
    }
  }

  testWidgets('키보드가 열린 작은 화면에서는 가시 영역 안에서 스크롤하여 취소할 수 있다', (tester) async {
    final state = await _harness(
      tester,
      size: const Size(320, 640),
      scale: 2,
      keyboard: 400,
    );
    final pending = state.open();
    await tester.pumpAndSettle();
    final surface = tester.getRect(_key('surface'));
    expect(surface.center.dx, 160);
    expect(surface.center.dy, closeTo(120, .1));
    expect(surface.top, greaterThanOrEqualTo(54));
    expect(surface.bottom, lessThanOrEqualTo(240 - 54));
    for (final key in ['confirm_button', 'cancel']) {
      await tester.ensureVisible(_key(key));
      await tester.pumpAndSettle();
      expect(_key(key).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
    expect(await pending, LogoutConfirmationResult.cancel);
  });

  testWidgets('큰 상하 SafeArea에서도 팝업과 버튼이 화면 안에 유지된다', (tester) async {
    final state = await _harness(
      tester,
      size: const Size(320, 640),
      scale: 2,
      top: 90,
      bottom: 60,
    );
    final pending = state.open();
    await tester.pumpAndSettle();
    final surface = tester.getRect(_key('surface'));
    expect(surface.top, greaterThanOrEqualTo(90));
    expect(surface.bottom, lessThanOrEqualTo(550));
    expect(surface.center.dy, 320);
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
    await pending;
  });

  testWidgets('키보드 포커스는 다이얼로그 안에서 순환하며 배경 입력으로 빠지지 않는다', (tester) async {
    final state = await _harness(tester);
    final pending = state.open();
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final context = FocusManager.instance.primaryFocus?.context;
      expect(context, isNotNull);
      expect(ModalRoute.of(context!)?.settings.name, 'logout-confirmation');
    }
    expect(state.input.text, '유지할 입력');
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
    await pending;
  });

  testWidgets('접근성에 확인 제목과 두 버튼의 탭 액션을 제공한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final state = await _harness(tester);
      final pending = state.open();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('로그아웃 확인'), findsOneWidget);
      for (final label in ['취소', '로그아웃']) {
        final button = find.bySemanticsLabel(
          RegExp(
            '^$label'
            r'(\n.*)?$',
          ),
        );
        expect(button, findsOneWidget);
        final node = tester.getSemantics(button);
        expect(node.flagsCollection.isButton, isTrue, reason: label);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
          reason: label,
        );
      }
      await tester.tap(_key('cancel'));
      await tester.pumpAndSettle();
      await pending;
    } finally {
      semantics.dispose();
    }
  });

  for (final exit in ['cancel', 'system_back']) {
    testWidgets('Debug 사전 안내 $exit 시 예시 계정이나 확인 팝업이 노출되지 않는다', (tester) async {
      await _pump(tester, const preview.LogoutConfirmationPreviewHost());
      expect(
        find.text(preview.logoutConfirmationPreviewNotice),
        findsOneWidget,
      );
      expect(find.text('연결됨 · 2025년 9월 6일 가입'), findsNothing);
      if (exit == 'cancel') {
        await tester.tap(find.text('취소'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(_preview('screen'), findsNothing);
    });
  }

  testWidgets('Debug 확인 후에는 미연결 안내만 표시하고 배경 예시와 라우트를 유지한다', (tester) async {
    await _enterPreview(tester);
    final original = tester.element(_preview('screen'));
    await tester.tap(_key('confirm_button'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃 기능은 아직 연결되지 않았습니다.'), findsOneWidget);
    expect(tester.element(_preview('screen')), same(original));
    expect(find.text('연결됨 · 2025년 9월 6일 가입'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.tap(_preview('back'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('로그아웃 기능은 아직 연결되지 않았습니다.'), findsNothing);
  });

  testWidgets('Debug 취소 후 재열기와 중복 클릭도 같은 배경과 단일 팝업을 유지한다', (tester) async {
    await _enterPreview(tester);
    final original = tester.element(_preview('screen'));
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
    expect(tester.element(_preview('screen')), same(original));
    expect(find.byType(SnackBar), findsNothing);
    final open = tester.widget<InkWell>(_preview('open')).onTap!;
    open();
    open();
    await tester.pumpAndSettle();
    expect(find.byType(LogoutConfirmationDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.element(_preview('screen')), same(original));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Debug 배경은 원본 로컬 자산과 지정된 아이콘 슬롯만 사용한다', (tester) async {
    await _enterPreview(tester);
    final image = tester.widget<Image>(_preview('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/pet_registration_complete_background.png',
    );
    expect(find.text('9:41'), findsNothing);
    expect(tester.getTopLeft(find.text('카카오')), const Offset(41, 173));
    expect(
      tester.getTopLeft(find.text('연결됨 · 2025년 9월 6일 가입')),
      const Offset(41, 192),
    );
    for (final element in find.byType(SvgPicture).evaluate()) {
      final svg = element.widget as SvgPicture;
      final path = (svg.bytesLoader as SvgAssetLoader).assetName;
      final render = element.renderObject! as RenderBox;
      final top = render.localToGlobal(Offset.zero);
      final bottom = render.localToGlobal(
        Offset(render.size.width, render.size.height),
      );
      expect(
        bottom.dx - top.dx,
        closeTo(path.contains('terms_chevron') ? 16 : 14, .1),
      );
      expect(
        bottom.dy - top.dy,
        closeTo(path.contains('terms_chevron') ? 16 : 14, .1),
      );
    }
    expect(find.byType(SvgPicture), findsNWidgets(3));
    await tester.tap(_key('cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('일반 앱은 기존 로그인에서 시작하고 로그아웃 미리보기 라우트를 노출하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LogoutConfirmationDialog), findsNothing);
    expect(find.text('연결됨 · 2025년 9월 6일 가입'), findsNothing);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routes
          ?.keys
          .any((r) => r.contains('logout')),
      isFalse,
    );
  });
}
