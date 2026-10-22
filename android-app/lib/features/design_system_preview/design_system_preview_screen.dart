import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

class DesignSystemPreviewScreen extends StatefulWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  State<DesignSystemPreviewScreen> createState() =>
      _DesignSystemPreviewScreenState();
}

class _DesignSystemPreviewScreenState extends State<DesignSystemPreviewScreen> {
  AppTab _currentTab = AppTab.habitat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디자인 시스템 미리보기'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.mistScreenGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x6,
            AppSpacing.x4,
            AppSpacing.x6,
            AppSpacing.x10,
          ),
          children: [
            const _PreviewSection(
              title: 'Color',
              child: Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  _ColorSwatch('Canvas', AppColors.canvas),
                  _ColorSwatch('Surface', AppColors.surface),
                  _ColorSwatch('Sunken', AppColors.sunken),
                  _ColorSwatch('Primary', AppColors.primaryBackground),
                  _ColorSwatch('Accent', AppColors.textAccent),
                  _ColorSwatch('Success', AppColors.textSuccess),
                  _ColorSwatch('Warning', AppColors.textWarning),
                  _ColorSwatch('Danger', AppColors.textDanger),
                ],
              ),
            ),
            const _PreviewSection(
              title: 'Typography',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Large', style: AppTypography.displayLarge),
                  Text('Display Medium', style: AppTypography.displayMedium),
                  Text('Title Large', style: AppTypography.titleLarge),
                  Text('Title Medium', style: AppTypography.titleMedium),
                  Text('Body Regular', style: AppTypography.bodyRegular),
                  Text('Label Medium', style: AppTypography.labelMedium),
                  Text('Caption Regular', style: AppTypography.captionRegular),
                  Text('52.4', style: AppTypography.numberLarge),
                ],
              ),
            ),
            _PreviewSection(
              title: 'Button',
              child: Column(
                children: [
                  AppButton(label: 'Primary', onPressed: () {}),
                  const SizedBox(height: AppSpacing.x3),
                  AppButton(
                    label: 'Secondary',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  AppButton(
                    label: 'Ghost',
                    variant: AppButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  const AppButton(
                    label: '처리 중',
                    onPressed: null,
                    isLoading: true,
                  ),
                ],
              ),
            ),
            _PreviewSection(
              title: 'Social Button',
              child: Column(
                children: AppSocialProvider.values
                    .map(
                      (provider) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                        child: SizedBox(
                          width: double.infinity,
                          child: AppSocialButton(
                            provider: provider,
                            onPressed: () {},
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const _PreviewSection(
              title: 'Text Field',
              child: Column(
                children: [
                  AppTextField(
                    label: '이름',
                    hintText: '예: 욱이',
                    isRequired: true,
                    maxLength: 30,
                    showCounter: true,
                  ),
                  SizedBox(height: AppSpacing.x4),
                  AppTextField(
                    label: '메모',
                    hintText: '특징을 입력해 주세요',
                    errorText: '메모를 확인해 주세요',
                    maxLines: 3,
                    maxLength: 300,
                    showCounter: true,
                  ),
                ],
              ),
            ),
            const _PreviewSection(
              title: 'Chip',
              child: Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  AppChip(label: '안정', tone: AppChipTone.success),
                  AppChip(label: '주의', tone: AppChipTone.warning),
                  AppChip(label: '경고', tone: AppChipTone.danger),
                  AppChip(label: '예상', tone: AppChipTone.accent),
                  AppChip(label: '기본'),
                ],
              ),
            ),
            const _PreviewSection(
              title: 'Card · Speech Bubble · Record Row',
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('욱이', style: AppTypography.displayMedium),
                    SizedBox(height: AppSpacing.x1),
                    Text(
                      '레오파드 게코 · 2살 3개월',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: AppSpacing.x4),
                    AppSpeechBubble(message: '배고파요! 밥 주세요'),
                    SizedBox(height: AppSpacing.x3),
                    Divider(),
                    AppRecordRow(title: '급여', meta: '귀뚜라미 5마리', trailing: '오늘'),
                  ],
                ),
              ),
            ),
            _PreviewSection(
              title: 'Bottom Navigation',
              child: Center(
                child: AppBottomNavigation(
                  currentTab: _currentTab,
                  onTabSelected: (tab) => setState(() => _currentTab = tab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.x3),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: const SizedBox.square(dimension: 56),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionRegular,
          ),
        ],
      ),
    );
  }
}
