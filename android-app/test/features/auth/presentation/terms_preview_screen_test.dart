import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/auth/presentation/terms_preview_screen.dart';
import 'package:tail_friends/main.dart';

const _headings = ['제1조 목적', '제2조 회원가입', '제3조 사진 및 캐릭터', '제4조 회원 탈퇴'];
const _bodies = [
  '이 약관은 꼬리친구(이하 "서비스")가 제공하는 파충류 사육 기록 및 캐릭터 서비스의 이용 조건과 절차, 회원과 서비스의 권리·의무를 정하는 것을 목적으로 합니다.',
  '회원은 Apple, 카카오, Google 계정으로 가입할 수 있으며, 약관에 동의함으로써 이용계약이 성립됩니다.',
  '회원이 업로드한 사진은 캐릭터 생성 목적으로만 사용되며, 생성 완료 후 원본은 회원의 요청에 따라 삭제할 수 있습니다.',
  '회원은 마이 > 계정 관리에서 언제든지 탈퇴할 수 있으며, 탈퇴 시 기록과 캐릭터는 즉시 삭제됩니다.',
];

Finder get _back => find.byKey(const ValueKey('terms_back_button'));
Finder get _scroll => find.byKey(const ValueKey('terms_scroll'));

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = const EdgeInsets.only(top: 54, bottom: 24),
}) async {
  _setSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.mist,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: padding,
          viewPadding: padding,
        ),
        child: child!,
      ),
      home: const TermsPreviewScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
  });

  testWidgets('Figma의 시행일과 네 조항을 시안 문구 그대로 표시한다', (tester) async {
    await _open(tester);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('시행일 2026년 11월 1일'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(find.text(_headings[i]), findsOneWidget);
      expect(find.text(_bodies[i]), findsOneWidget);
    }
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(AppButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844 기준에서 헤더·간격·Glass 카드와 에셋 크기를 유지한다', (tester) async {
    await _open(tester);
    final header = find.byKey(const ValueKey('terms_header'));
    final date = find.byKey(const ValueKey('terms_effective_date'));
    final card = find.byKey(const ValueKey('terms_card'));
    expect(tester.getRect(header), const Rect.fromLTWH(24, 58, 342, 44));
    expect(tester.getTopLeft(date), const Offset(24, 122));
    expect(tester.getTopLeft(card), const Offset(24, 156));
    expect(tester.getSize(card).width, 342);
    expect(tester.getSize(card).height, closeTo(361, 1));
    expect(tester.getTopLeft(find.text('제1조 목적')), const Offset(45, 177));
    expect(tester.getCenter(find.text('서비스 이용약관')).dx, 195);
    expect(tester.getSize(_back), const Size(44, 44));
    expect(
      tester.getSize(
        find.descendant(of: _back, matching: find.byType(AppGlassSurface)),
      ),
      const Size(36, 36),
    );
    expect(tester.getSize(find.byType(SvgPicture)), const Size(16, 16));
    expect(
      tester.getSize(find.byKey(const ValueKey('terms_background'))),
      const Size(390, 844),
    );
    final surface = tester.widget<AppGlassSurface>(card);
    expect(surface.borderRadius, BorderRadius.circular(22));
    final body = tester.widget<Text>(find.text(_bodies[0]));
    expect(body.style!.fontFamily, 'Jua');
    expect(body.style!.fontSize, 13);
    expect(body.style!.height, 19 / 13);
  });

  testWidgets('앱 시작은 로그인이고 Debug 약관 경로를 닫으면 원래 로그인으로 돌아온다', (tester) async {
    _setSize(tester, const Size(390, 844));
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TermsPreviewScreen), findsNothing);
    Navigator.of(
      tester.element(find.byType(LoginScreen)),
    ).pushNamed('/terms-preview');
    await tester.pumpAndSettle();
    expect(find.byType(TermsPreviewScreen), findsOneWidget);
    await tester.tap(_back);
    await tester.pumpAndSettle();
    expect(find.byType(TermsPreviewScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    final google = find.byKey(const ValueKey('login_google_button'));
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(find.text('로그인 기능은 준비 중입니다.'), findsOneWidget);
  });

  testWidgets('직접 연 약관 화면도 상단 뒤로가기로 로그인에 안전하게 복귀한다', (tester) async {
    await _open(tester);
    await tester.tap(_back);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TermsPreviewScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('직접 연 약관 화면에서 Android 뒤로가기도 로그인으로 복귀한다', (tester) async {
    await _open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TermsPreviewScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('쌓인 약관 경로는 시스템 뒤로가기로 기존 경로만 pop한다', (tester) async {
    _setSize(tester, const Size(390, 844));
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byType(LoginScreen)),
    ).pushNamed('/terms-preview');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TermsPreviewScreen), findsNothing);
  });

  testWidgets('뒤로가기 접근성 이름과 조항 제목 의미를 제공한다', (tester) async {
    await _open(tester);
    expect(find.bySemanticsLabel('뒤로가기'), findsOneWidget);
    for (final title in _headings) {
      expect(
        tester.getSemantics(find.text(title)).flagsCollection.isHeader,
        isTrue,
      );
    }
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size 글자 $scale배에서 네 조항 끝까지 가로 넘침 없이 스크롤한다', (tester) async {
        await _open(tester, size: size, scale: scale);
        expect(tester.takeException(), isNull);
        final initialBack = tester.getRect(_back);
        for (var i = 0; i < 4; i++) {
          final body = find.byKey(ValueKey('terms_article_${i + 1}_body'));
          await tester.ensureVisible(body);
          await tester.pumpAndSettle();
          final rect = tester.getRect(body);
          expect(rect.left, greaterThanOrEqualTo(24));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
          expect(tester.takeException(), isNull, reason: '조항 ${i + 1}');
        }
        final last = tester.getRect(
          find.byKey(const ValueKey('terms_article_4_body')),
        );
        expect(last.bottom, lessThanOrEqualTo(size.height - 24));
        expect(tester.getRect(_back), initialBack);
        await tester.tap(_back);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    }
  }

  testWidgets('큰 글자에서 실제 스크롤 후에도 헤더를 고정하고 SafeArea를 지킨다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      scale: 2,
      padding: const EdgeInsets.fromLTRB(12, 60, 12, 34),
    );
    final top = tester.getTopLeft(_back);
    expect(top.dx, 36);
    expect(top.dy, greaterThanOrEqualTo(60));
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: _scroll, matching: find.byType(Scrollable)),
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(_scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(tester.getTopLeft(_back), top);
    expect(tester.takeException(), isNull);
  });
}
