import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const batchCleaningPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 개체와 배변 상태는 예시이며 실제 기록 조회·저장·API·DB·알림은 실행되지 않습니다. 저장 안내의 트랜잭션과 5초 되돌리기도 구현되지 않았습니다.';
const batchCleaningSaveNotice = '디자인 미리보기입니다. 실제 청소 기록은 저장되지 않습니다.';
final _previewNavigators = Expando<bool>();

Future<void> showBatchCleaningPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewNavigators[navigator] == true) return;
  _previewNavigators[navigator] = true;
  try {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(batchCleaningPreviewNotice),
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
    if (allow != true || !context.mounted || !navigator.mounted) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => const BatchCleaningScreen.preview(),
    );
    await navigator.push(route);
    await route.completed;
  } finally {
    _previewNavigators[navigator] = false;
  }
}

// Display-only fixtures and choices, not server IDs or health classifications.
const _examples = [
  (id: 'leo', name: '레오', avatar: '레'),
  (id: 'ukki', name: '욱이', avatar: '욱'),
  (id: 'haru', name: '하루', avatar: '하'),
];
const _types = ['부분 · 배설물', '전체 · 바닥재 교체'];
const _statuses = ['정상', '묽음', '없음'];

/// Independent Figma 10-4 preview. Choices are discarded when this route closes.
class BatchCleaningScreen extends StatefulWidget {
  const BatchCleaningScreen.preview({super.key});
  @override
  State<BatchCleaningScreen> createState() => _CleaningState();
}

class _CleaningState extends State<BatchCleaningScreen> {
  static const _green = Color(0xFF2F6B57);
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _selected = [0, 0, 0];
  int _type = 0;
  bool _leaving = false;

  TextStyle _style(double size, double height, [Color color = _ink]) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: height / size,
        color: color,
        letterSpacing: size == 10 ? -0.1 : 0,
      );

  void _leave() {
    if (_leaving) return;
    _leaving = true;
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

  void _saveNotice() {
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
          content: const Text(batchCleaningSaveNotice),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
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
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/batch_cleaning_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('cleaning_scroll'),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            math.max(4, 58 - MediaQuery.paddingOf(context).top),
                            24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(),
                              const SizedBox(height: 18),
                              _typeControl(),
                              const SizedBox(height: 18),
                              AppGlassSurface(
                                key: const ValueKey('cleaning_card'),
                                borderRadius: BorderRadius.circular(22),
                                gradient: AppColors.glassSoftGradient,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 17,
                                  vertical: 5,
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
                                      if (i != 0)
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFE6E1D6),
                                        ),
                                      _petRow(i),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '저장 후 5초 동안 되돌릴 수 있어요 · 하나라도 실패하면 전부 저장하지 않아요',
                                style: _style(11, 16, _muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                        child: AppButton(
                          key: const ValueKey('cleaning_save'),
                          label: '3마리 저장',
                          onPressed: _saveNotice,
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          textStyle: _style(
                            14,
                            20,
                            Colors.white,
                          ).copyWith(letterSpacing: -0.2),
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

  Widget _header() => Row(
    key: const ValueKey('cleaning_header'),
    children: [
      Semantics(
        label: '뒤로가기',
        button: true,
        excludeSemantics: true,
        onTap: _leave,
        child: GestureDetector(
          key: const ValueKey('cleaning_back'),
          behavior: HitTestBehavior.opaque,
          onTap: _leave,
          child: SizedBox.square(
            dimension: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppGlassSurface(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/terms_chevron_left.svg',
                      width: 16,
                      height: 16,
                      excludeFromSemantics: true,
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
            '3마리 청소 기록',
            textAlign: TextAlign.center,
            style: _style(14, 20),
          ),
        ),
      ),
      const SizedBox(width: 44, height: 44),
    ],
  );

  Widget _typeControl() => AppGlassSurface(
    key: const ValueKey('cleaning_type'),
    borderRadius: BorderRadius.circular(999),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _types.length; i++)
            Expanded(
              child: _choice(
                key: 'cleaning_type_$i',
                label: _types[i],
                selected: _type == i,
                onTap: () => setState(() => _type = i),
                horizontal: 0,
                vertical: 10,
                text: _style(12, 17, _type == i ? Colors.white : _muted),
                minHeight: 45,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _petRow(int index) {
    final example = _examples[index];
    final identity = Row(
      children: [
        ExcludeSemantics(
          child: Container(
            key: ValueKey('cleaning_avatar_${example.id}'),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: Text(example.avatar, style: _style(10, 13, Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(example.name, style: _style(13, 18)),
              const SizedBox(height: 3),
              Text('배변 상태', style: _style(11, 16, _muted)),
            ],
          ),
        ),
      ],
    );
    final choices = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var status = 0; status < _statuses.length; status++) ...[
          if (status != 0) const SizedBox(width: 6),
          _choice(
            key: 'cleaning_${example.id}_$status',
            label: '${example.name} 배변 상태 ${_statuses[status]}',
            selected: _selected[index] == status,
            onTap: () => setState(() => _selected[index] = status),
            text: _style(
              12,
              17,
              _selected[index] == status
                  ? Colors.white
                  : const Color(0xFF6B675E),
            ),
            visibleLabel: _statuses[status],
            horizontal: 15,
            vertical: 9,
          ),
        ],
      ],
    );
    return Padding(
      key: ValueKey('cleaning_row_${example.id}'),
      padding: const EdgeInsets.symmetric(vertical: 10.5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
          if (constraints.maxWidth < 290 || scale > 1.1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: choices),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              choices,
            ],
          );
        },
      ),
    );
  }

  Widget _choice({
    required String key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required TextStyle text,
    String? visibleLabel,
    double horizontal = 0,
    double vertical = 0,
    double minHeight = 44,
  }) {
    final radius = BorderRadius.circular(999);
    final child = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: Text(
        visibleLabel ?? label,
        textAlign: TextAlign.center,
        style: text,
      ),
    );
    final surface = selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: _green,
              borderRadius: radius,
              border: Border.all(color: const Color(0xE6E6E1D6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A3D2E1F),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Color(0x0F3D2E1F),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: child,
          )
        : key.startsWith('cleaning_type_')
        ? child
        : AppGlassSurface(borderRadius: radius, child: child);
    return Semantics(
      key: ValueKey(key),
      label: label,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight, minWidth: 44),
          child: Center(
            child: key.startsWith('cleaning_type_')
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(width: double.infinity, child: surface),
                  )
                : surface,
          ),
        ),
      ),
    );
  }
}
