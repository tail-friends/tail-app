import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import 'pet_photo_add_sheet.dart';
import 'pet_species_picker_sheet.dart';

enum PetGender { male, female, unspecified }

typedef PetDatePicker =
    Future<DateTime?> Function(BuildContext context, DateTime? currentDate);

class PetRegistrationScreen extends StatefulWidget {
  const PetRegistrationScreen({this.datePicker, super.key})
    : _photoPreview = false;

  /// Independent Debug target uses Figma examples without saving any pet.
  const PetRegistrationScreen.photoAddPreview({super.key})
    : datePicker = null,
      _photoPreview = true;

  final PetDatePicker? datePicker;
  final bool _photoPreview;

  @override
  State<PetRegistrationScreen> createState() => _PetRegistrationScreenState();
}

class _PetRegistrationScreenState extends State<PetRegistrationScreen> {
  static const _backgroundColor = Color(0xFFFAF7F0);
  static const _primaryTextColor = Color(0xFF2B2A26);
  static const _secondaryTextColor = Color(0xFF6B675E);
  static const _tertiaryTextColor = Color(0xFF736E65);
  static const _dangerColor = Color(0xFFB23B30);
  static const _saveColor = Color(0xFF2F6B57);
  static const _fontFamily = 'Jua';

  static const _titleStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: -0.2,
    color: _primaryTextColor,
  );
  static const _fieldStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    height: 19 / 13,
    letterSpacing: -0.1,
    color: _primaryTextColor,
  );
  static const _labelStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 16 / 12,
    color: _secondaryTextColor,
  );
  static const _requiredStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: -0.1,
    color: _dangerColor,
  );
  static const _captionStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    color: _tertiaryTextColor,
  );
  static const _saveStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: -0.2,
  );

  final _nameController = TextEditingController();
  final _morphController = TextEditingController();
  final _feedingCycleController = TextEditingController();
  final _memoController = TextEditingController();

  PetGender _gender = PetGender.unspecified;
  DateTime? _hatchingDate;
  String? _species;
  String? _nameError;
  String? _speciesError;
  String? _feedingCycleError;

  @override
  void initState() {
    super.initState();
    if (kDebugMode && widget._photoPreview) {
      _nameController.text = '욱이';
      _species = '레오파드 게코';
      _morphController.text = '탠저린 · 꼬리 재생';
      _gender = PetGender.male;
      _hatchingDate = DateTime(2024, 7, 12);
      _feedingCycleController.text = '4';
      _memoController.text = '온순함, 손에 잘 올라옴';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPetPhotoAddSheet(context);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _morphController.dispose();
    _feedingCycleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<DateTime?> _showDatePicker(
    BuildContext context,
    DateTime? currentDate,
  ) {
    final today = DateUtils.dateOnly(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: currentDate ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
    );
  }

  Future<void> _pickHatchingDate() async {
    final selected = await (widget.datePicker ?? _showDatePicker)(
      context,
      _hatchingDate,
    );
    if (!mounted || selected == null) return;
    setState(() => _hatchingDate = DateUtils.dateOnly(selected));
  }

  Future<void> _pickSpecies() async {
    final selected = await showPetSpeciesPicker(
      context: context,
      initialValue: _species,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _species = selected;
      _speciesError = null;
    });
  }

  Future<void> _handleSave() async {
    final cycle = int.tryParse(_feedingCycleController.text);
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? '이름을 입력해 주세요.' : null;
      _speciesError = _species == null ? '종을 선택해 주세요.' : null;
      _feedingCycleError = _feedingCycleController.text.isEmpty
          ? '급여 주기를 입력해 주세요.'
          : cycle == null || cycle <= 0
          ? '1 이상의 숫자를 입력해 주세요.'
          : null;
    });
    if (_nameError != null ||
        _speciesError != null ||
        _feedingCycleError != null) {
      _showMessage('저장 기능은 준비 중입니다.');
      return;
    }
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await showPetPhotoAddSheet(context);
  }

  String? get _formattedDate {
    final date = _hatchingDate;
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarDividerColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        key: const ValueKey('pet_registration_screen'),
        backgroundColor: _backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 844,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Image.asset(
                    'assets/images/pet_registration_background.png',
                    key: const ValueKey('pet_registration_background'),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      key: const ValueKey('pet_registration_scroll_view'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x6,
                        AppSpacing.x1,
                        AppSpacing.x6,
                        128,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 342),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildNavigationBar(),
                              const SizedBox(height: 14),
                              AppTextField(
                                key: const ValueKey('pet_name_field'),
                                label: '이름',
                                controller: _nameController,
                                hintText: '이름을 입력해 주세요',
                                errorText: _nameError,
                                isRequired: true,
                                maxLength: 30,
                                showCounter: true,
                                minHeight: 44,
                                textInputAction: TextInputAction.next,
                                textStyle: _fieldStyle,
                                labelStyle: _labelStyle,
                                requiredStyle: _requiredStyle,
                                counterStyle: _captionStyle,
                                onChanged: (_) {
                                  if (_nameError != null) {
                                    setState(() => _nameError = null);
                                  }
                                },
                              ),
                              const SizedBox(height: 14),
                              _LabeledSelectionField(
                                key: const ValueKey('pet_species_field'),
                                label: '종',
                                value: _species,
                                hintText: '종을 선택해 주세요',
                                isRequired: true,
                                errorText: _speciesError,
                                onTap: _pickSpecies,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                key: const ValueKey('pet_morph_field'),
                                label: '모프 / 특징',
                                controller: _morphController,
                                hintText: '모프나 특징을 입력해 주세요',
                                maxLength: 40,
                                showCounter: true,
                                minHeight: 44,
                                textInputAction: TextInputAction.next,
                                textStyle: _fieldStyle,
                                labelStyle: _labelStyle,
                                counterStyle: _captionStyle,
                              ),
                              const SizedBox(height: 16),
                              _GenderSelector(
                                selected: _gender,
                                onSelected: (gender) =>
                                    setState(() => _gender = gender),
                              ),
                              const SizedBox(height: 16),
                              _LabeledSelectionField(
                                key: const ValueKey('pet_hatching_date_field'),
                                label: '해칭일',
                                value: _formattedDate,
                                hintText: '날짜를 선택해 주세요',
                                onTap: _pickHatchingDate,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                key: const ValueKey('pet_feeding_cycle_field'),
                                label: '급여 주기',
                                controller: _feedingCycleController,
                                hintText: '숫자를 입력해 주세요',
                                errorText: _feedingCycleError,
                                isRequired: true,
                                minHeight: 44,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textStyle: _fieldStyle,
                                labelStyle: _labelStyle,
                                requiredStyle: _requiredStyle,
                                suffixText: '일',
                                suffixStyle: _fieldStyle.copyWith(
                                  color: _secondaryTextColor,
                                ),
                                onChanged: (_) {
                                  if (_feedingCycleError != null) {
                                    setState(() => _feedingCycleError = null);
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.x1),
                              const Text(
                                '성체 기준이에요. 해칭 개체나 번식기라면 바꿔 주세요',
                                style: _captionStyle,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                key: const ValueKey('pet_memo_field'),
                                label: '메모',
                                controller: _memoController,
                                hintText: '함께 기억할 내용을 적어 주세요',
                                maxLength: 300,
                                showCounter: true,
                                maxLines: 3,
                                minHeight: 84,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textStyle: _fieldStyle,
                                labelStyle: _labelStyle,
                                counterStyle: _captionStyle,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.x6,
                    right: AppSpacing.x6,
                    bottom: AppSpacing.x1,
                    child: _buildFooter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '저장하면 사진으로 캐릭터를 만들 수 있어요',
          key: ValueKey('pet_registration_footer_message'),
          textAlign: TextAlign.center,
          style: _captionStyle,
        ),
        const SizedBox(height: AppSpacing.x2),
        AppButton(
          key: const ValueKey('pet_registration_save_button'),
          label: '저장',
          backgroundColor: _saveColor,
          textStyle: _saveStyle,
          onPressed: _handleSave,
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return SizedBox(
      key: const ValueKey('pet_registration_navigation_bar'),
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: '뒤로가기',
              child: SizedBox.square(
                key: const ValueKey('pet_registration_back_button'),
                dimension: 44,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    onTap: () => Navigator.maybePop(context),
                    child: Center(
                      child: IgnorePointer(
                        child: AppGlassSurface(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: SizedBox.square(
                            dimension: 36,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/chevron_left.svg',
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
          const Text('새 친구 등록', style: _titleStyle),
        ],
      ),
    );
  }
}

class _LabeledSelectionField extends StatelessWidget {
  const _LabeledSelectionField({
    required this.label,
    required this.value,
    required this.hintText,
    required this.onTap,
    this.isRequired = false,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final String hintText;
  final VoidCallback onTap;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox.shrink(),
            Text(label, style: _PetRegistrationScreenState._labelStyle),
            if (isRequired) ...[
              const SizedBox(width: 3),
              const Text(
                '필수',
                style: _PetRegistrationScreenState._requiredStyle,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: label,
          value: value ?? hintText,
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderColor: errorText == null
                ? Colors.white
                : _PetRegistrationScreenState._dangerColor,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value ?? hintText,
                            style: _PetRegistrationScreenState._fieldStyle
                                .copyWith(
                                  color: value == null
                                      ? _PetRegistrationScreenState
                                            ._tertiaryTextColor
                                      : _PetRegistrationScreenState
                                            ._primaryTextColor,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/icons/pet_registration_chevron_right_a.svg',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.x1),
          Text(
            errorText!,
            style: _PetRegistrationScreenState._captionStyle.copyWith(
              color: _PetRegistrationScreenState._dangerColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.onSelected});

  final PetGender selected;
  final ValueChanged<PetGender> onSelected;

  static const _labels = {
    PetGender.male: '수컷',
    PetGender.female: '암컷',
    PetGender.unspecified: '미구분',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('성별', style: _PetRegistrationScreenState._labelStyle),
        const SizedBox(height: 6),
        AppGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: AppColors.glassSoftGradient,
          padding: const EdgeInsets.all(3),
          child: Row(
            children: PetGender.values
                .map((gender) {
                  final isSelected = gender == selected;
                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      child: Material(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        elevation: isSelected ? 2 : 0,
                        shadowColor: const Color(0x1A3D2E1F),
                        child: InkWell(
                          key: ValueKey('pet_gender_${gender.name}'),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => onSelected(gender),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _labels[gender]!,
                              textAlign: TextAlign.center,
                              style: _PetRegistrationScreenState._labelStyle
                                  .copyWith(
                                    color: isSelected
                                        ? _PetRegistrationScreenState
                                              ._primaryTextColor
                                        : _PetRegistrationScreenState
                                              ._tertiaryTextColor,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
