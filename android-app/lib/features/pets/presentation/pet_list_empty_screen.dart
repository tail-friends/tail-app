import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'pet_registration_screen.dart';

Future<void> showPetListEmptyPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(
        '이 화면은 Figma 디자인 미리보기입니다. 실제 개체 목록 조회, 등록 저장 및 서버 데이터 변경은 실행되지 않습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('미리보기 열기'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const PetListEmptyScreen()));
}

/// Figma 06-0a, an empty Debug scenario with no list/persistence model.
class PetListEmptyScreen extends StatefulWidget {
  const PetListEmptyScreen({super.key});

  @override
  State<PetListEmptyScreen> createState() => _PetListEmptyScreenState();
}

enum _ViewMode { list, wheel }

class _PetListEmptyScreenState extends State<PetListEmptyScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  static const _forest = Color(0xFF2F6B57);
  static final _caption = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: _tertiary,
  );
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  _ViewMode _mode = _ViewMode.list;
  bool _openingRegistration = false;

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

  void _selectTab(AppTab tab) {
    if (tab == AppTab.pets) return;
    final label = switch (tab) {
      AppTab.habitat => '사육장',
      AppTab.records => '기록',
      AppTab.pets => '내 아이들',
      AppTab.profile => '마이',
    };
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            math.max(24, MediaQuery.viewPaddingOf(context).bottom) + 70,
          ),
          content: Text('$label 기능은 준비 중입니다.'),
        ),
      );
  }

  void _close() {
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
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
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
            key: const ValueKey('pet_list_empty_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma 408:2365 export is byte-identical to this existing bg.
                Image.asset(
                  'assets/images/pet_registration_complete_background.png',
                  key: const ValueKey('pet_list_empty_background'),
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
                          key: const ValueKey('pet_list_empty_scroll'),
                          padding: EdgeInsets.only(
                            top: math.max(4, 58 - media.padding.top),
                            bottom: 24,
                          ),
                          child: Column(
                            children: [
                              _header(),
                              const SizedBox(height: 14),
                              _empty(),
                            ],
                          ),
                        ),
                      ),
                      AppBottomNavigation(
                        key: const ValueKey('pet_list_empty_navigation'),
                        currentTab: AppTab.pets,
                        onTabSelected: _selectTab,
                        labelStyle: _caption,
                        labelMaxLines: 2,
                        selectedLabelColor: _ink,
                        unselectedLabelColor: _muted,
                        selectedBackgroundColor: Colors.white,
                        iconAssets: const {
                          AppTab.habitat:
                              'assets/icons/pet_list_empty_nav_home.svg',
                          AppTab.records:
                              'assets/icons/home_first_visit_nav_record.svg',
                          AppTab.pets:
                              'assets/icons/pet_list_empty_nav_pets.svg',
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

  Widget _header() => LayoutBuilder(
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
          Text('등록순 · 0마리', style: _caption),
        ],
      );
      final controls = Row(
        mainAxisSize: MainAxisSize.min,
        children: [_toggle(), _addButton()],
      );
      final compact =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(13) > 18;
      if (compact) {
        return Column(
          key: const ValueKey('pet_list_empty_header'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: controls),
          ],
        );
      }
      return Row(
        key: const ValueKey('pet_list_empty_header'),
        children: [
          Expanded(child: title),
          const SizedBox(width: 12),
          controls,
        ],
      );
    },
  );

  Widget _toggle() => Stack(
    children: [
      Positioned.fill(
        top: 5,
        bottom: 5,
        child: AppGlassSurface(
          key: const ValueKey('pet_list_empty_toggle_surface'),
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: AppColors.glassSoftGradient,
          child: const SizedBox(),
        ),
      ),
      IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in _ViewMode.values)
              Semantics(
                label: mode == _ViewMode.list ? '목록 보기' : '휠 보기',
                button: true,
                selected: _mode == mode,
                inMutuallyExclusiveGroup: true,
                excludeSemantics: true,
                onTap: () => setState(() => _mode = mode),
                child: InkWell(
                  key: ValueKey('pet_list_empty_mode_${mode.name}'),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  onTap: () => setState(() => _mode = mode),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 9,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _mode == mode
                              ? Colors.white
                              : Colors.transparent,
                          border: Border.all(
                            color: _mode == mode
                                ? const Color(0xE6E6E1D6)
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: _mode == mode
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Center(
                          child: Text(
                            mode == _ViewMode.list ? '목록' : '휠',
                            style: _caption.copyWith(
                              color: _mode == mode ? _ink : _tertiary,
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
    ],
  );

  Widget _addButton() => Semantics(
    label: '개체 추가',
    button: true,
    excludeSemantics: true,
    onTap: _register,
    child: InkWell(
      key: const ValueKey('pet_list_empty_add'),
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: _register,
      child: SizedBox.square(
        dimension: 44,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            key: const ValueKey('pet_list_empty_add_surface'),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _forest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/pet_list_empty_plus.svg',
                width: 16,
                height: 16,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _empty() => Padding(
    key: const ValueKey('pet_list_empty_content'),
    padding: const EdgeInsets.only(top: 110),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: '등록된 개체가 없는 빈 캐릭터 자리',
            child: CustomPaint(
              key: const ValueKey('pet_list_empty_character_slot'),
              painter: const _EmptyCharacterBorder(),
              child: const SizedBox.square(
                dimension: 96,
                child: Center(
                  child: SizedBox(
                    key: ValueKey('pet_list_empty_character'),
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
          '첫 개체를 등록해 보세요',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            fontFamily: 'Jua',
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '이름·종·급여 주기만 있으면 시작할 수 있어요',
          textAlign: TextAlign.center,
          style: _caption.copyWith(color: _muted),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 200,
            child: AppButton(
              key: const ValueKey('pet_list_empty_register'),
              label: '개체 등록하기',
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              minHeight: 48,
              textStyle: AppTypography.titleMedium.copyWith(fontFamily: 'Jua'),
              onPressed: _register,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Figma's dashed border is a layout primitive, not a character asset.
class _EmptyCharacterBorder extends CustomPainter {
  const _EmptyCharacterBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6E1D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addOval(Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1));
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 8) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 4, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EmptyCharacterBorder oldDelegate) => false;
}
