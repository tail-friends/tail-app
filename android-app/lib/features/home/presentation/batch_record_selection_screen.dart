import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const batchRecordSelectionPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 날짜, 개체 및 기록 내용은 예시이며, 선택하거나 버튼을 눌러도 실제 급여·청소 기록은 변경되지 않습니다.';
final _previewNavigators = Expando<bool>();

Future<void> showBatchRecordSelectionPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewNavigators[navigator] == true) return;
  _previewNavigators[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(batchRecordSelectionPreviewNotice),
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
      builder: (_) => const BatchRecordSelectionScreen.preview(),
    );
    await navigator.push(route);
    await route.completed;
  } finally {
    _previewNavigators[navigator] = false;
  }
}

// UI fixture keys only, not pet IDs, schedule types or a server API contract.
enum _Choice { leo, ukki, haru, calcium, uvb }

class _Example {
  const _Example(
    this.id,
    this.title,
    this.detail, {
    this.choice,
    this.status,
    this.avatar,
    this.done = false,
  });
  final String id, title, detail;
  final _Choice? choice;
  final String? status, avatar;
  final bool done;
}

const _groups = <({String id, String title, List<_Example> rows})>[
  (
    id: 'overdue',
    title: '지난 급여',
    rows: [
      _Example(
        'leo',
        '레오',
        '크레스티드 게코 · 귀뚜라미 4마리',
        choice: _Choice.leo,
        status: '2일 지남',
      ),
    ],
  ),
  (
    id: 'feeding',
    title: '오늘 급여',
    rows: [
      _Example(
        'ukki',
        '욱이',
        '레오파드 게코 · 귀뚜라미 5마리',
        choice: _Choice.ukki,
        status: '오늘 급여',
      ),
      _Example(
        'haru',
        '하루',
        '펫테일 게코 · 밀웜 3마리',
        choice: _Choice.haru,
        status: '오늘 급여',
      ),
    ],
  ),
  (
    id: 'schedule',
    title: '오늘 일정',
    rows: [
      _Example(
        'calcium',
        '칼슘 더스팅',
        '욱이 · 하루 · 매주 월·목',
        choice: _Choice.calcium,
      ),
      _Example('uvb', 'UVB 램프 점검', '치토 · 180일마다', choice: _Choice.uvb),
    ],
  ),
  (
    id: 'alert',
    title: '건강 경고',
    rows: [
      _Example('chito', '치토', '최근 30일 체중 12% 감소', status: '확인 필요', avatar: '치'),
    ],
  ),
  (
    id: 'done',
    title: '완료',
    rows: [_Example('sera', '세라', '급여 · 냉동 마우스 1마리', avatar: '세', done: true)],
  ),
];

/// Figma 10-2 fixture; all selection state is discarded with this Debug route.
class BatchRecordSelectionScreen extends StatefulWidget {
  const BatchRecordSelectionScreen.preview({super.key});
  @override
  State<BatchRecordSelectionScreen> createState() => _SelectionState();
}

class _SelectionState extends State<BatchRecordSelectionScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static const _green = Color(0xFF2F6B57);
  final _selected = <_Choice>{_Choice.leo, _Choice.ukki, _Choice.haru};
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _leaving = false;

  String get _selectionLabel {
    final hasSchedule =
        _selected.contains(_Choice.calcium) || _selected.contains(_Choice.uvb);
    return '${_selected.length}${hasSchedule || _selected.isEmpty ? '개' : '마리'} 선택';
  }

  TextStyle _style(double size, double height, [Color color = _ink]) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: height / size,
        color: color,
        letterSpacing: size == 14 ? -0.2 : (size == 13 ? -0.1 : 0),
      );

  void _notice(String message) {
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
            MediaQuery.paddingOf(context).bottom + 140,
          ),
          content: Text(message),
        ),
      );
  }

  void _toggle(_Choice choice) {
    if (_leaving) return;
    setState(() {
      if (!_selected.remove(choice)) _selected.add(choice);
    });
  }

  void _cancel() {
    if (_leaving) return;
    _leaving = true;
    _selected.clear();
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
        if (didPop) {
          _selected.clear();
        } else {
          _cancel();
        }
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
            key: const ValueKey('batch_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Isolated original Figma bg 408:2376, including its blur filters.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/batch_record_selection_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('batch_scroll'),
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
                              for (final (index, group) in _groups.indexed) ...[
                                if (index > 0) const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            group.title,
                                            key: ValueKey(
                                              'batch_section_${group.id}',
                                            ),
                                            style: _style(13, 19, _secondary),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${group.rows.length}',
                                        key: ValueKey(
                                          'batch_count_${group.id}',
                                        ),
                                        style: _style(11, 14, _muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppGlassSurface(
                                  key: ValueKey('batch_group_${group.id}'),
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
                                      for (final (rowIndex, example)
                                          in group.rows.indexed) ...[
                                        if (rowIndex > 0)
                                          const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Color(0xFFE6E1D6),
                                          ),
                                        _row(example),
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
                        child: _bar(),
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
              key: const ValueKey('batch_cancel'),
              onTap: _cancel,
              borderRadius: BorderRadius.circular(999),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Center(
                  widthFactor: 1,
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(999),
                    borderColor: const Color(0xE6E6E1D6),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    boxShadow: const [
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
                    ],
                    child: Text('취소', style: _style(12, 16)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _row(_Example example) {
    final choice = example.choice;
    void activate() =>
        choice == null ? _notice('이 항목은 일괄 선택 대상이 아닙니다.') : _toggle(choice);
    return Semantics(
      key: ValueKey('batch_semantics_${example.id}'),
      checked: choice == null ? null : _selected.contains(choice),
      button: choice == null ? true : null,
      enabled: true,
      label:
          '${example.title}, ${example.detail}, ${example.status ?? (example.done ? '완료 예시, 선택 대상 아님' : '일정 예시')}${choice == null && !example.done ? ', 선택 대상 아님' : ''}',
      excludeSemantics: true,
      onTap: activate,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('batch_row_${example.id}'),
          onTap: activate,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Opacity(
              key: ValueKey('batch_opacity_${example.id}'),
              opacity: example.done ? 0.55 : 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackStatus =
                      example.status != null &&
                      (constraints.maxWidth < 270 ||
                          MediaQuery.textScalerOf(context).scale(11) > 14);
                  return Row(
                    children: [
                      if (choice != null)
                        SvgPicture.asset(
                          'assets/icons/batch_record_${_selected.contains(choice) ? 'checked' : 'unchecked'}.svg',
                          key: ValueKey('batch_checkbox_${example.id}'),
                          width: 20,
                          height: 20,
                          excludeFromSemantics: true,
                        )
                      else
                        Container(
                          key: ValueKey('batch_avatar_${example.id}'),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: example.done ? Colors.white : _green,
                            border: Border.all(color: const Color(0xE6FFFFFF)),
                          ),
                          child: Text(
                            example.avatar!,
                            style: _style(
                              example.done ? 13 : 10,
                              example.done ? 19 : 13,
                              example.done ? _ink : Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(example.title, style: _style(13, 19)),
                            const SizedBox(height: 2),
                            Text(example.detail, style: _style(11, 14, _muted)),
                            if (stackStatus) ...[
                              const SizedBox(height: 6),
                              _status(example),
                            ],
                          ],
                        ),
                      ),
                      if (!stackStatus &&
                          (example.status != null || example.done)) ...[
                        const SizedBox(width: 12),
                        if (example.done)
                          SvgPicture.asset(
                            'assets/icons/batch_record_checked.svg',
                            key: const ValueKey('batch_done_icon'),
                            width: 20,
                            height: 20,
                            excludeFromSemantics: true,
                          )
                        else
                          _status(example),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _status(_Example example) {
    final feeding = example.status == '오늘 급여';
    return Container(
      key: ValueKey('batch_status_${example.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: feeding ? const Color(0xFFFBEBD3) : const Color(0xFFFBE3DF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        example.status!,
        style: _style(
          11,
          14,
          feeding ? const Color(0xFF96570C) : const Color(0xFFB23B30),
        ),
      ),
    );
  }

  Widget _bar() => DecoratedBox(
    key: const ValueKey('batch_bar'),
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 2.5, 8, 2.5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = Semantics(
            liveRegion: true,
            child: Text(
              _selectionLabel,
              key: const ValueKey('batch_selected_count'),
              style: _style(14, 20, Colors.white),
            ),
          );
          final feed = _action('feed', '급여 완료', '일괄 급여 기록 기능은 아직 연결되지 않았습니다.');
          final clean = _action('clean', '청소', '일괄 청소 기록 기능은 아직 연결되지 않았습니다.');
          if (constraints.maxWidth < 250 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: count),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: feed),
                    const SizedBox(width: 10),
                    Expanded(child: clean),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: count),
              const SizedBox(width: 10),
              feed,
              const SizedBox(width: 10),
              clean,
            ],
          );
        },
      ),
    ),
  );

  Widget _action(String id, String title, String message) => Semantics(
    button: true,
    enabled: _selected.isNotEmpty,
    label: title,
    excludeSemantics: true,
    onTap: _selected.isEmpty ? null : () => _notice(message),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('batch_action_$id'),
        borderRadius: BorderRadius.circular(999),
        onTap: _selected.isEmpty ? null : () => _notice(message),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: Opacity(
              opacity: _selected.isEmpty ? 0.4 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: _style(13, 19),
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
