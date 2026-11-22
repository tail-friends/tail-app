import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const inquiryPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 문의는 전송되지 않으며, 스크린샷 첨부와 이메일 발송은 실행되지 않습니다.';

Future<void> showInquiryPreview(BuildContext context) async {
  if (!kDebugMode) return;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('디자인 미리보기'),
      scrollable: true,
      content: const Text(inquiryPreviewNotice),
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
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const InquiryScreen.preview()),
  );
}

/// Local UI draft only: no account, attachment, transport or persistence service.
class InquiryScreen extends StatefulWidget {
  const InquiryScreen.preview({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _tertiary = Color(0xFF736E65);
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  String _category = '앱 오류';

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _notice(String message) {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 94),
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
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma bg 408:2352 is byte-identical to this existing export.
                Image.asset(
                  'assets/images/account_withdrawal_background.png',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(24, 0, 24, 34),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('inquiry_scroll'),
                          padding: EdgeInsets.only(
                            top: math.max(
                              4,
                              58 - MediaQuery.paddingOf(context).top,
                            ),
                            bottom: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 44,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      '문의하기',
                                      style: AppTypography.titleMedium.copyWith(
                                        fontFamily: 'Jua',
                                        color: _ink,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Semantics(
                                        label: '뒤로가기',
                                        button: true,
                                        child: GestureDetector(
                                          key: const ValueKey('inquiry_back'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _back,
                                          child: SizedBox.square(
                                            dimension: 44,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: AppGlassSurface(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                child: SizedBox.square(
                                                  dimension: 36,
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      'assets/icons/terms_chevron_left.svg',
                                                      width: 16,
                                                      height: 16,
                                                      excludeFromSemantics:
                                                          true,
                                                    ),
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
                              const SizedBox(height: 20),
                              Text(
                                '문의 유형',
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  '앱 오류',
                                  '캐릭터',
                                  '계정',
                                  '제안',
                                ].map(_categoryChip).toList(),
                              ),
                              const SizedBox(height: 6),
                              AppTextField(
                                key: const ValueKey('inquiry_title'),
                                label: '제목',
                                textStyle: AppTypography.bodyRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _ink,
                                ),
                                labelStyle: AppTypography.labelMedium.copyWith(
                                  fontFamily: 'Jua',
                                  color: _secondary,
                                ),
                                controller: _title,
                                hintText: '캐릭터가 생성되지 않아요',
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '내용',
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AppGlassSurface(
                                key: const ValueKey('inquiry_content_surface'),
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 140,
                                  ),
                                  child: Semantics(
                                    label: '내용',
                                    child: TextFormField(
                                      key: const ValueKey('inquiry_content'),
                                      controller: _content,
                                      maxLength: 1000,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      style: AppTypography.bodyRegular.copyWith(
                                        fontFamily: 'Jua',
                                        color: _ink,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintStyle: AppTypography.bodyRegular
                                            .copyWith(
                                              fontFamily: 'Jua',
                                              color: _secondary,
                                            ),
                                        hintText:
                                            '사진을 올리면 68%에서 멈춰요. 아이폰 15, iOS 18입니다.',
                                        semanticCounterText: '',
                                        counterText: '',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Semantics(
                                label:
                                    '${_content.text.characters.length}자 / 최대 1000자',
                                child: Text(
                                  '${_content.text.characters.length} / 1000',
                                  style: AppTypography.captionRegular.copyWith(
                                    fontFamily: 'Jua',
                                    color: _tertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Semantics(
                                button: true,
                                label: '스크린샷 첨부, 최대 3장, 미연결',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: const ValueKey('inquiry_attach'),
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        _notice('스크린샷 첨부 기능은 아직 연결되지 않았습니다.'),
                                    child: AppGlassSurface(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xC7FFFFFF),
                                          Color(0x66FFFFFF),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/photo_add_camera.svg',
                                            width: 16,
                                            height: 16,
                                            excludeFromSemantics: true,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '스크린샷 첨부 (최대 3장)',
                                              style: AppTypography
                                                  .captionRegular
                                                  .copyWith(
                                                    fontFamily: 'Jua',
                                                    color: _secondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '답변은 가입한 이메일로 보내드려요',
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppButton(
                        key: const ValueKey('inquiry_send'),
                        label: '보내기',
                        backgroundColor: const Color(0xFF2F6B57),
                        textStyle: AppTypography.titleMedium.copyWith(
                          fontFamily: 'Jua',
                        ),
                        onPressed: () => _notice('UI 미리보기입니다. 문의가 전송되지 않았습니다.'),
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

  Widget _categoryChip(String category) {
    final selected = _category == category;
    return Semantics(
      button: true,
      selected: selected,
      label: category,
      child: GestureDetector(
        key: ValueKey('inquiry_category_$category'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _category = category),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 46),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            alignment: Alignment.topCenter,
            child: AppGlassSurface(
              borderRadius: BorderRadius.circular(999),
              borderColor: selected ? const Color(0xE6E6E1D6) : Colors.white,
              gradient: selected
                  ? const LinearGradient(colors: [Colors.white, Colors.white])
                  : AppColors.glassStrongGradient,
              boxShadow: selected
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
                  : const [],
              padding: EdgeInsets.symmetric(
                horizontal: category == '앱 오류' ? 12 : 14,
                vertical: 7,
              ),
              child: Text(
                category,
                style: AppTypography.labelMedium.copyWith(
                  fontFamily: 'Jua',
                  color: selected ? _ink : _secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
