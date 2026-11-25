import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/design_system.dart';
import 'core/design_system/font_license.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/records/presentation/record_pet_picker_sheet.dart';
import 'main.dart' as app;

const recordPetPickerPreviewNotice =
    '이 화면은 Figma 디자인 미리보기입니다. 친구 이름과 7마리 표시는 예시이며, 실제 개체 데이터 조회나 기록 필터링은 실행되지 않습니다.';

/// flutter run --target lib/record_pet_picker_preview.dart
void main() {
  if (!kDebugMode) {
    app.main();
    return;
  }
  registerDesignSystemLicenses();
  runApp(
    MaterialApp(
      title: 'Tail Friends 친구 선택 디자인 미리보기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mist,
      home: const RecordPetPickerPreviewHost(),
    ),
  );
}

/// Deliberately independent of the 08 / 08-1 screens under design revision.
class RecordPetPickerPreviewHost extends StatefulWidget {
  const RecordPetPickerPreviewHost({super.key});
  @override
  State<RecordPetPickerPreviewHost> createState() => _PreviewState();
}

class _PreviewState extends State<RecordPetPickerPreviewHost> {
  RecordPetPickerChoice _selection = RecordPetPickerChoice.ukki;
  bool _opening = false;
  bool _previewed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && kDebugMode) _open();
    });
  }

  Future<void> _open() async {
    if (_opening || !kDebugMode || !mounted) return;
    _opening = true;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('디자인 미리보기'),
          scrollable: true,
          content: const Text(recordPetPickerPreviewNotice),
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
      if (accepted != true || !mounted) return;
      setState(() => _previewed = true);
      final result = await showRecordPetPickerPreviewSheet(
        context,
        initialSelection: _selection,
      );
      if (result != null && mounted) setState(() => _selection = result);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const LoginScreen();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('친구 선택 UI 미리보기'),
              const SizedBox(height: 16),
              const Text('08 기록 전체·08-1 기록 수정 화면과 연결되지 않은 독립 미리보기입니다.'),
              const SizedBox(height: 16),
              Text(
                _previewed
                    ? '디자인 미리보기 선택: ${_selection.label}'
                    : '디자인 미리보기 선택 전',
                key: const ValueKey('record_pet_picker_preview_result'),
              ),
              const SizedBox(height: 24),
              AppButton(label: '친구 선택 미리보기', onPressed: _open),
            ],
          ),
        ),
      ),
    );
  }
}
