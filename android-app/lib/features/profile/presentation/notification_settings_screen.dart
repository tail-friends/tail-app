import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';
import 'notification_time_sheet.dart';

const notificationSettingsPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 스위치와 시간은 예시이며 화면 안에서만 변경됩니다. 실제 알림 권한·예약·수신 설정이나 서버 데이터를 바꾸지 않으며, 다시 열면 기본값으로 초기화됩니다.';
final _previewInProgress = Expando<bool>();

Future<void> showNotificationSettingsPreview(BuildContext context) async {
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
        content: const Text(notificationSettingsPreviewNotice),
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
      MaterialPageRoute(
        builder: (_) => const NotificationSettingsScreen.preview(),
      ),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// Debug-only, in-memory UI state. No notification or storage service exists here.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen.preview({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

enum _Toggle { feeding, shedding, weight, growth, events }

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  final _values = {
    _Toggle.feeding: true,
    _Toggle.shedding: true,
    _Toggle.weight: false,
    _Toggle.growth: true,
    _Toggle.events: false,
  };
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _timeOpen = false;

  String get _timeLabel =>
      '${_time.hour >= 12 ? '오후' : '오전'} ${(_time.hour + 11) % 12 + 1}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _chooseTime() async {
    if (!kDebugMode ||
        !mounted ||
        _timeOpen ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _timeOpen = true;
    _messenger.currentState?.removeCurrentSnackBar();
    try {
      final selected = await showNotificationTimePreviewSheet(
        context,
        initialTime: _time,
      );
      if (selected == null || !mounted) return;
      setState(() => _time = selected);
    } finally {
      _timeOpen = false;
    }
  }

  void _unavailable() {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('방해 금지 시간 변경 기능은 아직 연결되지 않았습니다.')),
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
            key: const ValueKey('notification_settings_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma SVG bg 408:2345 has filters; its PNG export matches this asset.
                Image.asset(
                  'assets/images/account_withdrawal_background.png',
                  key: const ValueKey('notification_settings_background'),
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
                          key: const ValueKey('notification_settings_header'),
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
                                      'notification_settings_back',
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
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    '알림 설정',
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
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('notification_settings_scroll'),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    '돌봄 알림',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontFamily: 'Jua',
                                      color: _secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _group('care', [
                                  _toggle(
                                    _Toggle.feeding,
                                    '급여 알림',
                                    '급여 주기에 맞춰 알려드려요',
                                  ),
                                  _action(
                                    'time',
                                    '알림 시간',
                                    _timeLabel,
                                    _chooseTime,
                                  ),
                                  _toggle(
                                    _Toggle.shedding,
                                    '탈피 예정 알림',
                                    '예상일 3일 전',
                                  ),
                                  _toggle(_Toggle.weight, '체중 측정 알림', '매주 화요일'),
                                ]),
                                const SizedBox(height: 20),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    '소식',
                                    style: AppTypography.captionRegular
                                        .copyWith(
                                          fontFamily: 'Jua',
                                          color: _secondary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _group('news', [
                                  _toggle(_Toggle.growth, '캐릭터 성장 소식'),
                                  _toggle(_Toggle.events, '이벤트·혜택'),
                                ]),
                                const SizedBox(height: 20),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    '방해 금지',
                                    style: AppTypography.captionRegular
                                        .copyWith(
                                          fontFamily: 'Jua',
                                          color: _secondary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _group('quiet', [
                                  _action(
                                    'quiet',
                                    '방해 금지 시간',
                                    '22:00 – 08:00',
                                    _unavailable,
                                    subtitle: '이 시간에는 알림을 보내지 않아요',
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
      ),
    );
  }

  Widget _group(String name, List<Widget> rows) => AppGlassSurface(
    key: ValueKey('notification_settings_${name}_group'),
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

  Widget _labels(String title, String? subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTypography.bodyRegular.copyWith(
          fontFamily: 'Jua',
          color: _ink,
        ),
      ),
      if (subtitle != null)
        Text(
          subtitle,
          style: AppTypography.captionRegular.copyWith(
            fontFamily: 'Jua',
            color: _tertiary,
          ),
        ),
    ],
  );

  Widget _toggle(_Toggle kind, String title, [String? subtitle]) {
    final value = _values[kind]!;
    void toggle() => setState(() => _values[kind] = !value);
    final onAsset = kind == _Toggle.feeding
        ? 'notification_time_switch_on.png'
        : 'notification_settings_switch_on.png';
    return Semantics(
      key: ValueKey('notification_settings_toggle_${kind.name}'),
      label: title,
      hint: subtitle,
      toggled: value,
      enabled: true,
      onTap: toggle,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          excludeFromSemantics: true,
          onTap: toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: _labels(title, subtitle)),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/${value ? onAsset : 'notification_time_switch_off.png'}',
                  key: ValueKey('notification_settings_switch_${kind.name}'),
                  width: 40,
                  height: 24,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(
    String name,
    String title,
    String value,
    VoidCallback onTap, {
    String? subtitle,
  }) => Semantics(
    key: ValueKey('notification_settings_${name}_action'),
    button: true,
    label: title,
    value: value,
    hint: subtitle,
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('notification_settings_${name}_tap'),
        excludeFromSemantics: true,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(child: _labels(title, subtitle)),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * .45,
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AppTypography.bodyRegular.copyWith(
                      fontFamily: 'Jua',
                      color: _secondary,
                    ),
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
            ),
          ),
        ),
      ),
    ),
  );
}
