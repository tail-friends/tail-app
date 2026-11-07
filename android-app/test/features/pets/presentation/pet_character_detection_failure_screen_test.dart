import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/core/design_system/widgets/app_glass_surface.dart';
import 'package:tail_friends/features/auth/presentation/login_screen.dart';
import 'package:tail_friends/features/home/presentation/home_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_character_ai_result_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_character_detection_failure_screen.dart';
import 'package:tail_friends/features/pets/presentation/pet_registration_screen.dart';
import 'package:tail_friends/main.dart';
import 'package:tail_friends/pet_character_detection_failure_preview.dart'
    as preview;

const _fileError = '열 수 없는 파일이에요 · JPG나 PNG 사진을 골라 주세요';
const _photoNotice = '사진 선택 기능은 아직 연결되지 않았습니다. 실제 파일은 읽거나 검사하지 않습니다.';
Finder _key(String value) =>
    find.byKey(ValueKey('pet_detection_failure_$value'));
Finder _ai(String value) => find.byKey(ValueKey('pet_ai_result_$value'));
Finder _field(String value) => find.descendant(
  of: find.byKey(ValueKey(value)),
  matching: find.byType(TextFormField),
);

Future<void> _open(
  WidgetTester tester, {
  Widget home = const PetCharacterDetectionFailureScreen(),
  Size size = const Size(390, 844),
  double scale = 1,
  double top = 54,
  double bottom = 35,
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

Future<void> _launch(WidgetTester tester, {bool fileError = false}) async {
  showPetCharacterDetectionFailurePreview(
    tester.element(find.byType(PetRegistrationScreen)),
  );
  await tester.pumpAndSettle();
  expect(find.byType(PetCharacterDetectionFailureScreen), findsNothing);
  await tester.tap(find.text(fileError ? '파일 오류 예시' : '기본 미리보기'));
  await tester.pumpAndSettle();
}

void _rect(WidgetTester tester, String key, Rect expected) {
  final actual = tester.getRect(_key(key));
  expect(actual.left, closeTo(expected.left, .1));
  expect(actual.top, closeTo(expected.top, .1));
  expect(actual.width, closeTo(expected.width, .1));
  expect(actual.height, closeTo(expected.height, .1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
  });

  testWidgets('원본 안내·Jua·빈 캐릭터와 원본 자산을 표시한다', (tester) async {
    await _open(tester);
    for (final text in [
      '캐릭터 만들기',
      '사진에서 파충류를 찾지 못했어요',
      '사진 색으로 만든 캐릭터예요. 아래에서 직접 고쳐 주세요',
      '직접 고치기',
      '다른 사진 고르기',
    ]) {
      expect(find.text(text), findsOneWidget);
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'Jua');
    }
    expect(find.text('9:41'), findsNothing);
    expect(find.text(_fileError), findsNothing);
    final empty = tester.widget<SizedBox>(_key('empty_character'));
    expect(empty.child, isNull);
    expect(empty.width, 60);
    expect(empty.height, 90);
    final image = tester.widget<Image>(_key('background'));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/character_detection_failure_background.png',
    );
    expect(image.fit, BoxFit.cover);
    expect(image.excludeFromSemantics, isTrue);
    expect(find.byType(Image), findsOneWidget);
    final svg = find.descendant(
      of: _key('close_surface'),
      matching: find.byType(SvgPicture),
    );
    expect(svg, findsOneWidget);
    expect(tester.getSize(svg), const Size(24, 24));
    expect(tester.getRect(svg).size, const Size(16, 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('390×844의 헤더·안내·미리보기·버튼·Toast 좌표가 원본과 일치한다', (tester) async {
    await _open(
      tester,
      home: const PetCharacterDetectionFailureScreen(
        showFileErrorExample: true,
      ),
    );
    _rect(tester, 'close_surface', const Rect.fromLTWH(24, 62, 36, 36));
    _rect(tester, 'warning', const Rect.fromLTWH(24, 122, 342, 61));
    _rect(tester, 'preview_card', const Rect.fromLTWH(24, 203, 342, 210));
    _rect(tester, 'empty_character', const Rect.fromLTWH(165, 263, 60, 90));
    _rect(tester, 'edit', const Rect.fromLTWH(24, 433, 342, 50));
    _rect(tester, 'photo', const Rect.fromLTWH(24, 491, 342, 50));
    _rect(tester, 'file_toast', const Rect.fromLTWH(52, 770, 305, 39));
    final warning = tester.widget<AppGlassSurface>(_key('warning'));
    expect(warning.borderRadius, BorderRadius.circular(22));
    expect(warning.blur, 18);
    expect(warning.borderColor, Colors.white);
    final card = tester.widget<AppGlassSurface>(_key('preview_card'));
    expect(card.borderRadius, BorderRadius.circular(24));
    expect(card.gradient, AppColors.glassSoftGradient);
    expect(card.boxShadow.single.blurRadius, 32);
    expect(
      tester.widget<AppButton>(_key('edit')).backgroundColor,
      const Color(0xFF2F6B57),
    );
    expect(
      tester.widget<AppButton>(_key('photo')).variant,
      AppButtonVariant.ghost,
    );
  });

  testWidgets('사진 버튼은 미연결 안내만 표시하고 파일 오류나 입력기를 만들지 않는다', (tester) async {
    await _open(tester);
    final original = tester.element(
      find.byType(PetCharacterDetectionFailureScreen),
    );
    await tester.tap(_key('photo'));
    await tester.pumpAndSettle();
    expect(find.text(_photoNotice), findsOneWidget);
    expect(find.text(_fileError), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(PetCharacterAiResultScreen), findsNothing);
    expect(
      tester.element(find.byType(PetCharacterDetectionFailureScreen)),
      same(original),
    );
  });

  testWidgets('파일 오류는 명시적으로 선택한 고정 디자인 상태이며 시간이 지나도 검사를 수행하지 않는다', (
    tester,
  ) async {
    await _open(
      tester,
      home: const PetCharacterDetectionFailureScreen(
        showFileErrorExample: true,
      ),
    );
    expect(find.text(_fileError), findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
    expect(find.text(_fileError), findsOneWidget);
    await tester.tap(_key('photo'));
    await tester.pumpAndSettle();
    expect(find.text(_photoNotice), findsOneWidget);
    expect(find.text(_fileError), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  for (final fileError in [false, true]) {
    testWidgets('사전 안내에서 파일 오류 예시 $fileError를 명시적으로 선택한다', (tester) async {
      await _open(tester, home: const PetRegistrationScreen());
      await _launch(tester, fileError: fileError);
      expect(find.byType(PetCharacterDetectionFailureScreen), findsOneWidget);
      expect(find.text(_fileError), fileError ? findsOneWidget : findsNothing);
    });
  }

  for (final exit in ['cancel', 'back']) {
    testWidgets('사전 안내 $exit 시 실패 화면을 열지 않고 기존 폼을 유지한다', (tester) async {
      await _open(tester, home: const PetRegistrationScreen());
      final form = tester.element(find.byType(PetRegistrationScreen));
      await tester.enterText(_field('pet_name_field'), '모모');
      FocusManager.instance.primaryFocus?.unfocus();
      final opening = showPetCharacterDetectionFailurePreview(form);
      await tester.pumpAndSettle();
      expect(find.textContaining('실제 사진을 읽거나 검사하지 않으며'), findsOneWidget);
      expect(find.byType(PetCharacterDetectionFailureScreen), findsNothing);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('취소'));
      }
      await tester.pumpAndSettle();
      await opening;
      expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
      expect(
        tester.widget<TextFormField>(_field('pet_name_field')).controller!.text,
        '모모',
      );
    });
  }

  for (final exit in ['close', 'back']) {
    testWidgets('$exit 후 등록 폼의 이름·메모·주기를 보존하고 안내를 남기지 않는다', (tester) async {
      await _open(tester, home: const PetRegistrationScreen());
      final form = tester.element(find.byType(PetRegistrationScreen));
      final values = {
        'pet_name_field': '모모',
        'pet_memo_field': '보존할 메모',
        'pet_feeding_cycle_field': '7',
      };
      for (final entry in values.entries) {
        await tester.ensureVisible(_field(entry.key));
        await tester.enterText(_field(entry.key), entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _launch(tester, fileError: true);
      await tester.tap(_key('photo'));
      await tester.pumpAndSettle();
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('close'));
      }
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(PetRegistrationScreen)), same(form));
      expect(find.byType(PetCharacterDetectionFailureScreen), findsNothing);
      expect(find.text(_fileError), findsNothing);
      expect(find.text(_photoNotice), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      for (final entry in values.entries) {
        expect(
          tester.widget<TextFormField>(_field(entry.key)).controller!.text,
          entry.value,
        );
      }
    });

    testWidgets('직접 연 루트에서 $exit 시 로그인으로 안전하게 복귀한다', (tester) async {
      await _open(tester);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_key('close'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PetCharacterDetectionFailureScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('직접 고치기로 기존 03-3을 열고 $exit 시 실패 화면과 Toast를 보존한다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _open(
        tester,
        home: const PetCharacterDetectionFailureScreen(
          showFileErrorExample: true,
        ),
      );
      final failure = tester.element(
        find.byType(PetCharacterDetectionFailureScreen),
      );
      await tester.tap(_key('edit'));
      await tester.pumpAndSettle();
      expect(find.byType(PetCharacterAiResultScreen), findsOneWidget);
      expect(find.text('AI가 본 모습: 탠저린 레오파드 게코'), findsOneWidget);
      expect(find.text(_fileError), findsNothing);
      for (final group in ['body', 'pattern', 'color']) {
        await tester.ensureVisible(_ai('${group}_1'));
        await tester.tap(_ai('${group}_1'));
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(_ai('${group}_1')).flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );
      }
      await tester.tap(_ai('save'));
      await tester.pumpAndSettle();
      expect(find.text('디자인 미리보기입니다. 실제 캐릭터는 저장되지 않았습니다.'), findsOneWidget);
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(_ai('close'));
      }
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(PetCharacterDetectionFailureScreen)),
        same(failure),
      );
      expect(find.text(_fileError), findsOneWidget);
      expect(find.text('디자인 미리보기입니다. 실제 캐릭터는 저장되지 않았습니다.'), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      await tester.tap(_key('edit'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_ai('body_0')).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      semantics.dispose();
    });
  }

  testWidgets('직접 고치기 연속 탭으로 편집 화면을 중복해서 쌓지 않는다', (tester) async {
    await _open(tester);
    final press = tester.widget<AppButton>(_key('edit')).onPressed!;
    press();
    press();
    await tester.pumpAndSettle();
    await tester.tap(_ai('close'));
    await tester.pumpAndSettle();
    expect(find.byType(PetCharacterDetectionFailureScreen), findsOneWidget);
    expect(find.byType(PetCharacterAiResultScreen), findsNothing);
  });

  for (final size in [
    const Size(390, 844),
    const Size(360, 800),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final fileError in [false, true]) {
        testWidgets(
          '${size.width}×${size.height} 글자 $scale Toast=$fileError에서 오버플로 없이 버튼과 안내를 확인한다',
          (tester) async {
            await _open(
              tester,
              size: size,
              scale: scale,
              home: PetCharacterDetectionFailureScreen(
                showFileErrorExample: fileError,
              ),
            );
            expect(tester.getSize(_key('close')), const Size(44, 44));
            final toast = fileError ? tester.getRect(_key('file_toast')) : null;
            if (toast != null) {
              expect(toast.bottom, size.height - 35);
              expect(toast.left, greaterThanOrEqualTo(24));
              expect(toast.right, lessThanOrEqualTo(size.width - 24));
            }
            for (final key in ['edit', 'photo']) {
              await tester.ensureVisible(_key(key));
              await tester.pumpAndSettle();
              final rect = tester.getRect(_key(key));
              expect(rect.width, size.width - 48);
              expect(rect.height, greaterThanOrEqualTo(44));
              expect(
                rect.bottom,
                lessThanOrEqualTo(toast?.top ?? size.height - 35),
              );
              expect(_key(key).hitTestable(), findsOneWidget);
            }
            if (toast != null) {
              expect(tester.getRect(_key('file_toast')), toast);
            }
            await tester.tap(_key('photo'));
            await tester.pumpAndSettle();
            expect(find.text(_photoNotice), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('큰 시스템 안전 영역 안에 닫기·Toast·스크롤 버튼을 유지한다', (tester) async {
    await _open(
      tester,
      size: const Size(320, 640),
      top: 75,
      bottom: 60,
      scale: 2,
      home: const PetCharacterDetectionFailureScreen(
        showFileErrorExample: true,
      ),
    );
    expect(tester.getRect(_key('close')).top, 79);
    expect(tester.getRect(_key('file_toast')).bottom, 580);
    await tester.ensureVisible(_key('photo'));
    await tester.pumpAndSettle();
    expect(_key('photo').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Semantics는 실제 분석과 파일 검증이 아닌 예시임을 알린다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(
      tester,
      home: const PetCharacterDetectionFailureScreen(
        showFileErrorExample: true,
      ),
    );
    expect(find.bySemanticsLabel('캐릭터 인식 실패 미리보기 닫기'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('인식 실패 디자인 예시:.*실제 AI 분석은 실행되지 않았습니다.')),
      findsOneWidget,
    );
    final toast = find.bySemanticsLabel(
      RegExp('파일 오류 디자인 예시, 실제 파일은 검사하지 않았습니다.'),
    );
    expect(toast, findsOneWidget);
    expect(tester.getSemantics(toast).flagsCollection.isLiveRegion, isTrue);
    for (final key in ['edit', 'photo']) {
      final control = find.descendant(
        of: _key(key),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      );
      expect(tester.getSemantics(control).flagsCollection.isButton, isTrue);
    }
    semantics.dispose();
  });

  testWidgets('독립 Debug 진입은 안내 선택 후 열리고 닫으면 기존 등록 화면으로 복귀한다', (tester) async {
    await _open(
      tester,
      home: const preview.PetCharacterDetectionFailurePreviewHost(),
    );
    expect(find.text('디자인 미리보기'), findsOneWidget);
    expect(find.byType(PetCharacterDetectionFailureScreen), findsNothing);
    await tester.tap(find.text('파일 오류 예시'));
    await tester.pumpAndSettle();
    expect(find.text(_fileError), findsOneWidget);
    await tester.tap(_key('close'));
    await tester.pumpAndSettle();
    expect(find.byType(PetRegistrationScreen), findsOneWidget);
  });

  testWidgets('일반 앱의 초기 로그인과 라우트에 실패 미리보기를 추가하지 않는다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PetCharacterDetectionFailureScreen), findsNothing);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .routes
          ?.keys
          .any((route) => route.contains('detection-failure')),
      isFalse,
    );
  });
}
