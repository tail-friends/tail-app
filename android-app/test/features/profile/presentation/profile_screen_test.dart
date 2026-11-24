import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/auth/presentation/terms_preview_screen.dart';
import 'package:tail_friends/features/profile/presentation/account_management_screen.dart';
import 'package:tail_friends/features/profile/presentation/data_photo_settings_screen.dart';
import 'package:tail_friends/features/profile/presentation/inquiry_screen.dart';
import 'package:tail_friends/features/profile/presentation/notices_screen.dart';
import 'package:tail_friends/features/profile/presentation/notification_settings_screen.dart';
import 'package:tail_friends/features/profile/presentation/privacy_policy_screen.dart';
import 'package:tail_friends/features/profile/presentation/profile_edit_screen.dart';
import 'package:tail_friends/features/profile/presentation/profile_screen.dart';
import 'package:tail_friends/features/profile/presentation/terrarium_theme_screen.dart';
import 'package:tail_friends/features/profile/presentation/warning_units_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/profile_preview.dart';

Finder key(String value) => find.byKey(ValueKey('profile_$value'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const ProfileScreen.preview(),
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

Future<void> menu(WidgetTester tester, String label) async {
  final target = key(label == '프로필 편집' ? 'edit' : 'menu_$label');
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showProfilePreview(context),
        child: const Text('열기'),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Figma 09 geometry, exact assets and selected bottom tab', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, size: const Size(390, 1124));
    expect(tester.getRect(key('card')), const Rect.fromLTWH(24, 101, 342, 90));
    expect(tester.getRect(key('stats')), const Rect.fromLTWH(24, 211, 342, 68));
    expect(
      tester.getRect(key('navigation')),
      const Rect.fromLTWH(24, 1046, 342, 54),
    );
    expect(find.text('민준'), findsOneWidget);
    for (final text in ['카카오 계정으로 로그인 중', '7', '128', '410', '사막', '1.0.0']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('준비 중'), findsNWidgets(3));
    final paths = tester
        .widgetList<SvgPicture>(find.byType(SvgPicture))
        .map((svg) => (svg.bytesLoader as SvgAssetLoader).assetName)
        .toList();
    for (final path in [
      'home_bell.svg',
      'profile_settings_home.svg',
      'home_first_visit_record.svg',
      'profile_support_user.svg',
      'profile_nav_user.svg',
    ]) {
      expect(paths, contains('assets/icons/$path'));
      expect(
        (await rootBundle.load('assets/icons/$path')).lengthInBytes,
        greaterThan(0),
      );
    }
    expect(
      (await rootBundle.load(
        'assets/images/profile_background.png',
      )).lengthInBytes,
      greaterThan(0),
    );
    expect(
      tester.widget<AppGlassSurface>(key('card')).gradient,
      AppColors.glassSoftGradient,
    );
    final selected = find.byKey(
      const ValueKey('app_bottom_navigation_profile_touch_target'),
    );
    expect(
      tester
          .getSemantics(selected)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    for (final tab in AppTab.values) {
      final target = find.byKey(
        ValueKey('app_bottom_navigation_${tab.name}_touch_target'),
      );
      expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    }
    expect(tester.getSize(key('edit')).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  for (final (label, type) in <(String, Type)>[
    ('프로필 편집', ProfileEditScreen),
    ('알림 설정', NotificationSettingsScreen),
    ('사육장 테마', TerrariumThemeScreen),
    ('경고 기준 · 온도 단위', WarningUnitsScreen),
    ('데이터 · 사진 · 내보내기', DataPhotoSettingsScreen),
    ('공지사항', NoticesScreen),
    ('문의하기', InquiryScreen),
    ('서비스 이용약관', TermsPreviewScreen),
    ('개인정보 처리방침', PrivacyPolicyScreen),
    ('계정 관리', AccountManagementScreen),
  ]) {
    testWidgets('$label reuses merged preview, duplicate guard and safe return', (
      tester,
    ) async {
      await open(tester);
      await menu(tester, label);
      expect(find.byType(AlertDialog), findsOneWidget);
      // A repeated callback during an open preview must not push another dialog.
      final target = key(label == '프로필 편집' ? 'edit' : 'menu_$label');
      tester.widget<InkWell>(target).onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(type), findsNothing);
      await menu(tester, label);
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('screen'), findsOneWidget);
      expect(find.text('민준'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unimplemented menus and tabs only show notices', (tester) async {
    await open(tester);
    for (final label in ['일정 · 재고', '건강 관리']) {
      await menu(tester, label);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(key('screen'), findsOneWidget);
    }
    for (final tab in AppTab.values) {
      await tester.tap(
        find.byKey(ValueKey('app_bottom_navigation_${tab.name}_touch_target')),
      );
      await tester.pumpAndSettle();
      expect(key('screen'), findsOneWidget);
    }
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'disclaimer precedes sample data; cancellation and back preserve login',
    (tester) async {
      await open(tester, home: const ProfilePreviewHost());
      expect(find.text(profilePreviewNotice), findsOneWidget);
      expect(key('screen'), findsNothing);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await open(tester, home: const ProfilePreviewHost());
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      expect(key('screen'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('scroll, fixed navigation and overflow $size × $scale', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final nav = tester.getRect(key('navigation'));
        await tester.ensureVisible(find.text('앱 버전'));
        await tester.pumpAndSettle();
        expect(find.text('앱 버전').hitTestable(), findsOneWidget);
        expect(tester.getRect(key('navigation')), nav);
        expect(nav.bottom, lessThanOrEqualTo(size.height - 24));
        for (final label in ['계정 관리', '개인정보 처리방침']) {
          final target = key('menu_$label');
          expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('normal app still starts at LoginScreen', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });
}
