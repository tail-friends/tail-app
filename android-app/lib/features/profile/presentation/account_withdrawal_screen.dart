import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const accountWithdrawalPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 친구 7마리·기록 128개와 삭제·복구 관련 문구는 시안 예시이며 확정된 정책이나 실제 계정 정보가 아닙니다. 실제 회원 탈퇴·데이터 삭제·토큰 삭제는 실행되지 않습니다.';
final _previewOpen = Expando<bool>('account withdrawal preview');

Future<void> showAccountWithdrawalPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewOpen[navigator] ?? false) return;
  _previewOpen[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(accountWithdrawalPreviewNotice),
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
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => const AccountWithdrawalScreen.preview(),
      ),
    );
  } finally {
    _previewOpen[navigator] = null;
  }
}

/// Figma 09-5 presentation only; these labels are not server reason codes.
class AccountWithdrawalScreen extends StatefulWidget {
  const AccountWithdrawalScreen.preview({super.key});

  @override
  State<AccountWithdrawalScreen> createState() =>
      _AccountWithdrawalScreenState();
}

class _AccountWithdrawalScreenState extends State<AccountWithdrawalScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF6B675E);
  static const _reasons = [
    '더 이상 파충류를 키우지 않아요',
    '기록 기능이 부족해요',
    '다른 앱을 사용해요',
    '기타',
  ];
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  int? _reason;
  bool _acknowledged = false;

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

  void _requestWithdrawalPreview() {
    if (!kDebugMode || !_acknowledged) return;
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('회원 탈퇴 기능은 아직 연결되지 않았습니다.')));
  }

  TextStyle _text(TextStyle token, {Color color = _ink}) =>
      token.copyWith(fontFamily: 'Jua', color: color);

  Widget _glass(
    Widget child, {
    Key? key,
    BorderRadius? radius,
    Gradient gradient = AppColors.glassSoftGradient,
  }) => AppGlassSurface(
    key: key,
    borderRadius: radius ?? BorderRadius.circular(22),
    gradient: gradient,
    boxShadow: const [
      BoxShadow(
        color: Color(0x143D3329),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    child: child,
  );

  Widget _selection({
    required String label,
    required bool checked,
    required VoidCallback onTap,
    required Key key,
    bool exclusive = false,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 11,
    ),
  }) => Semantics(
    label: label,
    checked: checked,
    inMutuallyExclusiveGroup: exclusive,
    enabled: true,
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                SvgPicture.asset(
                  checked
                      ? 'assets/icons/account_withdrawal_checked.svg'
                      : 'assets/icons/account_withdrawal_unchecked.svg',
                  width: 18,
                  height: 18,
                  excludeFromSemantics: true,
                ),
                SizedBox(width: exclusive ? 10 : 8),
                Expanded(
                  child: Text(label, style: _text(AppTypography.bodyRegular)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => ConstrainedBox(
    key: const ValueKey('withdrawal_header'),
    constraints: const BoxConstraints(minHeight: 44),
    child: Row(
      children: [
        Semantics(
          label: '뒤로가기',
          button: true,
          excludeSemantics: true,
          onTap: _back,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('withdrawal_back'),
              onTap: _back,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: SizedBox.square(
                dimension: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 16,
                          child: FittedBox(
                            child: SvgPicture.asset(
                              'assets/icons/terms_chevron_left.svg',
                              width: 24,
                              height: 24,
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
        ),
        Expanded(
          child: Text(
            '회원 탈퇴',
            textAlign: TextAlign.center,
            style: _text(AppTypography.titleMedium),
          ),
        ),
        const SizedBox(width: 44),
      ],
    ),
  );

  Widget _intro() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      children: [
        _glass(
          const SizedBox.square(
            dimension: 88,
            child: Center(
              child: SizedBox(
                key: ValueKey('withdrawal_empty_character'),
                width: 36,
                height: 54,
              ),
            ),
          ),
          key: const ValueKey('withdrawal_character_surface'),
          radius: BorderRadius.circular(AppRadius.full),
        ),
        const SizedBox(height: 12),
        Text('정말 떠나시나요?', style: _text(AppTypography.titleLarge)),
        const SizedBox(height: 4),
        Text(
          '탈퇴 전에 아래 내용을 꼭 확인해 주세요',
          textAlign: TextAlign.center,
          style: _text(AppTypography.captionRegular, color: _muted),
        ),
      ],
    ),
  );

  Widget _warnings() => _glass(
    Padding(
      // Original 18px content padding plus 1px border.
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, label) in [
            '친구 7마리와 캐릭터가 모두 삭제돼요',
            '기록 128개는 복구할 수 없어요',
            '같은 계정으로 다시 가입해도 이전 기록은 없어요',
          ].indexed) ...[
            if (index != 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/account_withdrawal_bullet.svg',
                  width: 4,
                  height: 12,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: _text(AppTypography.bodyRegular)),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    key: const ValueKey('withdrawal_warnings'),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      transform: GradientRotation(-.324377),
      colors: [Color(0xC7FFFFFF), Color(0x66FFFFFF)],
    ),
  );

  Widget _reasonList() => _glass(
    Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var i = 0; i < _reasons.length; i++) ...[
            if (i != 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFE6E1D6)),
            _selection(
              key: ValueKey('withdrawal_reason_$i'),
              label: _reasons[i],
              checked: _reason == i,
              exclusive: true,
              onTap: () => setState(() => _reason = _reason == i ? null : i),
            ),
          ],
        ],
      ),
    ),
    key: const ValueKey('withdrawal_reasons'),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      transform: GradientRotation(-.458961),
      colors: [Color(0xC7FFFFFF), Color(0x66FFFFFF)],
    ),
  );

  Widget _footer() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _selection(
        key: const ValueKey('withdrawal_acknowledge'),
        label: '안내 사항을 모두 확인했어요',
        checked: _acknowledged,
        padding: EdgeInsets.zero,
        onTap: () => setState(() => _acknowledged = !_acknowledged),
      ),
      const SizedBox(height: 4),
      AnimatedOpacity(
        opacity: _acknowledged ? 1 : .4,
        duration: const Duration(milliseconds: 150),
        child: AppGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.full),
          blur: 0,
          borderColor: Colors.transparent,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            transform: GradientRotation(-.13944),
            colors: [Color(0xFFC0463A), Color(0xFFA83A30)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x38734033),
              offset: Offset(0, 8),
              blurRadius: 20,
            ),
          ],
          child: TextButton(
            key: const ValueKey('withdrawal_submit'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
              textStyle: _text(AppTypography.titleMedium),
            ),
            onPressed: _acknowledged ? _requestWithdrawalPreview : null,
            child: const Text('탈퇴하기'),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            key: const ValueKey('withdrawal_screen'),
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
                  minimum: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    math.max(34, media.padding.bottom),
                  ),
                  child: CustomScrollView(
                    key: const ValueKey('withdrawal_scroll'),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: math.max(4, 58 - media.padding.top),
                        ),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(),
                              const SizedBox(height: 22),
                              _intro(),
                              const SizedBox(height: 22),
                              _warnings(),
                              const SizedBox(height: 22),
                              Text(
                                '떠나는 이유를 알려주세요 (선택)',
                                style: _text(
                                  AppTypography.labelMedium,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _reasonList(),
                              const SizedBox(height: 22),
                              const Spacer(),
                              _footer(),
                            ],
                          ),
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
}
