part of 'home_screen.dart';

/// Presentation only: no account, pet, reminder or character creation state.
class _FirstVisitContent extends StatelessWidget {
  const _FirstVisitContent({
    required this.dateLabel,
    required this.greeting,
    required this.registrationHint,
    required this.onNotification,
    required this.onRegister,
  });

  final String dateLabel;
  final String greeting;
  final String registrationHint;
  final VoidCallback onNotification;
  final VoidCallback onRegister;

  static const _features = [
    (
      title: '기록하면 캐릭터가 반응해요',
      detail: '급여·탈피·체중을 남겨 보세요',
      icon: 'assets/icons/home_first_visit_record.svg',
    ),
    (
      title: '돌봄 주기를 알려드려요',
      detail: '급여일과 탈피 예정일 알림',
      icon: 'assets/icons/home_bell.svg',
    ),
    (
      title: '성장을 한눈에',
      detail: '체중 변화를 그래프로 확인',
      icon: 'assets/icons/home_first_visit_weight.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTypography.titleLarge.copyWith(
      fontFamily: HomeScreen._fontFamily,
      color: HomeScreen._primaryTextColor,
    );
    return Column(
      key: const ValueKey('home_first_visit_content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const ValueKey('home_first_visit_header'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel, style: HomeScreen._dateStyle),
                  Semantics(
                    header: true,
                    child: Text(greeting, style: titleStyle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            _RoundIconButton(
              key: const ValueKey('home_notification_button'),
              semanticLabel: '알림',
              asset: 'assets/icons/home_bell.svg',
              iconSize: 16,
              alignment: Alignment.topRight,
              onTap: onNotification,
            ),
          ],
        ),
        // The header keeps a 44px hit target; its 36px visible content and this
        // gap place the card at y=130 in the 390×844 Figma reference.
        const SizedBox(height: AppSpacing.x8),
        AppCard(
          key: const ValueKey('home_first_visit_card'),
          // Includes Figma's 1px border; AppGlassSurface does not inset it.
          padding: const EdgeInsets.fromLTRB(25, 37, 25, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              const Center(
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    key: ValueKey('home_first_visit_character_slot'),
                    dimension: 88,
                    child: CustomPaint(painter: _EmptySlotBorder()),
                  ),
                ),
              ),
              Column(
                spacing: AppSpacing.x1,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      '아직 함께하는 친구가 없어요',
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                  ),
                  Text(
                    registrationHint,
                    textAlign: TextAlign.center,
                    style: HomeScreen._captionStyle,
                  ),
                ],
              ),
              SizedBox(
                // Respect natural wrapping at large accessibility text sizes.
                height: MediaQuery.textScalerOf(context).scale(1) <= 1
                    ? 48
                    : null,
                child: AppButton(
                  key: const ValueKey('home_first_visit_register_button'),
                  label: '첫 친구 등록하기',
                  backgroundColor: HomeScreen._forestColor,
                  textStyle: AppTypography.titleMedium.copyWith(
                    fontFamily: HomeScreen._fontFamily,
                  ),
                  onPressed: onRegister,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppGlassSurface(
          key: const ValueKey('home_first_visit_features'),
          borderRadius: BorderRadius.circular(22),
          gradient: AppColors.glassSoftGradient,
          boxShadow: const [
            BoxShadow(
              color: Color(0x143D3329),
              offset: Offset(0, 12),
              blurRadius: 32,
            ),
          ],
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
          child: Column(
            children: [
              for (final (index, feature) in _features.indexed) ...[
                if (index > 0)
                  const Divider(height: 1, color: Color(0xFFE6E1D6)),
                Padding(
                  key: ValueKey('home_first_visit_feature_$index'),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: AppGlassSurface(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox.square(
                            dimension: 34,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 16,
                                child: SvgPicture.asset(feature.icon),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(feature.title, style: HomeScreen._bodyStyle),
                            Text(feature.detail, style: HomeScreen._dateStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The Figma slot is an empty layout with a dashed border, not a lizard image.
class _EmptySlotBorder extends CustomPainter {
  const _EmptySlotBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6E1D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Center the 1px stroke inside the slot.
    final circle = Path()
      ..addOval(Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1));
    for (final metric in circle.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 8) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 4, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EmptySlotBorder oldDelegate) => false;
}
