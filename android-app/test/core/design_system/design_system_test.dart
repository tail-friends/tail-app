import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/core/design_system/design_system.dart';
import 'package:tail_friends/features/design_system_preview/design_system_preview_screen.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.mist,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('세 가지 variant를 표시하고 탭을 전달한다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: AppButtonVariant.values
                .map(
                  (variant) => AppButton(
                    label: variant.name,
                    variant: variant,
                    onPressed: () => taps++,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );

      for (final variant in AppButtonVariant.values) {
        expect(find.text(variant.name), findsOneWidget);
        await tester.tap(find.text(variant.name));
      }
      expect(taps, 3);
    });

    testWidgets('loading 중에는 중복 탭을 차단한다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppButton(label: '저장', isLoading: true, onPressed: () => taps++)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });
  });

  testWidgets('소셜 버튼은 세 제공자와 18px 원본 로고를 사용한다', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: AppSocialProvider.values
              .map(
                (provider) =>
                    AppSocialButton(provider: provider, onPressed: () {}),
              )
              .toList(growable: false),
        ),
      ),
    );

    expect(find.text('Apple로 계속하기'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
    final logos = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(logos, hasLength(3));
    expect(
      logos.every((logo) => logo.width == 18 && logo.height == 18),
      isTrue,
    );
  });

  testWidgets('TextField는 입력 길이와 오류 상태를 반영한다', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 342,
          child: AppTextField(
            label: '이름',
            controller: controller,
            hintText: '예: 욱이',
            errorText: '이름을 확인해 주세요',
            maxLength: 3,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '도마뱀친구');
    expect(controller.text.characters.length, 3);
    expect(find.text('이름을 확인해 주세요'), findsOneWidget);
  });

  testWidgets('Chip은 모든 tone의 레이블을 표시한다', (tester) async {
    await tester.pumpWidget(
      _host(
        Wrap(
          children: AppChipTone.values
              .map((tone) => AppChip(label: tone.name, tone: tone))
              .toList(growable: false),
        ),
      ),
    );

    for (final tone in AppChipTone.values) {
      expect(find.text(tone.name), findsOneWidget);
    }
  });

  testWidgets('BottomNavigation은 선택 탭 콜백과 16px 아이콘을 제공한다', (tester) async {
    AppTab? selected;
    await tester.pumpWidget(
      _host(
        AppBottomNavigation(
          currentTab: AppTab.habitat,
          onTabSelected: (tab) => selected = tab,
        ),
      ),
    );

    await tester.tap(find.text('기록'));
    expect(selected, AppTab.records);
    final icons = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(icons, hasLength(4));
    expect(
      icons.every((icon) => icon.width == 16 && icon.height == 16),
      isTrue,
    );
  });

  testWidgets('기록 행과 말풍선이 Figma 텍스트를 표시한다', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSpeechBubble(message: '배고파요! 밥 주세요'),
            AppRecordRow(title: '급여', meta: '귀뚜라미 5마리', trailing: '오늘'),
          ],
        ),
      ),
    );

    expect(find.text('배고파요! 밥 주세요'), findsOneWidget);
    expect(find.text('급여'), findsOneWidget);
    expect(find.text('귀뚜라미 5마리'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
  });

  testWidgets('Preview 화면이 주요 섹션을 렌더링한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.mist,
        home: const DesignSystemPreviewScreen(),
      ),
    );

    expect(find.text('디자인 시스템 미리보기'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
  });
}
