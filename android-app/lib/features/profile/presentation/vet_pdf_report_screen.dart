import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const vetPdfReportPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 표시된 건강 기록은 예시이며 실제 반려동물 진료 문서가 아닙니다. 파일 저장과 공유도 실행되지 않습니다.';
final _previewInProgress = Expando<bool>();

Future<void> showVetPdfReportPreview(BuildContext context) async {
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
        content: const Text(vetPdfReportPreviewNotice),
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
      MaterialPageRoute(builder: (_) => const VetPdfReportScreen.preview()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// Static design sample, not a PDF document, medical record or generated report.
class VetPdfReportScreen extends StatefulWidget {
  const VetPdfReportScreen.preview({super.key});
  @override
  State<VetPdfReportScreen> createState() => _VetPdfReportScreenState();
}

class _VetPdfReportScreenState extends State<VetPdfReportScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _summaries = [
    ('체중', '48.1g → 53.4g (+5.3g)'),
    ('급여', '22회 · 안 먹음 2회'),
    ('탈피', '4회 · 평균 21일 · 부분 탈피 1회'),
    ('진료', '없음'),
  ];
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  void _notice(String text) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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
            key: const ValueKey('vet_pdf_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Original Figma bg 408:2408 export preserves the SVG blur filters.
                Image.asset(
                  'assets/images/vet_pdf_background.png',
                  key: const ValueKey('vet_pdf_background'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      math.max(4, 58 - MediaQuery.paddingOf(context).top),
                      24,
                      10,
                    ),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          key: const ValueKey('vet_pdf_header'),
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            children: [
                              Semantics(
                                button: true,
                                label: '뒤로가기',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: const ValueKey('vet_pdf_back'),
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
                                    'PDF 리포트',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontFamily: 'Jua',
                                      color: _ink,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: '공유',
                                excludeSemantics: true,
                                onTap: () =>
                                    _notice('디자인 미리보기에서는 실제 리포트를 공유하지 않습니다.'),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: const ValueKey('vet_pdf_share'),
                                    excludeFromSemantics: true,
                                    onTap: () => _notice(
                                      '디자인 미리보기에서는 실제 리포트를 공유하지 않습니다.',
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      child: Center(
                                        child: AppGlassSurface(
                                          key: const ValueKey(
                                            'vet_pdf_share_visual',
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 9,
                                          ),
                                          child: Text(
                                            '공유',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  fontFamily: 'Jua',
                                                  height: 17 / 12,
                                                  color: _secondary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('vet_pdf_scroll'),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _page(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          key: const ValueKey('vet_pdf_save'),
                          label: 'PDF 저장',
                          backgroundColor: const Color(0xFF2F6B57),
                          foregroundColor: Colors.white,
                          textStyle: AppTypography.titleMedium.copyWith(
                            fontFamily: 'Jua',
                          ),
                          onPressed: () =>
                              _notice('디자인 미리보기에서는 PDF 파일을 생성하지 않습니다.'),
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

  Widget _page() => DecoratedBox(
    key: const ValueKey('vet_pdf_page'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F33291F),
          offset: Offset(0, 12),
          blurRadius: 30,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                '욱이 건강 리포트',
                style: AppTypography.titleLarge.copyWith(
                  fontFamily: 'Jua',
                  height: 23 / 16,
                  color: _ink,
                ),
              );
              final info = Text(
                '레오파드 게코 · 수컷 · 2024.07.12 해칭',
                style: AppTypography.captionRegular.copyWith(
                  fontFamily: 'Jua',
                  height: 16 / 11,
                  color: _muted,
                ),
              );
              final period = Text(
                '2026.07–10',
                style: AppTypography.captionRegular.copyWith(
                  fontFamily: 'Jua',
                  height: 16 / 11,
                  color: _muted,
                ),
              );
              if (constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(11) > 13.2) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 2),
                    info,
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight, child: period),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 2), info],
                    ),
                  ),
                  period,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Figma 예시 체중 추이 그래프. 실제 측정 데이터가 아닙니다.',
            image: true,
            excludeSemantics: true,
            child: AspectRatio(
              key: const ValueKey('vet_pdf_graph'),
              aspectRatio: 298 / 80,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 298,
                  height: 80,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 9.5,
                        child: SvgPicture.asset(
                          'assets/images/vet_pdf_graph_grid.svg',
                          key: const ValueKey('vet_pdf_graph_grid'),
                          excludeFromSemantics: true,
                        ),
                      ),
                      Positioned(
                        left: 3.3045,
                        top: 11.25,
                        child: SvgPicture.asset(
                          'assets/images/vet_pdf_graph_line.svg',
                          key: const ValueKey('vet_pdf_graph_line'),
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < 4; i++) ...[
            const SizedBox(height: 14),
            DecoratedBox(
              key: ValueKey('vet_pdf_summary_$i'),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE6E1D6))),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 9, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _summaries[i].$1,
                      style: AppTypography.labelMedium.copyWith(
                        fontFamily: 'Jua',
                        height: 17 / 12,
                        color: _secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _summaries[i].$2,
                        textAlign: TextAlign.right,
                        style: AppTypography.labelMedium.copyWith(
                          fontFamily: 'Jua',
                          height: 17 / 12,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '꼬리친구에서 생성 · 참고용 자료예요',
            style: AppTypography.captionRegular.copyWith(
              fontFamily: 'Jua',
              fontSize: 10,
              height: 14 / 10,
              color: _muted,
            ),
          ),
        ],
      ),
    ),
  );
}
