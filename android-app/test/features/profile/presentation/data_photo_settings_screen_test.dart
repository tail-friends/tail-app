import 'package:tail_friends/features/profile/presentation/vet_pdf_report_screen.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/data_photo_settings_preview.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/profile/presentation/data_photo_settings_screen.dart';
import 'package:tail_friends/main.dart';

Finder key(String name) => find.byKey(ValueKey('data_photo_$name'));
Future<void> open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const DataPhotoSettingsScreen.preview(),
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

bool keep(WidgetTester tester) =>
    tester.widget<Semantics>(key('keep')).properties.toggled!;

class Entry extends StatelessWidget {
  const Entry({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showDataPhotoSettingsPreview(context),
        child: const Text('열기'),
      ),
    ),
  );
}

Future<void> accept(WidgetTester tester) async {
  await tester.tap(find.text('미리보기 열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });
  testWidgets(
    'Figma initial expanded card geometry and local original assets',
    (tester) async {
      await open(tester);
      expect(
        tester.getRect(key('header')),
        const Rect.fromLTWH(24, 58, 342, 44),
      );
      expect(
        tester.getRect(key('photos')),
        const Rect.fromLTWH(24, 161, 342, 133),
      );
      expect(
        tester.getRect(key('confirm')),
        const Rect.fromLTWH(24, 312, 342, 121),
      );
      expect(
        tester.getRect(key('exports')),
        const Rect.fromLTWH(24, 492, 342, 133),
      );
      for (final name in ['cancel', 'delete']) {
        expect(tester.getSize(key('${name}_visual')), const Size(150, 36));
        expect(tester.getSize(key(name)), const Size(150, 44));
      }
      expect(tester.getSize(key('switch')), const Size(40, 24));
      expect(
        (tester.widget<Image>(key('background')).image as AssetImage).assetName,
        'assets/images/data_photo_background.png',
      );
      expect(
        tester.widget<AppGlassSurface>(key('confirm')).borderRadius,
        BorderRadius.circular(22),
      );
      expect(find.text('9:41'), findsNothing);
    },
  );
  testWidgets('all example labels and dates remain static', (tester) async {
    await open(tester);
    for (final text in [
      '데이터 · 사진',
      '원본 사진',
      '원본 사진 보관',
      '실사풍 캐릭터 전환 때 다시 올리지 않아도 돼요',
      '보관 사진 모두 삭제',
      '현재 7장 · 약 2.1MB',
      '보관한 원본 사진 7장을 지울까요?',
      '캐릭터와 썸네일은 그대로 남아요',
      '기록 내보내기 · 이후',
      'CSV로 내보내기',
      '기간: 2026.01.01 – 10.20',
      '수의사용 PDF 리포트',
      '최근 3개월 체중·급여·탈피·진료 요약',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(keep(tester), isTrue);
  });
  testWidgets('local switch toggles and has accessible state', (tester) async {
    final h = tester.ensureSemantics();
    try {
      await open(tester);
      expect(
        tester.getSemantics(key('keep')).flagsCollection.isToggled,
        ui.Tristate.isTrue,
      );
      await tester.tap(key('keep'));
      await tester.pump();
      expect(keep(tester), isFalse);
      expect(
        (tester.widget<Image>(key('switch')).image as AssetImage).assetName,
        'assets/images/notification_time_switch_off.png',
      );
      final node = tester.getSemantics(key('keep'));
      tester.binding.performSemanticsAction(
        ui.SemanticsActionEvent(
          type: ui.SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pump();
      expect(keep(tester), isTrue);
      expect(key('confirm'), findsOneWidget);
      expect(tester.getSize(key('keep')).height, greaterThanOrEqualTo(44));
    } finally {
      h.dispose();
    }
  });
  testWidgets(
    'cancel hides confirmation and repeated delete-row taps reopen exactly one card',
    (tester) async {
      await open(tester);
      await tester.tap(key('keep'));
      await tester.pump();
      await tester.tap(key('cancel'));
      await tester.pumpAndSettle();
      expect(key('confirm'), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tester.tap(key('delete_row'));
        await tester.pump();
      }
      expect(key('confirm'), findsOneWidget);
      expect(keep(tester), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets('delete never removes examples or reports successful deletion', (
    tester,
  ) async {
    await open(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(key('delete'));
      await tester.pumpAndSettle();
    }
    expect(find.text('미리보기에서는 사진을 삭제하지 않습니다.'), findsOneWidget);
    expect(find.text('현재 7장 · 약 2.1MB'), findsOneWidget);
    expect(key('confirm'), findsOneWidget);
    expect(keep(tester), isTrue);
  });
  // PDF now opens a guarded design preview; validate disclosure before navigation.
  for (final name in ['pdf']) {
    testWidgets('$name shows design disclosure before navigation', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(key(name));
      await tester.pumpAndSettle();
      expect(find.text(vetPdfReportPreviewNotice), findsOneWidget);
      expect(key('screen'), findsOneWidget);
      expect(find.text('기간: 2026.01.01 – 10.20'), findsOneWidget);
    });
  }
  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$size scale $scale scroll and text remain usable', (
        tester,
      ) async {
        await open(tester, size: size, scale: scale);
        final header = tester.getRect(key('header'));
        for (final text in [
          '실사풍 캐릭터 전환 때 다시 올리지 않아도 돼요',
          '보관한 원본 사진 7장을 지울까요?',
          '캐릭터와 썸네일은 그대로 남아요',
          '최근 3개월 체중·급여·탈피·진료 요약',
        ]) {
          final p = tester.renderObject<RenderParagraph>(find.text(text));
          expect(p.didExceedMaxLines, isFalse);
          for (var i = 0; i < text.length; i++) {
            if (text[i].trim().isEmpty) continue;
            for (final b in p.getBoxesForSelection(
              TextSelection(baseOffset: i, extentOffset: i + 1),
            )) {
              expect(b.right, lessThanOrEqualTo(p.size.width + .1));
            }
          }
        }
        await tester.ensureVisible(key('delete'));
        await tester.pumpAndSettle();
        await tester.tap(key('delete'));
        await tester.pumpAndSettle();
        expect(find.text('미리보기에서는 사진을 삭제하지 않습니다.'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(key('pdf'));
        await tester.pumpAndSettle();
        expect(key('pdf').hitTestable(), findsOneWidget);
        await tester.tap(key('pdf'));
        await tester.pumpAndSettle();
        expect(tester.getRect(key('header')), header);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('entry disclosure cancellation and duplicate route protection', (
    tester,
  ) async {
    await open(tester, home: const Entry());
    await tester.tap(find.text('열기'));
    await tester.tap(find.text('열기'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(dataPhotoSettingsPreviewNotice), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(key('screen'), findsNothing);
  });
  for (final system in [false, true]) {
    testWidgets(
      '${system ? 'system' : 'header'} back and fresh preview reset',
      (tester) async {
        await open(tester, home: const Entry());
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await accept(tester);
        await tester.tap(key('keep'));
        await tester.pump();
        await tester.tap(key('cancel'));
        await tester.pump();
        if (system) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(key('back'));
        }
        await tester.pumpAndSettle();
        expect(find.text('열기'), findsOneWidget);
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await accept(tester);
        expect(keep(tester), isTrue);
        expect(key('confirm'), findsOneWidget);
      },
    );
  }
  testWidgets('preview host disclosure and standalone root back are safe', (
    tester,
  ) async {
    await open(tester, home: const DataPhotoSettingsPreviewHost());
    expect(find.text(dataPhotoSettingsPreviewNotice), findsOneWidget);
    await accept(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
  testWidgets(
    'all actions avoid network and file-service channels; normal app remains login',
    (tester) async {
      var requests = 0;
      final messages = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            messages.add(call.method);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await HttpOverrides.runZoned(
        () async {
          await open(tester);
          for (final name in ['keep', 'delete', 'pdf']) {
            await tester.tap(key(name));
            await tester.pumpAndSettle();
          }
        },
        createHttpClient: (_) {
          requests++;
          throw StateError('Unexpected network');
        },
      );
      expect(requests, 0);
      expect(
        messages.where(
          (x) =>
              x.contains('share') || x.contains('file') || x.contains('delete'),
        ),
        isEmpty,
      );
      await tester.pumpWidget(const TailFriendsApp());
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
