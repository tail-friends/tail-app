import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/widgets/app_glass_surface.dart';
import '../../pets/presentation/pet_registration_screen.dart';

part 'home_first_visit_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({this.now, super.key})
    : _data = null,
      _firstVisitPreview = false;

  const HomeScreen.preview({super.key})
    : now = null,
      _data = _previewData,
      _firstVisitPreview = false;

  /// Figma sample name/date are used only in Debug, never as account data.
  const HomeScreen.firstVisitPreview({super.key})
    : now = null,
      _data = null,
      _firstVisitPreview = true;

  final DateTime? now;
  final _HomeDisplayData? _data;
  final bool _firstVisitPreview;

  static const _backgroundColor = Color(0xFFFAF7F0);
  static const _forestColor = Color(0xFF2F6B57);
  static const _primaryTextColor = Color(0xFF2B2A26);
  static const _secondaryTextColor = Color(0xFF6B675E);
  static const _tertiaryTextColor = Color(0xFF736E65);
  static const _fontFamily = 'Jua';

  static const _dateStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    color: _tertiaryTextColor,
  );
  static const _greetingStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    height: 26 / 20,
    color: _forestColor,
  );
  static const _heroTitleStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 19,
    height: 26 / 19,
    letterSpacing: -0.4,
    color: _primaryTextColor,
  );
  static const _bodyStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    height: 19 / 13,
    letterSpacing: -0.1,
    color: _primaryTextColor,
  );
  static const _captionStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    color: _secondaryTextColor,
  );
  static const _sectionTitleStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: -0.2,
    color: _primaryTextColor,
  );
  static const _metricNumberStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    height: 1.1,
    color: _primaryTextColor,
  );

  static const _previewData = _HomeDisplayData(
    avatarLabel: '욱',
    dateLabel: '10월 20일 화요일',
    petName: '욱이',
    speciesAndAge: '레오파드 게코 · 2살 3개월',
    status: '배고픔',
    speech: '배고파요',
    feedingTitle: '오늘 급여할 차례예요',
    feedingDetail: '귀뚜라미 5마리 · 칼슘 더스팅',
    weightValue: '52',
    weightTrend: '지난주보다 +2g',
    shedDays: '12',
    shedEstimate: '약 9일 뒤 탈피',
    records: [
      _HomeRecordData(
        title: '급여',
        meta: '귀뚜라미 5마리 · 잘 받아먹음',
        trailing: '10.17',
        iconAsset: 'assets/icons/record_feed.svg',
      ),
      _HomeRecordData(
        title: '체중',
        meta: '52g · +1g',
        trailing: '10.13',
        iconAsset: 'assets/icons/record_weight.svg',
      ),
    ],
  );

  bool get _hasData => _data != null;

  void _showComingSoon(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('기능은 준비 중입니다.')));
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final heroHeight = (214 + math.max(0, textScale - 1) * 54).toDouble();
    final metricHeight = (140 + math.max(0, textScale - 1) * 200).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        key: const ValueKey('home_screen'),
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
                    _hasData
                        ? 'assets/images/home_background.png'
                        : 'assets/images/home_first_visit_background.png',
                    key: const ValueKey('home_background'),
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
                      key: const ValueKey('home_scroll_view'),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.x6,
                        _hasData
                            ? 4
                            : math.max(
                                0,
                                54 - MediaQuery.paddingOf(context).top,
                              ),
                        AppSpacing.x6,
                        104,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 342),
                          child: !_hasData
                              ? _FirstVisitContent(
                                  dateLabel: kDebugMode && _firstVisitPreview
                                      ? '10월 20일 화요일'
                                      : _formatDate(now ?? DateTime.now()),
                                  greeting: kDebugMode && _firstVisitPreview
                                      ? '반가워요, 민준님'
                                      : '반가워요, 어서 오세요',
                                  onNotification: () =>
                                      _showComingSoon(context),
                                  onRegister: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const PetRegistrationScreen(),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(context),
                                    const SizedBox(height: 25),
                                    _buildHero(heroHeight),
                                    const SizedBox(height: 33),
                                    _buildFeedingCallToAction(context),
                                    const SizedBox(height: 40),
                                    _buildMetrics(context, metricHeight),
                                    const SizedBox(height: 12),
                                    _buildRecentHeader(context),
                                    _buildRecentRecords(context),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.x6,
                    right: AppSpacing.x6,
                    bottom: _hasData ? 4 : 0,
                    child: AppBottomNavigation(
                      key: const ValueKey('home_bottom_navigation'),
                      currentTab: AppTab.habitat,
                      selectedLabelColor: _hasData
                          ? AppColors.textComponentPrimary
                          : _primaryTextColor,
                      unselectedLabelColor: _hasData
                          ? AppColors.textTertiary
                          : _secondaryTextColor,
                      selectedBackgroundColor: _hasData
                          ? AppColors.surface
                          : Colors.white,
                      iconAssets: _hasData
                          ? const {}
                          : const {
                              AppTab.habitat:
                                  'assets/icons/home_first_visit_nav_home.svg',
                              AppTab.records:
                                  'assets/icons/home_first_visit_nav_record.svg',
                              AppTab.pets:
                                  'assets/icons/home_first_visit_nav_pets.svg',
                              AppTab.profile:
                                  'assets/icons/home_first_visit_nav_profile.svg',
                            },
                      labelStyle: _dateStyle.copyWith(
                        fontSize: 10,
                        height: 13 / 10,
                      ),
                      onTabSelected: (tab) {
                        if (tab != AppTab.habitat) _showComingSoon(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final date = _data?.dateLabel ?? _formatDate(now ?? DateTime.now());
    final title = _hasData ? '${_data!.petName}의 하루' : '오늘의 사육장';
    return Row(
      key: const ValueKey('home_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            key: const ValueKey('home_avatar'),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _forestColor,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              _data?.avatarLabel ?? '—',
              style: _dateStyle.copyWith(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(date, style: _dateStyle),
                Text(title, style: _greetingStyle),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _RoundIconButton(
          key: const ValueKey('home_notification_button'),
          semanticLabel: '알림',
          asset: 'assets/icons/home_bell.svg',
          iconSize: 16,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildHero(double height) {
    return SizedBox(
      key: const ValueKey('home_hero_card'),
      height: height,
      child: AppCard(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _data?.petName ?? '등록된 친구가 없어요',
                        style: _heroTitleStyle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _data?.speciesAndAge ?? '친구를 등록하면 여기에 표시돼요',
                        style: _captionStyle,
                      ),
                    ],
                  ),
                ),
                if (_data?.speech case final message?) ...[
                  const SizedBox(width: AppSpacing.x2),
                  Flexible(
                    child: AppSpeechBubble(
                      message: message,
                      textStyle: _dateStyle.copyWith(
                        fontSize: 12,
                        height: 16 / 12,
                        color: _primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Expanded(
              child: Center(
                child: SizedBox(
                  key: ValueKey('home_character_slot'),
                  width: 92,
                  height: 80,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: _data?.status ?? '기록 없음',
                active: _hasData,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedingCallToAction(BuildContext context) {
    return Semantics(
      button: true,
      label: _data?.feedingTitle ?? '급여 기록이 없어요',
      child: Material(
        key: const ValueKey('home_feeding_cta'),
        color: _forestColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showComingSoon(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 59),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _data?.feedingTitle ?? '급여 기록이 없어요',
                          style: _bodyStyle.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _data?.feedingDetail ?? '친구를 등록하면 일정을 확인할 수 있어요',
                          style: _captionStyle.copyWith(
                            color: const Color(0xFFD7E6DC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: SizedBox.square(
                      dimension: 16,
                      child: FittedBox(
                        child: SvgPicture.asset(
                          'assets/icons/home_chevron_right.svg',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, double height) {
    return Row(
      key: const ValueKey('home_metrics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MetricCard(
            key: const ValueKey('home_weight_card'),
            height: height,
            type: _MetricType.weight,
            value: _data?.weightValue,
            helper: _data?.weightTrend,
            onTap: () => _showComingSoon(context),
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(
          child: _MetricCard(
            key: const ValueKey('home_shed_card'),
            height: height,
            type: _MetricType.shed,
            value: _data?.shedDays,
            helper: _data?.shedEstimate,
            onTap: () => _showComingSoon(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHeader(BuildContext context) {
    return Row(
      key: const ValueKey('home_recent_header'),
      children: [
        const Expanded(child: Text('최근 기록', style: _sectionTitleStyle)),
        Semantics(
          button: true,
          label: '전체 기록 보기',
          child: InkWell(
            key: const ValueKey('home_all_records_button'),
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: () => _showComingSoon(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Text('전체', style: _dateStyle),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecords(BuildContext context) {
    final records = _data?.records ?? const <_HomeRecordData>[];
    return AppCard(
      key: const ValueKey('home_recent_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: records.isEmpty
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 116),
              child: const Center(
                child: Text('아직 기록이 없어요', style: _captionStyle),
              ),
            )
          : Column(
              children: [
                for (final (index, record) in records.indexed) ...[
                  if (index > 0) const Divider(),
                  AppRecordRow(
                    title: record.title,
                    meta: record.meta,
                    trailing: record.trailing,
                    titleStyle: _bodyStyle,
                    metaStyle: _captionStyle,
                    trailingStyle: _dateStyle.copyWith(
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                    icon: ExcludeSemantics(
                      child: SvgPicture.asset(record.iconAsset),
                    ),
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.semanticLabel,
    required this.asset,
    required this.iconSize,
    required this.onTap,
    this.alignment = Alignment.center,
    super.key,
  });

  final String semanticLabel;
  final String asset;
  final double iconSize;
  final VoidCallback onTap;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: onTap,
            child: Align(
              alignment: alignment,
              child: IgnorePointer(
                child: AppGlassSurface(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Center(
                      child: SizedBox.square(
                        dimension: iconSize,
                        child: FittedBox(child: SvgPicture.asset(asset)),
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
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.full),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active)
            SvgPicture.asset('assets/icons/home_status_dot.svg')
          else
            const SizedBox.square(
              dimension: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.iconMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(label, style: HomeScreen._bodyStyle),
        ],
      ),
    );
  }
}

enum _MetricType { weight, shed }

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.height,
    required this.type,
    required this.value,
    required this.helper,
    required this.onTap,
    super.key,
  });

  final double height;
  final _MetricType type;
  final String? value;
  final String? helper;
  final VoidCallback onTap;

  bool get _hasValue => value != null;
  String get _title => type == _MetricType.weight ? '체중' : '탈피';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AppCard(
        padding: const EdgeInsets.all(15),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: HomeScreen._bodyStyle.copyWith(
                      color: HomeScreen._secondaryTextColor,
                    ),
                  ),
                ),
                SvgPicture.asset('assets/icons/home_metric_chevron_right.svg'),
              ],
            ),
            const SizedBox(height: 4),
            if (!_hasValue)
              const Expanded(
                child: Center(
                  child: Text('기록 없음', style: HomeScreen._captionStyle),
                ),
              )
            else ...[
              Wrap(
                spacing: 3,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(value!, style: HomeScreen._metricNumberStyle),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      type == _MetricType.weight ? 'g' : '일 전',
                      style: HomeScreen._captionStyle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (type == _MetricType.weight)
                SizedBox(
                  height: 27,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SvgPicture.asset(
                      'assets/icons/home_weight_sparkline.svg',
                    ),
                  ),
                )
              else
                const _ShedCycle(),
              const SizedBox(height: 3),
              if (type == _MetricType.shed)
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EstimateChip(),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          helper!,
                          style: HomeScreen._captionStyle.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  helper!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HomeScreen._captionStyle.copyWith(fontSize: 10),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShedCycle extends StatelessWidget {
  const _ShedCycle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          for (var index = 0; index < 7; index++) ...[
            if (index > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: index < 4
                      ? HomeScreen._primaryTextColor
                      : AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstimateChip extends StatelessWidget {
  const _EstimateChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E2C2),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '예상',
          style: HomeScreen._dateStyle.copyWith(
            fontSize: 10,
            color: HomeScreen._forestColor,
          ),
        ),
      ),
    );
  }
}

class _HomeDisplayData {
  const _HomeDisplayData({
    required this.avatarLabel,
    required this.dateLabel,
    required this.petName,
    required this.speciesAndAge,
    required this.status,
    required this.speech,
    required this.feedingTitle,
    required this.feedingDetail,
    required this.weightValue,
    required this.weightTrend,
    required this.shedDays,
    required this.shedEstimate,
    required this.records,
  });

  final String avatarLabel;
  final String dateLabel;
  final String petName;
  final String speciesAndAge;
  final String status;
  final String speech;
  final String feedingTitle;
  final String feedingDetail;
  final String weightValue;
  final String weightTrend;
  final String shedDays;
  final String shedEstimate;
  final List<_HomeRecordData> records;
}

class _HomeRecordData {
  const _HomeRecordData({
    required this.title,
    required this.meta,
    required this.trailing,
    required this.iconAsset,
  });

  final String title;
  final String meta;
  final String trailing;
  final String iconAsset;
}
