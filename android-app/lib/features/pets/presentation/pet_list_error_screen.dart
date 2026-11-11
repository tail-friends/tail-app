import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'pet_registration_screen.dart';

const petListErrorPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 실제 개체 목록 조회나 네트워크 진단은 실행되지 않습니다.';
const petListErrorRetryNotice = 'UI 미리보기입니다. 실제 목록 재시도 기능은 연결되지 않았습니다.';
const _ink = Color(0xFF2B2A26);
const _muted = Color(0xFF6B675E);
const _tertiary = Color(0xFF736E65);
final _caption = AppTypography.captionRegular.copyWith(
  fontFamily: 'Jua',
  color: _tertiary,
);

Future<void> showPetListErrorPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(
        '$petListErrorPreviewNotice\n\n등록·저장은 실행되지 않으며, 네트워크 토스트도 실제 연결 상태와 무관한 디자인 예시입니다.',
      ),
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
  if (accepted != true || !context.mounted) return;
  await Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const PetListErrorScreen()));
}

/// Static Debug UI; the preview supplies no request handler or pet model.
class PetListErrorScreen extends StatefulWidget {
  const PetListErrorScreen({this.onRetry, super.key});

  /// Retry intent only. A future integration owns the request and its state.
  /// The independent preview leaves this null and shows an unconnected notice.
  final VoidCallback? onRetry;

  @override
  State<PetListErrorScreen> createState() => _PetListErrorScreenState();
}

class _PetListErrorScreenState extends State<PetListErrorScreen> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _wheel = false;
  bool _openingRegistration = false;

  void _notice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            math.max(24, MediaQuery.viewPaddingOf(context).bottom) + 140,
          ),
          content: Text(message),
        ),
      );
  }

  void _retry() {
    if (!kDebugMode) return;
    if (widget.onRetry case final handler?) {
      handler();
    } else {
      _notice(petListErrorRetryNotice);
    }
  }

  Future<void> _register() async {
    if (!kDebugMode || _openingRegistration) return;
    _openingRegistration = true;
    _messenger.currentState?.removeCurrentSnackBar();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              const ScaffoldMessenger(child: PetRegistrationScreen()),
        ),
      );
    } finally {
      _openingRegistration = false;
    }
  }

  void _tab(AppTab tab) {
    if (tab == AppTab.pets) return;
    final name = switch (tab) {
      AppTab.habitat => '사육장',
      AppTab.records => '기록',
      AppTab.pets => '내 아이들',
      AppTab.profile => '마이',
    };
    _notice('$name 기능은 준비 중입니다.');
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
            key: const ValueKey('pet_list_error_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Exact Figma SVG bg 408:2367 render; preserves its blur filters.
                // Exported PNG is byte-identical to this existing develop asset.
                Image.asset(
                  'assets/images/pet_registration_complete_background.png',
                  key: const ValueKey('pet_list_error_background'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('pet_list_error_scroll'),
                          padding: EdgeInsets.only(
                            top: math.max(
                              4,
                              58 - MediaQuery.paddingOf(context).top,
                            ),
                            bottom: 24,
                          ),
                          child: Column(
                            children: [
                              _ErrorHeader(
                                wheel: _wheel,
                                onMode: (value) =>
                                    setState(() => _wheel = value),
                                onAdd: _register,
                              ),
                              const SizedBox(height: 14),
                              _ErrorContent(onRetry: _retry),
                            ],
                          ),
                        ),
                      ),
                      const _NetworkToastExample(),
                      const SizedBox(height: 26),
                      AppBottomNavigation(
                        key: const ValueKey('pet_list_error_navigation'),
                        currentTab: AppTab.pets,
                        onTabSelected: _tab,
                        labelStyle: _caption,
                        labelMaxLines: 2,
                        selectedLabelColor: _ink,
                        unselectedLabelColor: _muted,
                        selectedBackgroundColor: Colors.white,
                        iconAssets: const {
                          AppTab.habitat:
                              'assets/icons/pet_list_error_nav_home.svg',
                          AppTab.records:
                              'assets/icons/home_first_visit_nav_record.svg',
                          AppTab.pets:
                              'assets/icons/pet_list_error_nav_pets.svg',
                          AppTab.profile:
                              'assets/icons/home_first_visit_nav_profile.svg',
                        },
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
}

class _ErrorHeader extends StatelessWidget {
  const _ErrorHeader({
    required this.wheel,
    required this.onMode,
    required this.onAdd,
  });
  final bool wheel;
  final ValueChanged<bool> onMode;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '내 아이들',
              style: AppTypography.bodyRegular.copyWith(
                fontFamily: 'Jua',
                color: _ink,
              ),
            ),
          ),
          Text('등록순 · 불러올 수 없음', style: _caption),
        ],
      );
      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Positioned.fill(
                top: 5,
                bottom: 5,
                child: AppGlassSurface(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  gradient: AppColors.glassSoftGradient,
                  child: const SizedBox(),
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [_mode(false, '목록'), _mode(true, '휠')],
                ),
              ),
            ],
          ),
          Semantics(
            label: '개체 추가',
            button: true,
            excludeSemantics: true,
            onTap: onAdd,
            child: InkWell(
              key: const ValueKey('pet_list_error_add'),
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: SizedBox.square(
                dimension: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    key: const ValueKey('pet_list_error_add_surface'),
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F6B57),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/pet_list_error_plus.svg',
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
        ],
      );
      final compact =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(13) > 18;
      return compact
          ? Column(
              key: const ValueKey('pet_list_error_header'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              key: const ValueKey('pet_list_error_header'),
              children: [
                Expanded(child: title),
                const SizedBox(width: 12),
                actions,
              ],
            );
    },
  );

  Widget _mode(bool value, String label) => Semantics(
    label: '$label 보기',
    button: true,
    selected: wheel == value,
    inMutuallyExclusiveGroup: true,
    excludeSemantics: true,
    onTap: () => onMode(value),
    child: InkWell(
      key: ValueKey('pet_list_error_mode_${value ? 'wheel' : 'list'}'),
      onTap: () => onMode(value),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              color: wheel == value ? Colors.white : Colors.transparent,
              border: Border.all(
                color: wheel == value
                    ? const Color(0xE6E6E1D6)
                    : Colors.transparent,
              ),
              boxShadow: wheel == value
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
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: _caption.copyWith(
                  color: wheel == value ? _ink : _tertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('pet_list_error_content'),
    padding: const EdgeInsets.only(top: 110),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: '오류 화면의 빈 캐릭터 자리',
            child: CustomPaint(
              key: const ValueKey('pet_list_error_character_slot'),
              painter: const _DashedCircle(),
              child: const SizedBox.square(
                dimension: 96,
                child: Center(
                  child: SizedBox(
                    key: ValueKey('pet_list_error_character'),
                    width: 36,
                    height: 54,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '목록을 불러오지 못했어요',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            fontFamily: 'Jua',
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '잠시 후 다시 시도해 주세요',
          textAlign: TextAlign.center,
          style: _caption.copyWith(color: _muted),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 200,
            child: AppButton(
              key: const ValueKey('pet_list_error_retry'),
              label: '다시 시도',
              onPressed: onRetry,
              variant: AppButtonVariant.secondary,
              minHeight: 48,
              foregroundColor: _ink,
              textStyle: AppTypography.titleMedium.copyWith(fontFamily: 'Jua'),
            ),
          ),
        ),
      ],
    ),
  );
}

class _NetworkToastExample extends StatelessWidget {
  const _NetworkToastExample();

  @override
  Widget build(BuildContext context) => Padding(
    // The source toast is 6.5px left of the frame's center.
    padding: const EdgeInsets.only(right: 13),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
        return Center(
          child: Semantics(
            label: '네트워크 안내 토스트 디자인 예시입니다. 실제 인터넷 연결 상태를 진단하지 않았습니다.',
            excludeSemantics: true,
            child: Container(
              key: const ValueKey('pet_list_error_network_toast'),
              width: math.min(constraints.maxWidth, 170 * scale),
              constraints: const BoxConstraints(minHeight: 39),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '인터넷 연결을 확인해 주세요',
                textAlign: TextAlign.center,
                style: AppTypography.bodyRegular.copyWith(
                  fontFamily: 'Jua',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _DashedCircle extends CustomPainter {
  const _DashedCircle();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6E1D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final circle = Path()
      ..addOval(Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1));
    for (final metric in circle.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 8) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 4, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCircle oldDelegate) => false;
}
