import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/records/presentation/record_pet_picker_sheet.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/record_pet_picker_preview.dart';

Finder key(String name) => find.byKey(ValueKey('record_pet_picker_$name'));
Finder option(RecordPetPickerChoice choice) => key('option_${choice.name}');
Finder tap(RecordPetPickerChoice choice) => key('tap_${choice.name}');

class Harness extends StatefulWidget {
  const Harness({
    this.initial = RecordPetPickerChoice.ukki,
    this.onResult,
    super.key,
  });
  final RecordPetPickerChoice initial;
  final ValueChanged<RecordPetPickerChoice?>? onResult;
  @override
  State<Harness> createState() => _HarnessState();
}

class _HarnessState extends State<Harness> {
  late RecordPetPickerChoice selected = widget.initial;
  Future<void> open() async {
    final result = await showRecordPetPickerPreviewSheet(
      context,
      initialSelection: selected,
    );
    widget.onResult?.call(result);
    if (result != null && mounted) setState(() => selected = result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF7F0),
    body: SafeArea(
      child: Column(
        children: [
          Text('호출 화면 선택: ${selected.name}'),
          TextButton(onPressed: open, child: const Text('열기')),
        ],
      ),
    ),
  );
}

Future<void> pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Widget home = const Harness(),
  double bottom = 24,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: 54, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: 54, bottom: bottom);
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

Future<void> show(WidgetTester tester) async {
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('Figma sheet geometry, original icons and one-character avatars', (
    tester,
  ) async {
    await pump(tester);
    await show(tester);
    expect(tester.getRect(key('sheet')), const Rect.fromLTWH(0, 365, 390, 479));
    expect(
      tester.getRect(key('options')),
      const Rect.fromLTWH(25, 456, 340, 353),
    );
    expect(tester.getSize(key('grabber')), const Size(32, 4));
    expect(tester.getSize(key('close')), const Size(44, 44));
    final glass = tester.widget<AppGlassSurface>(key('sheet'));
    expect(glass.blur, 12);
    expect(
      glass.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(32)),
    );
    expect(glass.borderColor, const Color(0xE6FFFFFF));
    final route =
        ModalRoute.of(tester.element(key('sheet'))) as ModalBottomSheetRoute;
    expect(route.barrierColor, const Color(0x332F6B57));
    expect(route.barrierLabel, '친구 선택 취소');
    expect(route.useSafeArea, isTrue);
    expect(find.text('친구 선택'), findsOneWidget);
    expect(find.text('기록을 볼 친구를 골라 주세요'), findsOneWidget);
    expect(find.text('7마리'), findsOneWidget);
    final expected = [
      ('전체 친구', '7마리', null),
      ('욱이', '레오파드 게코', '욱'),
      ('치토', '비어디드 드래곤', '치'),
      ('레오', '크레스티드 게코', '레'),
      ('세라', '볼 파이톤', '세'),
      ('토토', '육지거북', '토'),
    ];
    for (final (index, choice) in RecordPetPickerChoice.values.indexed) {
      final row = expected[index];
      expect(choice.label, row.$1);
      expect(choice.description, row.$2);
      expect(choice.avatar, row.$3);
      expect(find.text(row.$1), findsOneWidget);
      expect(find.text(row.$2), findsOneWidget);
      expect(tester.getSize(option(choice)).height, greaterThanOrEqualTo(44));
      final indicator = tester.widget<SvgPicture>(
        key('indicator_${choice.name}'),
      );
      expect(
        (indicator.bytesLoader as SvgAssetLoader).assetName,
        'assets/icons/record_pet_picker_${choice == RecordPetPickerChoice.ukki ? 'selected' : 'unselected'}.svg',
      );
      expect(
        tester.getSize(key('indicator_${choice.name}')),
        const Size(18, 18),
      );
      if (row.$3 != null) {
        expect(find.text(row.$3!), findsOneWidget);
        final avatar = tester.widget<Container>(key('avatar_${choice.name}'));
        expect(
          tester.getSize(key('avatar_${choice.name}')),
          const Size(36, 36),
        );
        expect(
          (avatar.decoration as BoxDecoration).color,
          choice == RecordPetPickerChoice.toto
              ? const Color(0xFF736E65)
              : const Color(0xFF2F6B57),
        );
      }
      if (index > 0) {
        expect(
          tester.getTopLeft(option(choice)).dy,
          greaterThan(
            tester
                .getTopLeft(option(RecordPetPickerChoice.values[index - 1]))
                .dy,
          ),
        );
      }
    }
    final paths = tester
        .widgetList<SvgPicture>(find.byType(SvgPicture))
        .map((svg) => (svg.bytesLoader as SvgAssetLoader).assetName)
        .toSet();
    expect(paths, {
      'assets/icons/notification_time_close.svg',
      'assets/icons/record_pet_picker_selected.svg',
      'assets/icons/record_pet_picker_unselected.svg',
    });
    expect(find.byType(Image), findsNothing);
    for (final path in paths) {
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected choice semantics provides a TalkBack tap action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await show(tester);
    for (final choice in RecordPetPickerChoice.values) {
      final data = tester.getSemantics(option(choice)).getSemanticsData();
      expect(data.label, '${choice.label}, ${choice.description}');
      expect(
        data.flagsCollection.isSelected,
        choice == RecordPetPickerChoice.ukki
            ? ui.Tristate.isTrue
            : ui.Tristate.isFalse,
      );
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    }
    final selectedNode = tester.getSemantics(
      option(RecordPetPickerChoice.chito),
    );
    selectedNode.owner!.performAction(selectedNode.id, ui.SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.text('호출 화면 선택: chito'), findsOneWidget);
    handle.dispose();
  });

  for (final choice in RecordPetPickerChoice.values) {
    testWidgets(
      'returns ${choice.name}, closes once and restores injected selection',
      (tester) async {
        final results = <RecordPetPickerChoice?>[];
        await pump(tester, home: Harness(onResult: results.add));
        await show(tester);
        await tester.tap(tap(choice));
        await tester.pumpAndSettle();
        expect(results, [choice]);
        expect(key('sheet'), findsNothing);
        expect(find.text('호출 화면 선택: ${choice.name}'), findsOneWidget);
        await show(tester);
        final semantics = tester.widget<Semantics>(option(choice));
        expect(semantics.properties.selected, isTrue);
        await tester.tap(key('close'));
        await tester.pumpAndSettle();
        expect(results, [choice, null]);
        expect(find.text('호출 화면 선택: ${choice.name}'), findsOneWidget);
      },
    );
  }

  for (final dismissal in ['close', 'barrier', 'back', 'drag']) {
    testWidgets('$dismissal cancels without changing the previous selection', (
      tester,
    ) async {
      final results = <RecordPetPickerChoice?>[];
      await pump(
        tester,
        home: Harness(
          initial: RecordPetPickerChoice.leo,
          onResult: results.add,
        ),
      );
      await show(tester);
      switch (dismissal) {
        case 'close':
          await tester.tap(key('close'));
        case 'barrier':
          await tester.tapAt(const Offset(10, 200));
        case 'back':
          await tester.binding.handlePopRoute();
        case 'drag':
          await tester.drag(key('grabber'), const Offset(0, 500));
      }
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(key('sheet'), findsNothing);
      expect(find.text('호출 화면 선택: leo'), findsOneWidget);
    });
  }

  testWidgets('duplicate entry and rapid row/close taps cannot pop the host', (
    tester,
  ) async {
    final results = <RecordPetPickerChoice?>[];
    await pump(tester, home: Harness(onResult: results.add));
    final state = tester.state<_HarnessState>(find.byType(Harness));
    state.open();
    state.open();
    await tester.pumpAndSettle();
    expect(key('sheet'), findsOneWidget);
    expect(results, [null]);
    final first = tester
        .widget<InkWell>(tap(RecordPetPickerChoice.chito))
        .onTap!;
    final second = tester
        .widget<InkWell>(tap(RecordPetPickerChoice.toto))
        .onTap!;
    final close = tester.widget<InkWell>(key('close')).onTap!;
    first();
    second();
    close();
    state.open();
    await tester.pumpAndSettle();
    expect(results.whereType<RecordPetPickerChoice>().toList(), [
      RecordPetPickerChoice.chito,
    ]);
    expect(key('sheet'), findsNothing);
    expect(find.byType(Harness), findsOneWidget);
    await show(tester);
    expect(key('sheet'), findsOneWidget);
  });

  testWidgets('standalone widget emits at most one result', (tester) async {
    final results = <RecordPetPickerChoice?>[];
    await pump(
      tester,
      home: Scaffold(body: RecordPetPickerSheet(onResult: results.add)),
    );
    tester.widget<InkWell>(tap(RecordPetPickerChoice.sera)).onTap!();
    tester.widget<InkWell>(tap(RecordPetPickerChoice.ukki)).onTap!();
    tester.widget<InkWell>(key('close')).onTap!();
    expect(results, [RecordPetPickerChoice.sera]);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('accessible scrolling and no overflow $size × $scale', (
        tester,
      ) async {
        await pump(tester, size: size, scale: scale);
        await show(tester);
        final sheet = tester.getRect(key('sheet'));
        expect(sheet.top, greaterThanOrEqualTo(54));
        expect(sheet.bottom, size.height);
        for (final choice in RecordPetPickerChoice.values) {
          await tester.ensureVisible(option(choice));
          await tester.pumpAndSettle();
          expect(tap(choice).hitTestable(), findsOneWidget);
          expect(
            tester.getSize(option(choice)).height,
            greaterThanOrEqualTo(44),
          );
          for (final text in [choice.label, choice.description]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(text),
            );
            expect(paragraph.didExceedMaxLines, isFalse);
          }
        }
        expect(tester.getSize(key('close')), const Size(44, 44));
        expect(tester.takeException(), isNull);
        await tester.tap(tap(RecordPetPickerChoice.toto));
        await tester.pumpAndSettle();
        expect(find.text('호출 화면 선택: toto'), findsOneWidget);
      });
    }
  }

  testWidgets(
    'large bottom SafeArea leaves last option above system navigation',
    (tester) async {
      await pump(tester, bottom: 48);
      await show(tester);
      expect(
        tester.getRect(option(RecordPetPickerChoice.toto)).bottom,
        lessThanOrEqualTo(844 - 48),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preview discloses fixture data, returns local result and keeps cancel value',
    (tester) async {
      await pump(tester, home: const RecordPetPickerPreviewHost());
      expect(find.text(recordPetPickerPreviewNotice), findsOneWidget);
      expect(key('sheet'), findsNothing);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('디자인 미리보기 선택 전'), findsOneWidget);
      await tester.tap(find.text('친구 선택 미리보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      await tester.tap(tap(RecordPetPickerChoice.allFriends));
      await tester.pumpAndSettle();
      expect(find.text('디자인 미리보기 선택: 전체 친구'), findsOneWidget);
      await tester.tap(find.text('친구 선택 미리보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('미리보기 열기'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('디자인 미리보기 선택: 전체 친구'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('normal application still starts on login', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RecordPetPickerSheet), findsNothing);
  });
}
