import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const batchFeedingConfirmationNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 개체·먹이·개수와 직전 기록 안내는 예시이며 실제 기록을 조회하지 않았습니다. 스위치는 화면 안에서만 바뀌고 실제 저장·트랜잭션·되돌리기는 실행되지 않습니다.';
final _openPreviews = Expando<bool>();
Future<void> showBatchFeedingConfirmationPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final nav = Navigator.of(context);
  if (_openPreviews[nav] == true) return;
  _openPreviews[nav] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(batchFeedingConfirmationNotice),
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
    if (accepted != true || !context.mounted || !nav.mounted) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => const BatchFeedingConfirmationScreen.preview(),
    );
    await nav.push(route);
    await route.completed;
  } finally {
    _openPreviews[nav] = false;
  }
}

// Read-only Figma display fixtures; not pet IDs or a server record model.
const _examples = [
  (id: 'leo', name: '레오', letter: '레', food: '귀뚜라미', count: '4마리'),
  (id: 'ukki', name: '욱이', letter: '욱', food: '귀뚜라미', count: '5마리'),
  (id: 'haru', name: '하루', letter: '하', food: '밀웜', count: '3마리'),
];

class BatchFeedingConfirmationScreen extends StatefulWidget {
  const BatchFeedingConfirmationScreen.preview({super.key});
  @override
  State<BatchFeedingConfirmationScreen> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<BatchFeedingConfirmationScreen> {
  static const _ink = Color(0xFF2B2A26),
      _secondary = Color(0xFF6B675E),
      _muted = Color(0xFF736E65);
  final _refused = [false, false, true];
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _leaving = false;
  TextStyle _style(double size, double line, [Color color = _ink]) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: line / size,
        color: color,
        letterSpacing: size == 14
            ? -0.2
            : (size == 13 || size == 10 ? -0.1 : 0),
      );
  void _back() {
    if (_leaving) return;
    _leaving = true;
    _messenger.currentState?.removeCurrentSnackBar();
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _save() {
    if (_leaving) return;
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.paddingOf(context).bottom + 80,
          ),
          content: const Text('디자인 미리보기입니다. 실제 급여 기록은 저장되지 않습니다.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _back();
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
            key: const ValueKey('batch_feed_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/data_photo_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('batch_feed_scroll'),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            math.max(4, 58 - MediaQuery.paddingOf(context).top),
                            24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ConstrainedBox(
                                key: const ValueKey('batch_feed_header'),
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Row(
                                  children: [
                                    Semantics(
                                      button: true,
                                      label: '뒤로가기',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          key: const ValueKey(
                                            'batch_feed_back',
                                          ),
                                          onTap: _back,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: SizedBox.square(
                                            dimension: 44,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: AppGlassSurface(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                child: SizedBox.square(
                                                  dimension: 36,
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      'assets/icons/terms_chevron_left.svg',
                                                      width: 16,
                                                      height: 16,
                                                      excludeFromSemantics:
                                                          true,
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
                                          '3마리 급여 완료',
                                          textAlign: TextAlign.center,
                                          style: _style(14, 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 44),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '먹이와 개수는 개체별 직전 기록으로 채웠어요',
                                style: _style(11, 14, _muted),
                              ),
                              const SizedBox(height: 18),
                              AppGlassSurface(
                                key: const ValueKey('batch_feed_card'),
                                borderRadius: BorderRadius.circular(22),
                                gradient: AppColors.glassSoftGradient,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 17,
                                  vertical: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x143D3329),
                                    offset: Offset(0, 12),
                                    blurRadius: 32,
                                  ),
                                ],
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _examples.length;
                                      i++
                                    ) ...[
                                      if (i > 0)
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFE6E1D6),
                                        ),
                                      _row(i),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '하나라도 저장에 실패하면 전부 저장하지 않아요',
                                style: _style(11, 14, _muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                        child: AppButton(
                          key: const ValueKey('batch_feed_save'),
                          label: '3마리 저장',
                          onPressed: _save,
                          backgroundColor: const Color(0xFF2F6B57),
                          foregroundColor: Colors.white,
                          textStyle: _style(14, 20, Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int index) {
    final example = _examples[index];
    final refused = _refused[index];
    void toggle() {
      if (!_leaving) setState(() => _refused[index] = !_refused[index]);
    }

    return Padding(
      key: ValueKey('batch_feed_row_${example.id}'),
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Container(
                  key: ValueKey('batch_feed_avatar_${example.id}'),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2F6B57),
                    border: Border.all(color: const Color(0xE6FFFFFF)),
                  ),
                  child: Text(
                    example.letter,
                    style: _style(10, 13, Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(example.name, style: _style(13, 19))),
                Semantics(
                  key: ValueKey('batch_feed_refused_${example.id}'),
                  label: '${example.name} 안 먹음',
                  toggled: refused,
                  enabled: true,
                  onTap: toggle,
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('batch_feed_switch_${example.id}'),
                      onTap: toggle,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('안 먹음', style: _style(11, 14, _secondary)),
                            const SizedBox(width: 2),
                            SizedBox.square(
                              dimension: 44,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Image.asset(
                                  'assets/images/batch_feeding_switch_${refused ? 'on' : 'off'}.png',
                                  key: ValueKey(
                                    'batch_feed_switch_image_${example.id}',
                                  ),
                                  width: 40,
                                  height: 24,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Opacity(
            key: ValueKey('batch_feed_pills_${example.id}'),
            opacity: refused ? 0.4 : 1,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(example.food, food: !refused),
                _pill(example.count),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, {bool food = false}) => AppGlassSurface(
    borderRadius: BorderRadius.circular(999),
    gradient: food
        ? const LinearGradient(colors: [Colors.white, Colors.white])
        : AppColors.glassStrongGradient,
    borderColor: food ? const Color(0xE6E6E1D6) : Colors.white,
    padding: EdgeInsets.symmetric(horizontal: food ? 13 : 15, vertical: 8),
    boxShadow: food
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
    child: Text(label, style: _style(12, 16, food ? _ink : _secondary)),
  );
}
