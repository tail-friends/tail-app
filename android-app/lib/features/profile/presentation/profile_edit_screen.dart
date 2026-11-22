import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../auth/presentation/login_screen.dart';

const profileEditPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 민준과 아바타는 예시이며, 실제 계정 정보 수정·사진 선택·업로드·저장은 실행되지 않습니다. 닉네임 안내는 시안의 UI 규칙입니다.';
final _previewInProgress = Expando<bool>();

Future<void> showProfileEditPreview(BuildContext context) async {
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
        content: const Text(profileEditPreviewNotice),
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
      MaterialPageRoute(builder: (_) => const ProfileEditScreen.preview()),
    );
  } finally {
    _previewInProgress[navigator] = false;
  }
}

/// Local Debug draft; no account, photo or storage service is connected.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen.preview({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  final _nickname = TextEditingController(text: '민준');
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
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

  void _savePreview() {
    // This is only the visible Figma UI rule, not an approved server policy.
    final name = _nickname.text;
    if (name.characters.length < 2 ||
        !RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$').hasMatch(name)) {
      setState(() => _error = '닉네임은 2–10자의 한글·영문·숫자로 입력해 주세요.');
      return;
    }
    setState(() => _error = null);
    _notice('UI 미리보기입니다. 프로필이 저장되지 않았습니다.');
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
            backgroundColor: const Color(0xFFFAF7F0),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Figma bg 408:2354 is identical to this local background export.
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
                          key: const ValueKey('profile_edit_scroll'),
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
                              ConstrainedBox(
                                key: const ValueKey('profile_edit_header'),
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Row(
                                  children: [
                                    Semantics(
                                      label: '뒤로가기',
                                      button: true,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          key: const ValueKey(
                                            'profile_edit_back',
                                          ),
                                          onTap: _back,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                                                    child: SizedBox.square(
                                                      dimension: 16,
                                                      child: SvgPicture.asset(
                                                        'assets/icons/terms_chevron_left.svg',
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
                                    ),
                                    Expanded(
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          '프로필 편집',
                                          textAlign: TextAlign.center,
                                          style: AppTypography.titleMedium
                                              .copyWith(
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
                              const SizedBox(height: 32),
                              Center(
                                child: Semantics(
                                  label: 'Figma 예시 아바타',
                                  child: Container(
                                    key: const ValueKey('profile_edit_avatar'),
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xE6FFFFFF),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '민',
                                      style: AppTypography.bodyRegular.copyWith(
                                        fontFamily: 'Jua',
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Semantics(
                                  label: '사진 변경, 미연결',
                                  button: true,
                                  child: GestureDetector(
                                    key: const ValueKey('profile_edit_photo'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        _notice('사진 변경 기능은 아직 연결되지 않았습니다.'),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      child: Align(
                                        widthFactor: 1,
                                        heightFactor: 1,
                                        alignment: Alignment.topCenter,
                                        child: AppGlassSurface(
                                          key: const ValueKey(
                                            'profile_edit_photo_surface',
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            '사진 변경',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  fontFamily: 'Jua',
                                                  color: _secondary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              AppTextField(
                                key: const ValueKey('profile_edit_nickname'),
                                label: '닉네임',
                                controller: _nickname,
                                maxLength: 10,
                                errorText: _error,
                                semanticHint: 'Figma 시안의 닉네임, 2–10자 한글·영문·숫자',
                                textInputAction: TextInputAction.done,
                                textStyle: AppTypography.bodyRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: _ink,
                                ),
                                labelStyle: AppTypography.labelMedium.copyWith(
                                  fontFamily: 'Jua',
                                  color: _secondary,
                                ),
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                              ),
                              const SizedBox(height: 22),
                              Text(
                                '2–10자, 한글·영문·숫자',
                                style: AppTypography.captionRegular.copyWith(
                                  fontFamily: 'Jua',
                                  color: const Color(0xFF736E65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppButton(
                        key: const ValueKey('profile_edit_save'),
                        label: '저장',
                        onPressed: _savePreview,
                        backgroundColor: const Color(0xFF2F6B57),
                        textStyle: AppTypography.titleMedium.copyWith(
                          fontFamily: 'Jua',
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
