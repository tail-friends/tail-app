import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

/// Only presents UI; never returns an image, a saved pet or a success result.
Future<void> showPetPhotoAddSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x332F6B57),
      barrierLabel: '사진 추가 미리보기 닫기',
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (_) => const PetPhotoAddSheet(),
    );

class PetPhotoAddSheet extends StatelessWidget {
  const PetPhotoAddSheet({super.key});

  static const _ink = Color(0xFF2B2A26);
  static const _secondary = Color(0xFF6B675E);
  static const _muted = Color(0xFF736E65);
  static final _title = AppTypography.titleLarge.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _body = AppTypography.bodyRegular.copyWith(
    fontFamily: 'Jua',
    color: _ink,
  );
  static final _caption = AppTypography.captionRegular.copyWith(
    fontFamily: 'Jua',
    color: _muted,
  );
  static const _tips = ['위에서 내려다본 전신이 보이게', '밝은 곳에서 그림자 없이', '배경은 단순할수록 좋아요'];

  Future<void> _showUnavailable(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('사진 추가 미리보기'),
      content: const Text('사진 선택 기능은 준비 중입니다. 실제 사진은 선택하거나 저장하지 않습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(
          0.0,
          constraints.maxHeight - media.viewInsets.bottom,
        );
        // Figma 22:1085: y=394, h=450 on 390×844. A constrained viewport
        // scrolls the content rather than clipping cards or enlarged text.
        final height = math.min(media.size.height * 450 / 844, available);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: Semantics(
              label: '사진 추가 UI 미리보기',
              onDismiss: () => Navigator.of(context).pop(),
              child: AppGlassSurface(
                key: const ValueKey('pet_photo_add_sheet'),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                blur: 12,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
                borderColor: AppColors.borderGlass,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D1F1C1A),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 11),
                      Center(
                        child: Container(
                          key: const ValueKey('pet_photo_grabber'),
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E1D6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: _header(context),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('pet_photo_scroll'),
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _options(context),
                              const SizedBox(height: 20),
                              _photoTips(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          25,
                          20,
                          25,
                          media.viewInsets.bottom > 0
                              ? 12
                              : math.max(35.0, media.padding.bottom),
                        ),
                        child: AppButton(
                          key: const ValueKey('pet_photo_cancel'),
                          label: '취소',
                          variant: AppButtonVariant.ghost,
                          minHeight: 48,
                          foregroundColor: _ink,
                          textStyle: AppTypography.titleMedium.copyWith(
                            fontFamily: 'Jua',
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) => Row(
    key: const ValueKey('pet_photo_header'),
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('사진 추가', style: _title)),
            Text('캐릭터는 이 사진을 바탕으로 만들어져요', style: _caption),
          ],
        ),
      ),
      Semantics(
        label: '사진 추가 닫기',
        button: true,
        excludeSemantics: true,
        onTap: () => Navigator.of(context).pop(),
        child: InkWell(
          key: const ValueKey('pet_photo_close'),
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox.square(
            dimension: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: AppGlassSurface(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: _icon('assets/icons/species_picker_close.svg', 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _options(BuildContext context) => Padding(
    key: const ValueKey('pet_photo_options'),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        Expanded(child: _option(context, camera: true)),
        Expanded(child: _option(context, camera: false)),
      ],
    ),
  );

  Widget _option(BuildContext context, {required bool camera}) {
    final label = camera ? '카메라로 촬영' : '앨범에서 선택';
    return Semantics(
      label: label,
      hint: '사진 선택 기능 준비 중',
      button: true,
      excludeSemantics: true,
      onTap: () => _showUnavailable(context),
      child: InkWell(
        key: ValueKey(camera ? 'pet_photo_camera' : 'pet_photo_album'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showUnavailable(context),
        child: AppGlassSurface(
          borderRadius: BorderRadius.circular(22),
          gradient: camera
              ? const LinearGradient(colors: [Colors.white, Colors.white])
              : AppColors.glassSoftGradient,
          borderColor: camera ? const Color(0xE6E6E1D6) : Colors.white,
          boxShadow: camera
              ? const [
                  BoxShadow(
                    color: Color(0x0F3D2E1F),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Color(0x1F3D2E1F),
                    offset: Offset(0, 4),
                    blurRadius: 14,
                  ),
                ]
              : const [],
          padding: EdgeInsets.fromLTRB(4, camera ? 15 : 21, 4, camera ? 15 : 9),
          child: Column(
            children: [
              _icon(
                camera
                    ? 'assets/icons/photo_add_camera.svg'
                    : 'assets/icons/photo_add_album.svg',
                22,
              ),
              const SizedBox(height: 10),
              Text(label, style: _body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoTips() => AppGlassSurface(
    key: const ValueKey('pet_photo_tips'),
    borderRadius: BorderRadius.circular(22),
    gradient: AppColors.glassSoftGradient,
    padding: const EdgeInsets.all(17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Semantics(
          header: true,
          child: Text('잘 나오는 사진', style: _caption.copyWith(color: _secondary)),
        ),
        for (final (index, tip) in _tips.indexed)
          Row(
            key: ValueKey('pet_photo_tip_$index'),
            children: [
              SvgPicture.asset(
                'assets/icons/photo_add_check.svg',
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(tip, style: _body)),
            ],
          ),
      ],
    ),
  );

  Widget _icon(String asset, double size) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: FittedBox(child: SvgPicture.asset(asset)),
    ),
  );
}
