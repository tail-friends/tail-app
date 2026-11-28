import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const todayTasksPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 10월 20일 일정, 개체 정보, 건강 경고와 완료 상태는 예시이며 실제 기록 조회나 저장은 실행되지 않습니다.';
final _openPreviews = Expando<bool>();

Future<void> showTodayTasksPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_openPreviews[navigator] == true) return;
  _openPreviews[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(todayTasksPreviewNotice),
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
    final route = MaterialPageRoute<void>(
      builder: (_) => const TodayTasksScreen.preview(),
    );
    await navigator.push(route);
    await route.completed;
  } finally {
    _openPreviews[navigator] = false;
  }
}

// Display fixtures only: these fields are not an API model or computed schedule.
enum _Treatment { overdue, feeding, schedule, alert, done }

class _TaskPreview {
  const _TaskPreview(
    this.id,
    this.title,
    this.description,
    this.avatar,
    this.treatment, [
    this.status,
  ]);
  final String id, title, description, avatar;
  final _Treatment treatment;
  final String? status;
}

const _sections = <({String id, String title, List<_TaskPreview> tasks})>[
  (
    id: 'overdue',
    title: '지난 급여',
    tasks: [
      _TaskPreview(
        'leo',
        '레오',
        '크레스티드 게코 · 귀뚜라미 4마리',
        '레',
        _Treatment.overdue,
        '2일 지남',
      ),
    ],
  ),
  (
    id: 'feeding',
    title: '오늘 급여',
    tasks: [
      _TaskPreview(
        'ukki',
        '욱이',
        '레오파드 게코 · 귀뚜라미 5마리',
        '욱',
        _Treatment.feeding,
        '오늘 급여',
      ),
      _TaskPreview(
        'haru',
        '하루',
        '펫테일 게코 · 밀웜 3마리',
        '하',
        _Treatment.feeding,
        '오늘 급여',
      ),
    ],
  ),
  (
    id: 'schedule',
    title: '오늘 일정',
    tasks: [
      _TaskPreview(
        'calcium',
        '칼슘 더스팅',
        '욱이 · 하루 · 매주 월·목',
        '욱',
        _Treatment.schedule,
      ),
      _TaskPreview('uvb', 'UVB 램프 점검', '치토 · 180일마다', '치', _Treatment.schedule),
    ],
  ),
  (
    id: 'alert',
    title: '건강 경고',
    tasks: [
      _TaskPreview(
        'chito',
        '치토',
        '최근 30일 체중 12% 감소',
        '치',
        _Treatment.alert,
        '확인 필요',
      ),
    ],
  ),
  (
    id: 'done',
    title: '완료',
    tasks: [
      _TaskPreview('sera', '세라', '급여 · 냉동 마우스 1마리', '세', _Treatment.done),
    ],
  ),
];

/// Figma 10 only. No record, schedule, health calculation or storage service.
class TodayTasksScreen extends StatefulWidget {
  const TodayTasksScreen.preview({super.key});
  @override
  State<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends State<TodayTasksScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _previewActionNotice = '디자인 미리보기입니다. 실제 기록은 변경되지 않습니다.';
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  TextStyle _style(double size, double lineHeight, [Color color = _ink]) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: lineHeight / size,
        color: color,
        letterSpacing: size == 13 || size == 10 ? -0.1 : 0,
      );

  void _notice(String message) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final navigationHeight = math.max(54.0, 8 + math.max(44, 16 + 26 * scale));
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.paddingOf(context).bottom + navigationHeight + 16,
          ),
          content: Text(message),
        ),
      );
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
            key: const ValueKey('today_tasks_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Original bg 408:2373, rasterized by Figma to preserve SVG blur.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/today_tasks_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('today_tasks_scroll'),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            math.max(
                              2.5,
                              56.5 - MediaQuery.paddingOf(context).top,
                            ),
                            24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(),
                              const SizedBox(height: 10.5),
                              for (final (index, section)
                                  in _sections.indexed) ...[
                                if (index > 0) const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            section.title,
                                            key: ValueKey(
                                              'today_tasks_section_${section.id}',
                                            ),
                                            style: _style(13, 19, _secondary),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${section.tasks.length}',
                                        key: ValueKey(
                                          'today_tasks_count_${section.id}',
                                        ),
                                        style: _style(11, 14, _muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppGlassSurface(
                                  key: ValueKey(
                                    'today_tasks_group_${section.id}',
                                  ),
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
                                      for (final (rowIndex, task)
                                          in section.tasks.indexed) ...[
                                        if (rowIndex > 0)
                                          const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Color(0xFFE6E1D6),
                                          ),
                                        _row(task),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppBottomNavigation(
                          key: const ValueKey('today_tasks_navigation'),
                          currentTab: AppTab.habitat,
                          labelMaxLines: 2,
                          labelStyle: _style(10, 13),
                          selectedLabelColor: _ink,
                          unselectedLabelColor: _secondary,
                          iconAssets: const {
                            AppTab.habitat:
                                'assets/icons/home_first_visit_nav_home.svg',
                            AppTab.records:
                                'assets/icons/home_first_visit_nav_record.svg',
                            AppTab.pets:
                                'assets/icons/home_first_visit_nav_pets.svg',
                            AppTab.profile:
                                'assets/icons/home_first_visit_nav_profile.svg',
                          },
                          onTabSelected: (_) =>
                              _notice('이 미리보기에서는 하단 탭 이동이 연결되지 않았습니다.'),
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

  Widget _header() => ConstrainedBox(
    key: const ValueKey('today_tasks_header'),
    constraints: const BoxConstraints(minHeight: 44),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('10월 20일 화요일', style: _style(11, 14, _muted)),
              Semantics(
                header: true,
                child: Text('오늘 할 일', style: _style(13, 19)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('today_tasks_multi_select'),
              borderRadius: BorderRadius.circular(999),
              onTap: () => _notice('일괄 선택 기능은 아직 연결되지 않았습니다.'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Center(
                  widthFactor: 1,
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    child: Text('여러 개 선택', style: _style(12, 16, _secondary)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _row(_TaskPreview task) {
    final done = task.treatment == _Treatment.done;
    return Semantics(
      button: true,
      label:
          '${task.title}, ${task.description}, ${task.status ?? (done ? '완료 예시' : '일정 예시')}',
      excludeSemantics: true,
      onTap: () => _notice(_previewActionNotice),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('today_tasks_row_${task.id}'),
          onTap: () => _notice(_previewActionNotice),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Opacity(
              key: ValueKey('today_tasks_opacity_${task.id}'),
              opacity: done ? 0.55 : 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackedStatus =
                      task.status != null &&
                      (constraints.maxWidth < 270 ||
                          MediaQuery.textScalerOf(context).scale(11) > 14);
                  final label = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(task.title, style: _style(13, 19)),
                      const SizedBox(height: 2),
                      Text(task.description, style: _style(11, 14, _muted)),
                      if (stackedStatus) ...[
                        const SizedBox(height: 6),
                        _status(task),
                      ],
                    ],
                  );
                  return ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Row(
                      children: [
                        Container(
                          key: ValueKey('today_tasks_avatar_${task.id}'),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? Colors.white
                                : const Color(0xFF2F6B57),
                            border: Border.all(color: const Color(0xE6FFFFFF)),
                          ),
                          child: Text(
                            task.avatar,
                            style: _style(
                              done ? 13 : 10,
                              done ? 19 : 13,
                              done ? _ink : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: label),
                        if (!stackedStatus) ...[
                          const SizedBox(width: 12),
                          if (task.status != null)
                            _status(task)
                          else
                            SvgPicture.asset(
                              'assets/icons/today_tasks_${done ? 'done' : 'pending'}.svg',
                              key: ValueKey('today_tasks_icon_${task.id}'),
                              width: 20,
                              height: 20,
                              excludeFromSemantics: true,
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _status(_TaskPreview task) {
    final warning = task.treatment == _Treatment.feeding;
    return Container(
      key: ValueKey('today_tasks_status_${task.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFBEBD3) : const Color(0xFFFBE3DF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        task.status!,
        style: _style(
          11,
          14,
          warning ? const Color(0xFF96570C) : const Color(0xFFB23B30),
        ),
      ),
    );
  }
}
