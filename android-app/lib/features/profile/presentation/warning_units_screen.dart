import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const warningUnitsPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 경고 수치는 건강 진단이나 확정된 기준이 아닌 예시입니다. 숫자와 온도 단위는 화면 안에서만 바뀌며 저장되지 않습니다. ‘서버에는 °C로 저장돼요’도 시안 문구이며 실제 서버 계약이나 저장을 뜻하지 않습니다.';
final _previewInProgress = Expando<bool>();

Future<void> showWarningUnitsPreview(BuildContext context) async {
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
        content: const Text(warningUnitsPreviewNotice),
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
      MaterialPageRoute(builder: (_) => const WarningUnitsScreen.preview()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// In-memory design fixture. These numbers never evaluate husbandry records.
class WarningUnitsScreen extends StatefulWidget {
  const WarningUnitsScreen.preview({super.key});
  @override
  State<WarningUnitsScreen> createState() => _WarningUnitsScreenState();
}

class _WarningUnitsScreenState extends State<WarningUnitsScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  static const _titles = ['거식 경고', '체중 감소 경고', '묽은 변 경고'];
  static const _subtitles = ['연속 안 먹음 횟수', '최근 30일 기준', '연속 횟수'];
  final _values = [3, 10, 2];
  bool _celsius = true;

  void _back() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _adjust(int index, int delta) {
    // Nonnegative display values only: not a server or medical validation rule.
    setState(() => _values[index] = math.max(0, _values[index] + delta));
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
        child: Scaffold(
          key: const ValueKey('warning_units_screen'),
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Original Figma bg 408:2393 PNG preserves unsupported SVG filters.
              Image.asset(
                'assets/images/warning_units_background.png',
                key: const ValueKey('warning_units_background'),
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
                        key: const ValueKey('warning_units_header'),
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: '뒤로가기',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey('warning_units_back'),
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
                                  '경고 기준 · 단위',
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
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('warning_units_scroll'),
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _section('건강 경고 기준'),
                              const SizedBox(height: 18),
                              _group('thresholds', [
                                for (var i = 0; i < 3; i++) ...[
                                  if (i > 0)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE6E1D6),
                                      ),
                                    ),
                                  _threshold(i),
                                ],
                              ]),
                              const SizedBox(height: 18),
                              _section('단위'),
                              const SizedBox(height: 18),
                              _group('units', [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    13,
                                    8,
                                    13,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final labels = _labels(
                                        '온도 단위',
                                        '서버에는 °C로 저장돼요',
                                      );
                                      // Keep the original row at 390px; avoid squeezed labels on small/large-text views.
                                      if (constraints.maxWidth < 280 &&
                                          MediaQuery.textScalerOf(
                                                context,
                                              ).scale(12) >
                                              18) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            labels,
                                            const SizedBox(height: 12),
                                            _unitSelector(),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(child: labels),
                                          const SizedBox(width: 12),
                                          _unitSelector(),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ]),
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
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: AppTypography.bodyRegular.copyWith(
          fontFamily: 'Jua',
          color: _secondary,
        ),
      ),
    ),
  );

  Widget _group(String name, List<Widget> children) => AppGlassSurface(
    key: ValueKey('warning_units_$name'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    // Eight extra pixels inside each visual row accommodate 28px controls' 44px targets.
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    child: Column(children: children),
  );

  Widget _labels(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTypography.bodyRegular.copyWith(
          fontFamily: 'Jua',
          color: _ink,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: AppTypography.captionRegular.copyWith(
          fontFamily: 'Jua',
          color: _tertiary,
        ),
      ),
    ],
  );

  Widget _threshold(int index) => Padding(
    key: ValueKey('warning_units_row_$index'),
    padding: const EdgeInsets.symmetric(vertical: 9.5),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _labels(_titles[index], _subtitles[index]),
          ),
        ),
        const SizedBox(width: 12),
        _step(index, -1),
        const SizedBox(width: 2),
        Text(
          '${_values[index]}${index == 1 ? '%' : '번'}',
          key: ValueKey('warning_units_value_$index'),
          style: AppTypography.bodyRegular.copyWith(
            fontFamily: 'Jua',
            color: _ink,
          ),
        ),
        const SizedBox(width: 2),
        _step(index, 1),
      ],
    ),
  );

  Widget _step(int index, int delta) {
    final minus = delta < 0;
    final enabled = !minus || _values[index] > 0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${_titles[index]} ${minus ? '감소' : '증가'}',
      value: '${_values[index]}${index == 1 ? '%' : '번'}',
      onTap: enabled ? () => _adjust(index, delta) : null,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('warning_units_${minus ? 'minus' : 'plus'}_$index'),
          onTap: enabled ? () => _adjust(index, delta) : null,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: Opacity(
                opacity: enabled ? 1 : .4,
                child: AppGlassSurface(
                  key: ValueKey(
                    'warning_units_${minus ? 'minus' : 'plus'}_visual_$index',
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox.square(
                    dimension: 28,
                    child: Center(
                      child: Text(
                        minus ? '−' : '+',
                        style: AppTypography.bodyRegular.copyWith(
                          fontFamily: 'Jua',
                          color: _ink,
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
    );
  }

  Widget _unitSelector() => SizedBox(
    width: 140,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AppGlassSurface(
          key: const ValueKey('warning_units_unit_visual'),
          borderRadius: BorderRadius.circular(999),
          gradient: AppColors.glassSoftGradient,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final celsius in [true, false])
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _celsius == celsius
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: _celsius == celsius
                          ? Border.all(color: const Color(0xE6E6E1D6))
                          : null,
                      boxShadow: _celsius == celsius
                          ? const [
                              BoxShadow(
                                color: Color(0x0F3D2E1F),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                              BoxShadow(
                                color: Color(0x1A3D2E1F),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ]
                          : const [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 9,
                      ),
                      child: Text(
                        celsius ? '°C' : '°F',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMedium.copyWith(
                          fontFamily: 'Jua',
                          color: _celsius == celsius ? _ink : _tertiary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            for (final celsius in [true, false])
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _celsius == celsius,
                  label: '온도 단위 ${celsius ? '섭씨' : '화씨'}',
                  onTap: () => setState(() => _celsius = celsius),
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey(
                        'warning_units_${celsius ? 'celsius' : 'fahrenheit'}',
                      ),
                      onTap: () => setState(() => _celsius = celsius),
                      excludeFromSemantics: true,
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(height: 44),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
