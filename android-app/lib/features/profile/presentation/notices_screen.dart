import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const noticesPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 공지 제목·날짜·새 공지 표시는 예시이며, 실제 출시·정책 개정·서버 점검 안내가 아닙니다. 공지 API 조회나 읽음 상태 저장은 실행되지 않습니다.';
final _previewOpen = Expando<bool>('notices preview');

/// Local presentation values only; not an API response or persisted read state.
@immutable
class NoticePreviewItem {
  const NoticePreviewItem({
    required this.title,
    required this.displayDate,
    this.showNewIndicator = false,
  });
  final String title;
  final String displayDate;
  final bool showNewIndicator;
}

const _figmaNotices = [
  NoticePreviewItem(
    title: '꼬리친구 1.0이 출시됐어요',
    displayDate: '2026.11.01',
    showNewIndicator: true,
  ),
  NoticePreviewItem(
    title: '사진 캐릭터 생성 품질 개선',
    displayDate: '2026.11.08',
    showNewIndicator: true,
  ),
  NoticePreviewItem(title: '개인정보 처리방침 개정 안내', displayDate: '2026.10.25'),
  NoticePreviewItem(
    title: '서버 점검 안내 (11/12 02:00–04:00)',
    displayDate: '2026.10.20',
  ),
];

Future<void> showNoticesPreview(BuildContext context) async {
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
        content: const Text(noticesPreviewNotice),
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
      MaterialPageRoute(builder: (_) => const NoticesScreen.preview()),
    );
  } finally {
    _previewOpen[navigator] = null;
  }
}

/// Figma 09-7 examples are exposed only in Debug.
class NoticesScreen extends StatefulWidget {
  const NoticesScreen.preview({this.items = _figmaNotices, super.key});
  final List<NoticePreviewItem> items;

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  static const _ink = Color(0xFF2B2A26);

  void _showUnconnectedNotice() {
    if (!kDebugMode) return;
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('공지 상세 화면은 아직 연결되지 않았습니다.')));
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

  Widget _header() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: ConstrainedBox(
      key: const ValueKey('notices_header'),
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
                key: const ValueKey('notices_back'),
                onTap: _back,
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: SizedBox.square(
                  dimension: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppGlassSurface(
                      key: const ValueKey('notices_back_surface'),
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
              '공지사항',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontFamily: 'Jua',
                color: _ink,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    ),
  );

  Widget _row(NoticePreviewItem item, int index) => Semantics(
    label:
        '${item.title}, ${item.displayDate}${item.showNewIndicator ? ', 새 공지 표시' : ''}',
    button: true,
    onTap: _showUnconnectedNotice,
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('notices_item_$index'),
        onTap: _showUnconnectedNotice,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 63),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.bodyRegular.copyWith(
                          fontFamily: 'Jua',
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.displayDate,
                        style: AppTypography.captionRegular.copyWith(
                          fontFamily: 'Jua',
                          color: const Color(0xFF736E65),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.showNewIndicator) ...[
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    'assets/icons/notices_new_dot.svg',
                    key: ValueKey('notices_new_$index'),
                    width: 6,
                    height: 6,
                    excludeFromSemantics: true,
                  ),
                ],
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
            key: const ValueKey('notices_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/account_withdrawal_background.png',
                  key: const ValueKey('notices_background'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  minimum: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: math.max(4, 58 - media.padding.top),
                    ),
                    child: Column(
                      children: [
                        _header(),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('notices_scroll'),
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: AppGlassSurface(
                              key: const ValueKey('notices_card'),
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                transform: GradientRotation(-.644436),
                                colors: [Color(0xC7FFFFFF), Color(0x66FFFFFF)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x143D3329),
                                  offset: Offset(0, 12),
                                  blurRadius: 32,
                                ),
                              ],
                              padding: const EdgeInsets.all(1),
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < widget.items.length;
                                    i++
                                  ) ...[
                                    if (i != 0)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE6E1D6),
                                      ),
                                    _row(widget.items[i], i),
                                  ],
                                ],
                              ),
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
}
