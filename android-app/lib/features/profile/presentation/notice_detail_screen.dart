import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const noticeDetailPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 공지 제목·날짜·출시 및 기능 안내 문구는 예시이며, 실제 출시 공지나 지원 기능을 의미하지 않습니다. 공지 API 조회나 읽음 상태 저장은 실행되지 않습니다.';
final _previewOpen = Expando<bool>();

Future<void> showNoticeDetailPreview(BuildContext context) async {
  if (!kDebugMode || !context.mounted) return;
  final navigator = Navigator.of(context);
  if (_previewOpen[navigator] == true) return;
  _previewOpen[navigator] = true;
  try {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디자인 미리보기'),
        scrollable: true,
        content: const Text(noticeDetailPreviewNotice),
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
      MaterialPageRoute(builder: (_) => const NoticeDetailScreen.preview()),
    );
  } finally {
    _previewOpen[navigator] = false;
  }
}

/// Figma 09-13 example copy only; not fetched, published or marked as read.
class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen.preview({super.key});

  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  static const _paragraphs = [
    '안녕하세요, 꼬리친구 팀이에요. 우리 아이의 하루를 기록하고, 사진 한 장으로 캐릭터를 만드는 꼬리친구가 정식 출시됐어요.',
    '급여·탈피·체중 기록, 돌봄 주기 알림, 사진 기반 캐릭터를 지금 바로 사용해 보세요. 의견은 마이 › 문의하기로 보내주세요.',
  ];

  void _back(BuildContext context) {
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
    final bodyStyle = AppTypography.bodyRegular.copyWith(
      fontFamily: 'Jua',
      color: _secondary,
    );
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: '공지 상세 디자인 미리보기',
          child: Scaffold(
            key: const ValueKey('notice_detail_screen'),
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma bg 408:2356 matches the existing local export exactly.
                Image.asset(
                  'assets/images/account_withdrawal_background.png',
                  key: const ValueKey('notice_detail_background'),
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
                        SizedBox(
                          key: const ValueKey('notice_detail_header'),
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Semantics(
                              button: true,
                              label: '뒤로가기',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey('notice_detail_back'),
                                  onTap: () => _back(context),
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
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('notice_detail_scroll'),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // The navbar title is empty in Figma; the article has the heading.
                                Semantics(
                                  header: true,
                                  child: Text(
                                    '꼬리친구 1.0이 출시됐어요',
                                    key: const ValueKey('notice_detail_title'),
                                    style: bodyStyle.copyWith(color: _ink),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '2026.11.01',
                                  key: const ValueKey('notice_detail_date'),
                                  style: AppTypography.captionRegular.copyWith(
                                    fontFamily: 'Jua',
                                    color: _tertiary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                AppGlassSurface(
                                  key: const ValueKey('notice_detail_card'),
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: AppColors.glassSoftGradient,
                                  padding: const EdgeInsets.all(21),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x143D3329),
                                      offset: Offset(0, 12),
                                      blurRadius: 32,
                                    ),
                                  ],
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: DecoratedBox(
                                          key: const ValueKey(
                                            'notice_detail_cover',
                                          ),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              // CSS 153.435deg on the original 300x150 cover.
                                              begin: Alignment(-.4, -1.6),
                                              end: Alignment(.4, 1.6),
                                              stops: [.25, .75],
                                              colors: [
                                                Color(0xFFF3E2C2),
                                                Color(0xFFE6E1D6),
                                              ],
                                            ),
                                          ),
                                          child: const SizedBox(
                                            height: 150,
                                            child: Stack(
                                              children: [
                                                // character/lizard is empty in the source design.
                                                Positioned(
                                                  left: 123,
                                                  top: 30,
                                                  child: SizedBox(
                                                    key: ValueKey(
                                                      'notice_detail_character_slot',
                                                    ),
                                                    width: 60,
                                                    height: 90,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      for (
                                        var i = 0;
                                        i < _paragraphs.length;
                                        i++
                                      ) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _paragraphs[i],
                                          key: ValueKey(
                                            'notice_detail_paragraph_$i',
                                          ),
                                          style: bodyStyle,
                                        ),
                                      ],
                                    ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
