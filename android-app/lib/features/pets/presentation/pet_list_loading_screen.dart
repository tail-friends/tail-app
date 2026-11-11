import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'pet_registration_screen.dart';

const petListLoadingPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 실제 개체 목록 조회, 등록 저장 및 서버 데이터 변경은 실행되지 않습니다.';

Future<void> showPetListLoadingPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(petListLoadingPreviewNotice),
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
  ).push<void>(MaterialPageRoute(builder: (_) => const PetListLoadingScreen()));
}

/// A static Debug design scenario, independent of requests or pet data.
class PetListLoadingScreen extends StatefulWidget {
  const PetListLoadingScreen({super.key});

  @override
  State<PetListLoadingScreen> createState() => _PetListLoadingScreenState();
}

enum _ViewMode { list, wheel }

class _PetListLoadingScreenState extends State<PetListLoadingScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
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
            key: const ValueKey('pet_list_loading_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma bg 408:2366 is byte-identical to this existing export.
                Image.asset(
                  'assets/images/pet_registration_complete_background.png',
                  key: const ValueKey('pet_list_loading_background'),
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
                          key: const ValueKey('pet_list_loading_scroll'),
                          padding: EdgeInsets.only(
                            top: math.max(4, 58 - media.padding.top),
                            bottom: 24,
                          ),
                          child: Column(
                            children: [
                              _header(),
                              const SizedBox(height: 14),
                              Semantics(
                                label: '개체 목록을 불러오는 중입니다. 디자인 미리보기입니다.',
                                container: true,
                                child: ExcludeSemantics(
                                  child: Column(
                                    key: const ValueKey(
                                      'pet_list_loading_skeletons',
                                    ),
                                    children: [
                                      for (var i = 0; i < 6; i++) ...[
                                        if (i > 0) const SizedBox(height: 8),
                                        _LoadingCard(index: i),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppBottomNavigation(
                        key: const ValueKey('pet_list_loading_navigation'),
                        currentTab: AppTab.pets,
                        onTabSelected: _selectTab,
                        labelStyle: _caption,
                        labelMaxLines: 2,
                        selectedLabelColor: _ink,
                        unselectedLabelColor: _muted,
                        selectedBackgroundColor: Colors.white,
                        iconAssets: const {
                          AppTab.habitat:
                              'assets/icons/pet_list_loading_nav_home.svg',
                          AppTab.records:
                              'assets/icons/home_first_visit_nav_record.svg',
                          AppTab.pets:
                              'assets/icons/pet_list_loading_nav_pets.svg',
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
          Text('등록순 · 불러오는 중', style: _caption),
        ],
      );
      final controls = Row(
        mainAxisSize: MainAxisSize.min,
        children: [_toggle(), _addButton()],
      );
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(13) > 18) {
        return Column(
          key: const ValueKey('pet_list_loading_header'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: controls),
          ],
        );
      }
      return Row(
        key: const ValueKey('pet_list_loading_header'),
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
                  key: ValueKey('pet_list_loading_mode_${mode.name}'),
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
      key: const ValueKey('pet_list_loading_add'),
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: _register,
      child: SizedBox.square(
        dimension: 44,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            key: const ValueKey('pet_list_loading_add_surface'),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2F6B57),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/pet_list_loading_plus.svg',
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
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey('pet_list_loading_card_$index'),
    height: 78,
    child: AppGlassSurface(
      borderRadius: BorderRadius.circular(22),
      gradient: AppColors.glassSoftGradient,
      // Includes the original 1px border; AppGlassSurface does not inset it.
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/pet_list_loading_placeholder.svg',
            key: ValueKey('pet_list_loading_placeholder_$index'),
            width: 48,
            height: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _line(90, 'name'),
                const SizedBox(height: 8),
                _line(150, 'detail'),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _line(double width, String name) => Container(
    key: ValueKey('pet_list_loading_${name}_$index'),
    width: width,
    height: 10,
    decoration: BoxDecoration(
      color: const Color(0x99E6E1D6),
      borderRadius: BorderRadius.circular(5),
    ),
  );
}
