import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'notification_time_sheet.dart';

const notificationTimePreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 알림 설정과 시간은 로컬 예시이며, 실제 알림 예약·권한 요청·급여일 계산·저장은 실행되지 않습니다.';
final _previewInProgress = Expando<bool>();

Future<void> showNotificationTimePreview(BuildContext context) async {
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
        content: const Text(notificationTimePreviewNotice),
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
      MaterialPageRoute(builder: (_) => const NotificationTimePreviewScreen()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// The 09-1-looking backdrop exists only to preview the 09-12 modal in context.
/// It is not an implemented notification settings feature or permission state.
class NotificationTimePreviewScreen extends StatefulWidget {
  const NotificationTimePreviewScreen({
    this.initialTime = const TimeOfDay(hour: 20, minute: 0),
    this.openOnStart = true,
    super.key,
  });
  final TimeOfDay initialTime;
  final bool openOnStart;
  @override
  State<NotificationTimePreviewScreen> createState() =>
      _NotificationTimePreviewScreenState();
}

class _NotificationTimePreviewScreenState
    extends State<NotificationTimePreviewScreen> {
  late TimeOfDay _time = widget.initialTime;
  bool _opening = false;
  final _switches = {
    '급여 알림': true,
    '탈피 예정 알림': true,
    '체중 측정 알림': false,
    '캐릭터 성장 소식': true,
    '이벤트·혜택': false,
  };
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    if (widget.openOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && kDebugMode) _openTime();
      });
    }
  }

  Future<void> _openTime() async {
    if (!kDebugMode || _opening || !mounted) return;
    _opening = true;
    _messenger.currentState?.removeCurrentSnackBar();
    try {
      final selected = await showNotificationTimePreviewSheet(
        context,
        initialTime: _time,
      );
      if (!mounted || selected == null) return;
      setState(() => _time = selected);
      _notice('UI 미리보기입니다. 실제 알림은 예약되거나 저장되지 않았습니다.');
    } finally {
      _opening = false;
    }
  }

  void _notice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _back() {
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

  String get _timeLabel =>
      '${_time.hour >= 12 ? '오후' : '오전'} ${(_time.hour + 11) % 12 + 1}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ScaffoldMessenger(
        key: _messenger,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF7F0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/account_withdrawal_background.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              SafeArea(
                child: SingleChildScrollView(
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
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: '뒤로가기',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey(
                                    'notification_preview_back',
                                  ),
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
                              child: Text(
                                '알림 설정',
                                textAlign: TextAlign.center,
                                style: _style(14, 20),
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('돌봄 알림', style: _style(12, 16, secondary: true)),
                      const SizedBox(height: 20),
                      _group([
                        _toggle('급여 알림', '급여 주기에 맞춰 알려드려요'),
                        _row(
                          '알림 시간',
                          trailing: _timeLabel,
                          onTap: _openTime,
                          key: const ValueKey('notification_preview_time'),
                        ),
                        _toggle('탈피 예정 알림', '예상일 3일 전'),
                        _toggle('체중 측정 알림', '매주 화요일'),
                      ]),
                      const SizedBox(height: 20),
                      Text('소식', style: _style(11, 14, secondary: true)),
                      const SizedBox(height: 20),
                      _group([
                        _toggle('캐릭터 성장 소식', null),
                        _toggle('이벤트·혜택', null),
                      ]),
                      const SizedBox(height: 20),
                      Text('방해 금지', style: _style(11, 14, secondary: true)),
                      const SizedBox(height: 20),
                      _group([
                        _row(
                          '방해 금지 시간',
                          subtitle: '이 시간에는 알림을 보내지 않아요',
                          trailing: '22:00 – 08:00',
                          onTap: () =>
                              _notice('방해 금지 시간 편집은 이번 미리보기 범위가 아닙니다.'),
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
    );
  }

  TextStyle _style(double size, double height, {bool secondary = false}) =>
      AppTypography.bodyRegular.copyWith(
        fontFamily: 'Jua',
        fontSize: size,
        height: height / size,
        color: secondary ? const Color(0xFF6B675E) : const Color(0xFF2B2A26),
      );

  Widget _group(List<Widget> rows) => AppGlassSurface(
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.all(1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE6E1D6)),
          rows[i],
        ],
      ],
    ),
  );

  Widget _toggle(String title, String? subtitle) {
    final value = _switches[title]!;
    return Semantics(
      label: title,
      toggled: value,
      child: _row(
        title,
        subtitle: subtitle,
        onTap: () => setState(() => _switches[title] = !value),
        toggle: value,
      ),
    );
  }

  Widget _row(
    String title, {
    String? subtitle,
    String? trailing,
    bool? toggle,
    required VoidCallback onTap,
    Key? key,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _style(13, 19)),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: _style(
                        11,
                        14,
                        secondary: true,
                      ).copyWith(color: const Color(0xFF736E65)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (toggle != null)
              SizedBox(
                width: 40,
                height: 24,
                child: Center(
                  child: Image.asset(
                    'assets/images/notification_time_switch_${toggle ? 'on' : 'off'}.png',
                    width: 40,
                    height: 24,
                    excludeFromSemantics: true,
                  ),
                ),
              )
            else ...[
              Flexible(
                fit: FlexFit.tight,
                child: Text(
                  trailing!,
                  textAlign: TextAlign.right,
                  style: _style(13, 19, secondary: true),
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/icons/home_metric_chevron_right.svg',
                width: 14,
                height: 14,
                excludeFromSemantics: true,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
