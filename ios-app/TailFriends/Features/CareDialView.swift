import SwiftUI

enum CareDialDestination {
    case week
    case calendar
    case feeding

    var noticeMessage: String {
        switch self {
        case .week:
            "07-1 케어 · 주간 화면은 준비 중이에요."
        case .calendar:
            "07-2 캘린더 화면은 준비 중이에요."
        case .feeding:
            "07-3 급여 기록 · 다이얼 화면은 준비 중이에요."
        }
    }
}

struct CareDialView: View {
    let onDestinationTap: (CareDialDestination) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CareDialPalette.canvas
                    .ignoresSafeArea()

                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    topControls
                        .frame(height: 36)
                        .padding(.bottom, 26)

                    Text("오늘 육이를\n돌봐줄 시간이에요")
                        .font(.custom("Jua", size: 20, relativeTo: .title2))
                        .foregroundStyle(CareDialPalette.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 48, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 8)
                        .accessibilityIdentifier("careDial.headline")

                    careIndicators
                        .frame(height: 18)
                        .padding(.bottom, 29)

                    CareDialGraphic()
                        .frame(width: 330, height: 330)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 0)

                    Spacer(minLength: 45)

                    summaryCards
                        .frame(height: 52)
                        .padding(.bottom, 18)

                    feedingButton
                        .frame(height: 50)

                    Spacer(minLength: 90)
                }
                .frame(maxWidth: 342)
                .padding(.horizontal, 24)
                .padding(.top, 11)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.light)
    }

    private var topControls: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                periodButton(title: "오늘", selected: true, width: 44, action: {})
                periodButton(title: "주간", selected: false, width: 44) {
                    onDestinationTap(.week)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("careDial.periodSwitch")

            Spacer(minLength: 0)

            Button {
                onDestinationTap(.calendar)
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CareDialPalette.primary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.86), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("캘린더")
            .accessibilityIdentifier("careDial.calendar")
        }
        .frame(maxWidth: .infinity)
    }

    private func periodButton(
        title: String,
        selected: Bool,
        width: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                if selected {
                    Capsule()
                        .fill(.white.opacity(0.88))
                }

                Text(title)
                    .font(.custom("Jua", size: 12, relativeTo: .caption))
                    .foregroundStyle(selected ? CareDialPalette.forest : CareDialPalette.secondary)
            }
                .frame(width: width, height: selected ? 30 : 36)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: width, height: 36)
        .accessibilityLabel(title)
        .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("careDial.period.\(title)")
    }

    private var careIndicators: some View {
        HStack(spacing: 18) {
            indicator(title: "급여", color: CareDialPalette.primary)
            indicator(title: "탈피", color: CareDialPalette.forest)
            indicator(title: "체중", color: CareDialPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("careDial.indicators")
    }

    private func indicator(title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)

            Text(title)
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(CareDialPalette.secondary)
        }
        .accessibilityLabel(title)
    }

    private var summaryCards: some View {
        HStack(spacing: 8) {
            summaryCard(title: "마지막 급여", value: "3일 18시간 전", identifier: "lastFeeding")
            summaryCard(title: "먹이", value: "귀뚜라미 5", identifier: "food")
            summaryCard(title: "주기", value: "96시간", identifier: "period")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("careDial.summaryCards")
    }

    private func summaryCard(title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .center, spacing: 3) {
            Text(title)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(CareDialPalette.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(CareDialPalette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 9)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.76), .white.opacity(0.38)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: CareDialPalette.shadow, radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("careDial.summary.\(identifier)")
    }

    private var feedingButton: some View {
        Button {
            onDestinationTap(.feeding)
        } label: {
            Text("급여 기록하기")
                .font(.custom("Jua", size: 15, relativeTo: .body))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CareDialPalette.forest, in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("급여 기록하기")
        .accessibilityIdentifier("careDial.feedingButton")
    }
}

private struct CareDialGraphic: View {
    private let progress = 90.0 / 96.0
    private let diameter: CGFloat = 232
    private let centerDiameter: CGFloat = 176
    private let tickRadius: CGFloat = 132

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: side / 2, y: side / 2)

            ZStack {
                CareDialGlassLayer()
                CareDialTickMarks(radius: tickRadius)
                CareDialTrack(diameter: diameter)
                CareDialProgressArc(diameter: diameter, progress: progress)
                CareDialCore(diameter: centerDiameter)
                CareDialProgressKnob(
                    center: center,
                    radius: diameter / 2,
                    angle: Angle(degrees: -90 + progress * 360)
                )
                CareDialCountdown()
                CareDialLabels(side: side)
            }
            .frame(width: side, height: side)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("다음 급여까지 6시간, 3일 18시간 경과, 주기 96시간")
        .accessibilityIdentifier("careDial.gauge")
    }
}

private struct CareDialGlassLayer: View {
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay {
                Circle().fill(.white.opacity(0.28))
            }
            .frame(width: 300, height: 300)
            .shadow(color: CareDialPalette.shadow, radius: 18, x: 0, y: 7)
            .accessibilityHidden(true)
    }
}

private struct CareDialTickMarks: View {
    let radius: CGFloat

    var body: some View {
        ForEach(0..<48, id: \.self) { tick in
            let isCardinal = tick.isMultiple(of: 12)

            Capsule()
                .fill(CareDialPalette.muted.opacity(0.7))
                .frame(width: 1.25, height: isCardinal ? 12 : 7)
                .offset(y: -radius)
                .rotationEffect(.degrees(Double(tick) * 7.5))
                .accessibilityHidden(true)
        }
    }
}

private struct CareDialTrack: View {
    let diameter: CGFloat

    var body: some View {
        Circle()
            .stroke(CareDialPalette.muted.opacity(0.32), lineWidth: 8)
            .frame(width: diameter, height: diameter)
    }
}

private struct CareDialProgressArc: View {
    let diameter: CGFloat
    let progress: Double

    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: CareDialPalette.forest, location: 0),
                .init(color: CareDialPalette.forest, location: 0.82),
                .init(color: CareDialPalette.sage.opacity(0.72), location: 0.9),
                .init(color: CareDialPalette.sage, location: 0.95),
                .init(color: CareDialPalette.forest, location: 1)
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(-90))
            .shadow(color: CareDialPalette.shadow, radius: 3, x: 0, y: 2)
    }
}

private struct CareDialCore: View {
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay {
                Circle().fill(.white.opacity(0.55))
            }
            .frame(width: diameter, height: diameter)
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.92), CareDialPalette.sage.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: CareDialPalette.shadow, radius: 8, x: 0, y: 5)
    }
}

private struct CareDialProgressKnob: View {
    let center: CGPoint
    let radius: CGFloat
    let angle: Angle

    var body: some View {
        let radians = Double(angle.radians)
        let cosine: Double = cos(radians)
        let sine: Double = sin(radians)

        Circle()
            .fill(CareDialPalette.paleSage)
            .frame(width: 22, height: 22)
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.34), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.96), lineWidth: 1.25)
            }
            .shadow(color: CareDialPalette.shadow, radius: 6, x: 0, y: 3)
            .position(
                x: center.x + CGFloat(cosine) * radius,
                y: center.y + CGFloat(sine) * radius
            )
            .accessibilityHidden(true)
    }
}

private struct CareDialCountdown: View {
    var body: some View {
        VStack(spacing: 5) {
            Text("다음 급여까지")
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(CareDialPalette.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("6")
                    .font(.custom("Jua", size: 26, relativeTo: .title))

                Text("시간")
                    .font(.custom("Jua", size: 14, relativeTo: .body))
            }
            .foregroundStyle(CareDialPalette.primary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("6시간")
            .accessibilityIdentifier("careDial.countdown")
        }
        .multilineTextAlignment(.center)
    }
}

private struct CareDialLabels: View {
    let side: CGFloat

    private var center: CGFloat { side / 2 }

    var body: some View {
        ZStack {
            label("0", x: center, y: 3)
            label("1일", x: side - 3, y: center)
            label("2일", x: center, y: side - 3)
            label("3일", x: 3, y: center)
        }
    }

    private func label(_ title: String, x: CGFloat, y: CGFloat) -> some View {
        Text(title)
            .font(.custom("Jua", size: 10, relativeTo: .caption))
            .foregroundStyle(CareDialPalette.secondary)
            .position(x: x, y: y)
            .accessibilityHidden(true)
    }
}

private enum CareDialPalette {
    static let canvas = Color(.sRGB, red: 250 / 255, green: 247 / 255, blue: 240 / 255, opacity: 1)
    static let forest = Color(.sRGB, red: 47 / 255, green: 107 / 255, blue: 87 / 255, opacity: 1)
    static let primary = Color(.sRGB, red: 43 / 255, green: 42 / 255, blue: 38 / 255, opacity: 1)
    static let secondary = Color(.sRGB, red: 107 / 255, green: 103 / 255, blue: 94 / 255, opacity: 1)
    static let muted = Color(.sRGB, red: 171 / 255, green: 164 / 255, blue: 152 / 255, opacity: 1)
    static let paleSage = Color(.sRGB, red: 232 / 255, green: 234 / 255, blue: 227 / 255, opacity: 1)
    static let sage = Color(.sRGB, red: 143 / 255, green: 154 / 255, blue: 132 / 255, opacity: 1)
    static let shadow = Color(.sRGB, red: 61 / 255, green: 51 / 255, blue: 41 / 255, opacity: 0.08)
}
