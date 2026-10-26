import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import 'login_screen.dart';

/// Development preview only; opening this route does not authenticate a user.
class PrivacyConsentPreviewScreen extends StatefulWidget {
  const PrivacyConsentPreviewScreen({super.key});

  @override
  State<PrivacyConsentPreviewScreen> createState() =>
      _PrivacyConsentPreviewScreenState();
}

class _PrivacyConsentPreviewScreenState
    extends State<PrivacyConsentPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showPrivacyConsentPreview(context);
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}

Future<void> showPrivacyConsentPreview(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x332F6B57),
    barrierLabel: '개인정보 동의 미리보기 닫기',
    builder: (context) => Padding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      child: const PrivacyConsentSheet(),
    ),
  );
}

class PrivacyConsentSheet extends StatefulWidget {
  const PrivacyConsentSheet({super.key});

  @override
  State<PrivacyConsentSheet> createState() => _PrivacyConsentSheetState();
}

class _PrivacyConsentSheetState extends State<PrivacyConsentSheet> {
  static const _ink = Color(0xFF2B2A26);
  static const _muted = Color(0xFF736E65);
  static const _green = Color(0xFF2F6B57);
  static const _border = Color(0xFFE6E1D6);
  static const _body = TextStyle(
    fontFamily: 'Jua',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 19 / 13,
    letterSpacing: -0.1,
    color: _ink,
  );
  static const _caption = TextStyle(
    fontFamily: 'Jua',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 14 / 11,
    color: _muted,
  );

  // Figma UI copy and required markers are provisional, not a legal contract.
  // These choices stay in this widget and are never saved or transmitted.
  static const _items = [
    (
      id: 'personal',
      title: '개인정보 수집 및 이용 동의',
      description: '계정 식별자, 닉네임, 개체·사육 기록을 서비스 제공에 사용해요',
      required: true,
    ),
    (
      id: 'analysis',
      title: '사진 분석을 위한 이미지 전송 동의',
      description: '캐릭터 생성을 위해 사진을 AI 분석 서버로 보내요',
      required: true,
    ),
    (
      id: 'original',
      title: '원본 사진 보관 동의',
      description: '나중에 실사풍 캐릭터로 바꿀 때 다시 올리지 않아도 돼요. 설정에서 언제든 끄고 지울 수 있어요',
      required: false,
    ),
    (
      id: 'notifications',
      title: '알림 수신 동의',
      description: '급여일·탈피 예정일을 알려드려요',
      required: false,
    ),
  ];
  final _selected = <String>{};

  bool get _allSelected => _selected.length == _items.length;
  bool get _requiredSelected => _items
      .where((item) => item.required)
      .every((item) => _selected.contains(item.id));

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _showPreviewNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 동의 미리보기'),
        content: const Text('UI 미리보기입니다. 동의는 저장되지 않으며 로그인되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '개인정보 동의 미리보기',
      onDismiss: () => Navigator.of(context).pop(),
      child: Material(
        key: const ValueKey('privacy_consent_sheet'),
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          side: BorderSide(color: AppColors.borderGlass),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          key: const ValueKey('consent_scroll'),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x6,
            10,
            AppSpacing.x6,
            math.max(34, MediaQuery.paddingOf(context).bottom),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.x5,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text('개인정보 동의', style: _body),
                  Text('꼬리친구를 시작하려면 필수 항목에 동의해 주세요', style: _caption),
                ],
              ),
              AppGlassSurface(
                borderRadius: BorderRadius.circular(22),
                gradient: AppColors.glassSoftGradient,
                child: _checkRow(
                  id: 'all',
                  label: '전체 동의',
                  checked: _allSelected,
                  onTap: () => setState(() {
                    if (_allSelected) {
                      _selected.clear();
                    } else {
                      _selected.addAll(_items.map((item) => item.id));
                    }
                  }),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x4,
                    vertical: 14,
                  ),
                  child: const Text('전체 동의', style: _body),
                ),
              ),
              const Divider(color: _border, height: 1, thickness: 1),
              for (final item in _items)
                _checkRow(
                  id: item.id,
                  label:
                      '${item.required ? '필수' : '선택'}, ${item.title}, ${item.description}',
                  checked: _selected.contains(item.id),
                  onTap: () => _toggle(item.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.required
                                  ? const Color(0xFFE4EEDF)
                                  : const Color(0xFFF3EFE6),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              item.required ? '필수' : '선택',
                              style: _caption.copyWith(
                                color: item.required
                                    ? _green
                                    : const Color(0xFF6B675E),
                              ),
                            ),
                          ),
                          Expanded(child: Text(item.title, style: _body)),
                        ],
                      ),
                      Text(
                        item.description,
                        style: _body.copyWith(
                          fontSize: 12,
                          height: 17 / 12,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              Semantics(
                hint: _requiredSelected
                    ? '미리보기 안내를 표시합니다. 동의와 로그인은 처리되지 않습니다.'
                    : '필수 항목 두 개를 모두 선택해 주세요.',
                child: AppButton(
                  key: const ValueKey('consent_continue'),
                  label: '동의하고 시작하기',
                  backgroundColor: _green,
                  textStyle: _body.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: -0.2,
                  ),
                  onPressed: _requiredSelected ? _showPreviewNotice : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkRow({
    required String id,
    required String label,
    required bool checked,
    required VoidCallback onTap,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
  }) {
    return Semantics(
      key: ValueKey('consent_$id'),
      checked: checked,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                SvgPicture.asset(
                  checked
                      ? 'assets/icons/consent_checked.svg'
                      : 'assets/icons/consent_unchecked.svg',
                  width: 20,
                  height: 20,
                  excludeFromSemantics: true,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
