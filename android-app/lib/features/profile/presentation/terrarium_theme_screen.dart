import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const terrariumThemePreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 사용 중인 테마는 예시이며 실제 사육장 설정이나 사진은 변경되지 않습니다.';
final _previewInProgress = Expando<bool>();

Future<void> showTerrariumThemePreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewInProgress[navigator] == true) return;
  _previewInProgress[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(terrariumThemePreviewNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('미리보기 열기'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted || !navigator.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => const TerrariumThemeScreen.preview()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// A static design catalogue. "사용 중" is a Figma example, not user data.
class TerrariumThemeScreen extends StatefulWidget {
  const TerrariumThemeScreen.preview({super.key});
  @override
  State<TerrariumThemeScreen> createState() => _TerrariumThemeScreenState();
}

class _TerrariumThemeScreenState extends State<TerrariumThemeScreen> {
  static const _names = ['사막', '열대우림', '바위 협곡', '물가', '달밤', '내 사육장 사진으로'];
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  void _unavailable() {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('테마 변경 기능은 아직 연결되지 않았습니다.')));
  }

  void _back() {
    _messenger.currentState?.removeCurrentSnackBar();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            key: const ValueKey('terrarium_theme_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma SVG bg 408:2346 has filters; the PNG matches this local asset.
                Image.asset(
                  'assets/images/account_withdrawal_background.png',
                  key: const ValueKey('terrarium_theme_background'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      math.max(4, 58 - MediaQuery.paddingOf(context).top),
                      24,
                      0,
                    ),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          key: const ValueKey('terrarium_theme_header'),
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            children: [
                              Semantics(
                                button: true,
                                label: '뒤로가기',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: const ValueKey('terrarium_theme_back'),
                                    onTap: _back,
                                    borderRadius: BorderRadius.circular(999),
                                    child: SizedBox.square(
                                      dimension: 44,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: AppGlassSurface(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: SizedBox.square(
                                            dimension: 36,
                                            child: Center(
                                              child: SizedBox.square(
                                                dimension: 16,
                                                child: SvgPicture.asset(
                                                  'assets/icons/terms_chevron_left.svg',
                                                  excludeFromSemantics: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    '사육장 테마',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontFamily: 'Jua',
                                      color: _ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 44),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('terrarium_theme_scroll'),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '개체 상세 맨 위 사육장 배경이 바뀌어요',
                                  style: AppTypography.captionRegular.copyWith(
                                    fontFamily: 'Jua',
                                    color: _tertiary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) => Column(
                                    key: const ValueKey('terrarium_theme_grid'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (var row = 0; row < 3; row++) ...[
                                        if (row > 0) const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Figma flex shares content widths, before padding/border.
                                            SizedBox(
                                              width: row == 0
                                                  ? (constraints.maxWidth -
                                                                10 -
                                                                48) /
                                                            2 +
                                                        22
                                                  : (constraints.maxWidth -
                                                            10) /
                                                        2,
                                              child: _card(row * 2),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(child: _card(row * 2 + 1)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(int index) {
    final selected = index == 0;
    final dimmed = index == 1 || index == 5;
    final status = selected
        ? '사용 중'
        : index == 5
        ? '확장'
        : '미리보기';
    final surface = AppGlassSurface(
      key: ValueKey('terrarium_theme_surface_$index'),
      borderRadius: BorderRadius.circular(22),
      gradient: selected
          ? const LinearGradient(colors: [Colors.white, Colors.white])
          : AppColors.glassSoftGradient,
      borderColor: selected ? const Color(0xE6E6E1D6) : Colors.white,
      padding: EdgeInsets.all(selected ? 11 : 13),
      boxShadow: selected
          ? const [
              BoxShadow(
                color: Color(0x0F3D2E1F),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: Color(0x1F3D2E1F),
                offset: Offset(0, 4),
                blurRadius: 14,
              ),
            ]
          : const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              foregroundPainter: index == 5 ? const _DashedOutline() : null,
              child: ColoredBox(
                key: ValueKey('terrarium_theme_placeholder_$index'),
                color: const Color(0xFFE4DDD3),
                child: SizedBox(
                  height: 96,
                  child: Stack(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          'assets/icons/terrarium_theme_placeholder.svg',
                          key: ValueKey('terrarium_theme_icon_$index'),
                          excludeFromSemantics: true,
                        ),
                      ),
                      if (selected)
                        const Positioned(
                          left: 55,
                          top: 21,
                          child: SizedBox(
                            key: ValueKey('terrarium_theme_character_slot'),
                            width: 36,
                            height: 54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _names[index],
                style: AppTypography.bodyRegular.copyWith(
                  fontFamily: 'Jua',
                  color: selected ? _ink : _secondary,
                ),
              ),
              Text(
                status,
                style:
                    (selected
                            ? AppTypography.bodyRegular
                            : AppTypography.captionRegular)
                        .copyWith(
                          fontFamily: 'Jua',
                          color: selected ? _ink : _tertiary,
                        ),
              ),
            ],
          ),
        ],
      ),
    );
    return Semantics(
      key: ValueKey('terrarium_theme_card_$index'),
      button: true,
      enabled: true,
      selected: selected,
      label: '${_names[index]}, $status${selected ? ', 디자인 예시' : ''}',
      onTap: _unavailable,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: ValueKey('terrarium_theme_tap_$index'),
          onTap: _unavailable,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(22),
          child: Opacity(
            key: ValueKey('terrarium_theme_opacity_$index'),
            opacity: dimmed ? .45 : 1,
            child: surface,
          ),
        ),
      ),
    );
  }
}

/// The photo extension's CSS dashed border, not a replacement for its SVG icon.
class _DashedOutline extends CustomPainter {
  const _DashedOutline();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(11.5),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xFFD3CCBE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 6) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 3, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutline oldDelegate) => false;
}
