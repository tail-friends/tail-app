import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';

enum _SpeciesCategory { lizard, snake, turtle, other }

Future<String?> showPetSpeciesPicker({
  required BuildContext context,
  String? initialValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x332F6B57),
    builder: (context) => PetSpeciesPickerSheet(initialValue: initialValue),
  );
}

class PetSpeciesPickerSheet extends StatefulWidget {
  const PetSpeciesPickerSheet({this.initialValue, super.key});

  final String? initialValue;

  @override
  State<PetSpeciesPickerSheet> createState() => _PetSpeciesPickerSheetState();
}

class _PetSpeciesPickerSheetState extends State<PetSpeciesPickerSheet> {
  static const _primaryTextColor = Color(0xFF2B2A26);
  static const _secondaryTextColor = Color(0xFF6B675E);
  static const _tertiaryTextColor = Color(0xFF736E65);
  static const _accentColor = Color(0xFF2F6B57);
  static const _fontFamily = 'Jua';
  static const _itemExtent = 39.0;

  // Figma 화면을 재현하기 위한 로컬 예시이며 서버의 공식 종 목록이 아니다.
  static const Map<_SpeciesCategory, List<String>> _exampleSpecies = {
    _SpeciesCategory.lizard: [
      '토케이 게코',
      '크레스티드 게코',
      '펫테일 게코',
      '레오파드 게코',
      '비어디드 드래곤',
      '블루텅 스킨크',
      '가고일 게코',
    ],
    _SpeciesCategory.snake: [],
    _SpeciesCategory.turtle: [],
    _SpeciesCategory.other: [],
  };

  static const _categoryLabels = {
    _SpeciesCategory.lizard: '도마뱀',
    _SpeciesCategory.snake: '뱀',
    _SpeciesCategory.turtle: '거북',
    _SpeciesCategory.other: '기타',
  };

  static const _titleStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: -0.3,
    color: _primaryTextColor,
  );
  static const _bodyStyle = TextStyle(
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
  static const _captionStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    color: _tertiaryTextColor,
  );

  late final TextEditingController _searchController;
  late FixedExtentScrollController _wheelController;
  _SpeciesCategory _category = _SpeciesCategory.lizard;
  String _query = '';
  String? _draftSelection;
  int _selectedIndex = 0;
  bool _acceptWheelChanges = false;

  List<String> get _filteredOptions {
    final query = _query.trim();
    final matches = _exampleSpecies[_category]!
        .where((species) => species.contains(query))
        .toList(growable: true);
    if (query.isNotEmpty && !matches.contains(query)) {
      matches.add(query);
    }
    return matches;
  }

  bool get _isDirectEntry {
    final selection = _draftSelection;
    return selection != null &&
        !_exampleSpecies.values.any((items) => items.contains(selection));
  }

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue?.trim();
    final lizardOptions = _exampleSpecies[_SpeciesCategory.lizard]!;
    if (initialValue != null && initialValue.isNotEmpty) {
      final initialIndex = lizardOptions.indexOf(initialValue);
      if (initialIndex >= 0) {
        _selectedIndex = initialIndex;
        _draftSelection = initialValue;
      } else {
        _query = initialValue;
        _draftSelection = initialValue;
      }
    } else {
      _selectedIndex = lizardOptions.indexOf('레오파드 게코');
    }
    _searchController = TextEditingController(text: _query);
    _wheelController = FixedExtentScrollController(initialItem: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _acceptWheelChanges = true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  void _replaceWheelController() {
    final previousController = _wheelController;
    _acceptWheelChanges = false;
    _wheelController = FixedExtentScrollController(initialItem: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
      if (mounted) _acceptWheelChanges = true;
    });
  }

  void _selectCategory(_SpeciesCategory category) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _category = category;
      _query = '';
      _searchController.clear();
      _selectedIndex = 0;
      _draftSelection = null;
      _replaceWheelController();
    });
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _query = value;
      _selectedIndex = 0;
      final options = _filteredOptions;
      _draftSelection = value.trim().isEmpty || options.isEmpty
          ? null
          : options.first;
      _replaceWheelController();
    });
  }

  void _selectWheelOption(List<String> options, int index) {
    setState(() {
      _selectedIndex = index;
      _draftSelection = options[index];
    });
    _wheelController.animateToItem(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _confirmSelection() {
    final selection = _draftSelection?.trim();
    if (selection == null || selection.isEmpty) return;
    Navigator.pop(context, selection);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final availableHeight = math.max(
      320.0,
      mediaQuery.size.height - keyboardInset - mediaQuery.padding.top - 12,
    );
    final sheetHeight = math.min(583.0, availableHeight);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          key: const ValueKey('pet_species_picker_sheet'),
          height: sheetHeight,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xE6FFFFFF)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D1F1C1A),
                  offset: Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGrabber(),
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSearchField(),
                      const SizedBox(height: 10),
                      _buildCategories(),
                      const SizedBox(height: 10),
                      _buildPicker(),
                      const SizedBox(height: 10),
                      _buildConfirmButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        key: const ValueKey('pet_species_picker_grabber'),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderDefault,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('종 선택', style: _titleStyle),
              Text('목록에 없으면 직접 입력할 수 있어요', style: _captionStyle),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: '종 선택 닫기',
          child: SizedBox.square(
            key: const ValueKey('pet_species_picker_close'),
            dimension: 44,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: AppGlassSurface(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/species_picker_close.svg',
                          width: 16,
                          height: 16,
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
    );
  }

  Widget _buildSearchField() {
    return Semantics(
      textField: true,
      label: '종 이름 검색 또는 직접 입력',
      hint: '목록에 없는 종 이름도 입력할 수 있습니다',
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(AppRadius.full),
        gradient: AppColors.glassSoftGradient,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 16),
              SvgPicture.asset(
                'assets/icons/species_picker_search.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('pet_species_search_field'),
                  controller: _searchController,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  textInputAction: TextInputAction.done,
                  style: _captionStyle.copyWith(color: _primaryTextColor),
                  decoration: const InputDecoration(
                    hintText: '종 이름 검색',
                    hintStyle: _captionStyle,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _handleSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _SpeciesCategory.values.map((category) {
          final isSelected = category == _category;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '${_categoryLabels[category]} 카테고리',
              child: SizedBox(
                key: ValueKey('pet_species_category_${category.name}'),
                height: 44,
                child: Center(
                  child: Material(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    elevation: isSelected ? 3 : 0,
                    shadowColor: const Color(0x1A3D2E1F),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: () => _selectCategory(category),
                      child: AppGlassSurface(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Colors.white, Colors.white],
                              )
                            : AppColors.glassSoftGradient,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          child: Text(
                            _categoryLabels[category]!,
                            style: _labelStyle.copyWith(
                              color: isSelected
                                  ? _primaryTextColor
                                  : _secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPicker() {
    final options = _filteredOptions;
    if (options.isEmpty) {
      return SizedBox(
        key: const ValueKey('pet_species_picker_empty'),
        height: 275,
        child: Center(
          child: Text(
            '공식 종 목록은 준비 중이에요\n위 검색창에 종 이름을 직접 입력해 주세요',
            textAlign: TextAlign.center,
            style: _captionStyle,
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        key: ValueKey('pet_species_picker_wheel_${options.join('_')}'),
        width: 220,
        height: 275,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Container(
                key: const ValueKey('pet_species_selected_pill'),
                width: 220,
                height: 41,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: const Color(0xE6E6E1D6)),
                  boxShadow: const [
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
                  ],
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              key: const ValueKey('pet_species_picker_wheel'),
              controller: _wheelController,
              itemExtent: _itemExtent,
              diameterRatio: 100,
              perspective: 0.001,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                if (!_acceptWheelChanges) return;
                setState(() {
                  _selectedIndex = index;
                  _draftSelection = options[index];
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: options.length,
                builder: (context, index) {
                  return AnimatedBuilder(
                    animation: _wheelController,
                    builder: (context, child) {
                      final distance = (index - _selectedIndex).abs();
                      final opacity = switch (distance) {
                        0 => 1.0,
                        1 => 0.6,
                        2 => 0.35,
                        _ => 0.2,
                      };
                      return Opacity(opacity: opacity, child: child);
                    },
                    child: Semantics(
                      button: true,
                      selected: options[index] == _draftSelection,
                      label: options[index],
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectWheelOption(options, index),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    options[index],
                                    key: ValueKey(
                                      'pet_species_option_${options[index]}',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    style: _bodyStyle.copyWith(
                                      color: index == _selectedIndex
                                          ? _primaryTextColor
                                          : _secondaryTextColor,
                                    ),
                                  ),
                                ),
                                if (_isDirectEntry &&
                                    options[index] == _draftSelection) ...[
                                  const SizedBox(width: 6),
                                  Text('직접 입력', style: _captionStyle),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final enabled = _draftSelection?.trim().isNotEmpty ?? false;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '선택한 종 적용',
      child: SizedBox(
        key: const ValueKey('pet_species_confirm_button'),
        height: 48,
        child: Material(
          color: enabled ? _accentColor : _accentColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.full),
          elevation: enabled ? 8 : 0,
          shadowColor: const Color(0x2E14120F),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: enabled ? _confirmSelection : null,
            child: const Center(
              child: Text(
                '선택',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 14,
                  height: 20 / 14,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
