import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const dataPhotoSettingsPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 사진 7장, 저장 용량 및 내보내기 날짜는 예시이며, 실제 사진 보관·삭제·내보내기는 실행되지 않습니다. 캐릭터와 썸네일의 보존 안내도 시안 문구이며 확정된 서비스 정책이 아닙니다.';
final _previewInProgress = Expando<bool>();

Future<void> showDataPhotoSettingsPreview(BuildContext context) async {
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
        content: const Text(dataPhotoSettingsPreviewNotice),
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
        builder: (_) => const DataPhotoSettingsScreen.preview(),
      ),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// Design fixture only. No photo, filesystem, export, or persistence service.
class DataPhotoSettingsScreen extends StatefulWidget {
  const DataPhotoSettingsScreen.preview({super.key});
  @override
  State<DataPhotoSettingsScreen> createState() =>
      _DataPhotoSettingsScreenState();
}

class _DataPhotoSettingsScreenState extends State<DataPhotoSettingsScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  bool _keepOriginals = true;
  bool _confirmOpen = true;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  void _notice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            key: const ValueKey('data_photo_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Original Figma bg 408:2394 PNG preserves the SVG's blur filters.
                Image.asset(
                  'assets/images/data_photo_background.png',
                  key: const ValueKey('data_photo_background'),
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
                          key: const ValueKey('data_photo_header'),
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            children: [
                              Semantics(
                                button: true,
                                label: '뒤로가기',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: const ValueKey('data_photo_back'),
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
                                    '데이터 · 사진',
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
                        const SizedBox(height: 18),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('data_photo_scroll'),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _section('원본 사진'),
                                const SizedBox(height: 18),
                                _group('photos', [
                                  Semantics(
                                    key: const ValueKey('data_photo_keep'),
                                    label: '원본 사진 보관',
                                    hint:
                                        '실사풍 캐릭터 전환 때 다시 올리지 않아도 돼요. 디자인 예시이며 실제 보관 설정은 바뀌지 않습니다.',
                                    toggled: _keepOriginals,
                                    enabled: true,
                                    excludeSemantics: true,
                                    onTap: () => setState(
                                      () => _keepOriginals = !_keepOriginals,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        excludeFromSemantics: true,
                                        onTap: () => setState(
                                          () =>
                                              _keepOriginals = !_keepOriginals,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _labels(
                                                  '원본 사진 보관',
                                                  '실사풍 캐릭터 전환 때 다시 올리지 않아도 돼요',
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Image.asset(
                                                'assets/images/${_keepOriginals ? 'data_photo_switch_on.png' : 'notification_time_switch_off.png'}',
                                                key: const ValueKey(
                                                  'data_photo_switch',
                                                ),
                                                width: 40,
                                                height: 24,
                                                excludeFromSemantics: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE6E1D6),
                                  ),
                                  _action(
                                    'delete_row',
                                    '보관 사진 모두 삭제',
                                    '현재 7장 · 약 2.1MB',
                                    () => setState(() => _confirmOpen = true),
                                    danger: true,
                                  ),
                                ]),
                                if (_confirmOpen) ...[
                                  const SizedBox(height: 18),
                                  _confirmation(),
                                ],
                                const SizedBox(height: 18),
                                _section('기록 내보내기 · 이후'),
                                const SizedBox(height: 18),
                                _group('exports', [
                                  _action(
                                    'csv',
                                    'CSV로 내보내기',
                                    '기간: 2026.01.01 – 10.20',
                                    () =>
                                        _notice('CSV 내보내기 기능은 아직 연결되지 않았습니다.'),
                                    chevron: true,
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE6E1D6),
                                  ),
                                  _action(
                                    'pdf',
                                    '수의사용 PDF 리포트',
                                    '최근 3개월 체중·급여·탈피·진료 요약',
                                    () => _notice('PDF 리포트 기능은 아직 연결되지 않았습니다.'),
                                    chevron: true,
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

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: AppTypography.bodyRegular.copyWith(
          fontFamily: 'Jua',
          color: _secondary,
        ),
      ),
    ),
  );
  Widget _labels(String title, String subtitle, {bool danger = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyRegular.copyWith(
              fontFamily: 'Jua',
              color: danger ? const Color(0xFFB23B30) : _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.captionRegular.copyWith(
              fontFamily: 'Jua',
              color: _tertiary,
            ),
          ),
        ],
      );
  Widget _group(String name, List<Widget> rows) => AppGlassSurface(
    key: ValueKey('data_photo_$name'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 3),
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    child: Column(children: rows),
  );

  Widget _action(
    String name,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool danger = false,
    bool chevron = false,
  }) => Semantics(
    button: true,
    label: title,
    hint: subtitle,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('data_photo_$name'),
        excludeFromSemantics: true,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: _labels(title, subtitle, danger: danger)),
                if (chevron) ...[
                  const SizedBox(width: 12),
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
      ),
    ),
  );

  Widget _confirmation() => AppGlassSurface(
    key: const ValueKey('data_photo_confirm'),
    borderRadius: BorderRadius.circular(22),
    gradient: const LinearGradient(
      begin: Alignment(-.295, -1.82),
      end: Alignment(.295, 1.82),
      colors: [Color(0xE0FFFFFF), Color(0xBFF3E2C2)],
    ),
    // 36px visuals retain their Figma position; the extra touch height uses bottom padding.
    padding: const EdgeInsets.fromLTRB(17, 17, 17, 9),
    boxShadow: const [
      BoxShadow(color: Color(0x0F3D2E1F), offset: Offset(0, 8), blurRadius: 24),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '보관한 원본 사진 7장을 지울까요?',
          style: AppTypography.bodyRegular.copyWith(
            fontFamily: 'Jua',
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '캐릭터와 썸네일은 그대로 남아요',
          style: AppTypography.captionRegular.copyWith(
            fontFamily: 'Jua',
            color: _secondary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _confirmButton(false)),
            const SizedBox(width: 8),
            Expanded(child: _confirmButton(true)),
          ],
        ),
      ],
    ),
  );

  Widget _confirmButton(bool delete) {
    final label = delete ? '삭제' : '취소';
    void onTap() {
      if (delete) {
        _notice('미리보기에서는 사진을 삭제하지 않습니다.');
      } else {
        _messenger.currentState?.removeCurrentSnackBar();
        setState(() => _confirmOpen = false);
      }
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Center(
        child: Text(
          label,
          style: AppTypography.bodyRegular.copyWith(
            fontFamily: 'Jua',
            height: 20 / 13,
            letterSpacing: -.2,
            color: delete ? Colors.white : _ink,
          ),
        ),
      ),
    );
    final visual = delete
        ? DecoratedBox(
            key: const ValueKey('data_photo_delete_visual'),
            decoration: BoxDecoration(
              color: const Color(0xFFC0463A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE6E1D6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A804D40),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: content,
          )
        : AppGlassSurface(
            key: const ValueKey('data_photo_cancel_visual'),
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xB3FFFFFF), Color(0x59FFFFFF)],
            ),
            child: content,
          );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('data_photo_${delete ? 'delete' : 'cancel'}'),
          excludeFromSemantics: true,
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1,
              child: visual,
            ),
          ),
        ),
      ),
    );
  }
}
