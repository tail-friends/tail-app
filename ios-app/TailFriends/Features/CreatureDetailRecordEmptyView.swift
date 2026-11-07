import SwiftUI

struct CreatureDetailRecordEmptyView: View {
    @Environment(\.dismiss) private var dismiss

    var onBack: (() -> Void)? = nil

    @State private var selectedCategory: String? = nil
    @State private var isNoticePresented = false
    @State private var noticeTitle = ""
    @State private var noticeMessage = ""

    private let categories: [(title: String, symbol: String)] = [
        ("급여", "ladybug.fill"),
        ("탈피", "square.3.layers.3d"),
        ("체중", "scalemass.fill"),
        ("청소", "drop.fill"),
        ("환경", "thermometer.medium")
    ]
    private let managementItems = ["성장 앨범", "합사 보기", "번식 기록", "쿨링(휴면) 모드"]

    var body: some View {
        ZStack {
            RecordEmptyPalette.canvas.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    heroCard
                    creatureSummary
                    metricsCard
                    categoryPicker
                    weightChart
                    recentRecordSection
                    managementSection
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
                .frame(maxWidth: 390)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("creatureDetailRecordEmpty.scroll")
        }
        .preferredColorScheme(.light)
        .alert(noticeTitle, isPresented: $isNoticePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(noticeMessage)
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(RecordEmptyPalette.photoPlaceholder)

            PhotoPlaceholderMark(color: RecordEmptyPalette.photoPlaceholderMark)

            VStack(spacing: 8) {
                HStack {
                    Button {
                        if let onBack {
                            onBack()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RecordEmptyPalette.primary)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.82), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("뒤로")
                    .accessibilityIdentifier("creatureDetailRecordEmpty.back")

                    Spacer()

                    Button {
                        showNotice(title: "수정 미리보기", message: "친구 정보 수정은 준비 중이에요.")
                    } label: {
                        Text("수정")
                            .font(.custom("Jua", size: 13, relativeTo: .subheadline))
                            .foregroundStyle(RecordEmptyPalette.primary)
                            .frame(minWidth: 60, minHeight: 44)
                            .background(.white.opacity(0.82), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("creatureDetailRecordEmpty.edit")
                }

                Spacer(minLength: 0)

                HStack {
                    Text("사막 · 평소")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(RecordEmptyPalette.primary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(.white.opacity(0.84), in: Capsule())
                    Spacer()
                }
            }
            .padding(12)
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.78), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordEmpty.hero")
    }

    private var creatureSummary: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("욱이")
                .font(.custom("Jua", size: 20, relativeTo: .title2))
                .foregroundStyle(RecordEmptyPalette.primary)
                .accessibilityAddTraits(.isHeader)

            Text("레오파드 게코 · 탄제린 · 수컷 · 생후 1년 7개월")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(RecordEmptyPalette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("creatureDetailRecordEmpty.description")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricsCard: some View {
        HStack(spacing: 0) {
            metric(title: "다음 급여", identifier: "feeding")
            metricDivider
            metric(title: "마지막 탈피", identifier: "molting")
            metricDivider
            metric(title: "체중", identifier: "weight")
        }
        .padding(.vertical, 15)
        .background(RecordEmptyPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.85), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordEmpty.metrics")
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(RecordEmptyPalette.divider)
            .frame(width: 1, height: 42)
            .accessibilityHidden(true)
    }

    private func metric(title: String, identifier: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RecordEmptyPalette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("기록 없음")
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(RecordEmptyPalette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("creatureDetailRecordEmpty.metric.\(identifier).value")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("creatureDetailRecordEmpty.metric.\(identifier)")
    }

    private var categoryPicker: some View {
        HStack(spacing: 2) {
            ForEach(categories, id: \.title) { category in
                let isSelected = selectedCategory == category.title
                Button {
                    selectedCategory = category.title
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityHidden(true)
                        Text(category.title)
                            .font(.custom("Jua", size: 11, relativeTo: .caption))
                    }
                    .foregroundStyle(isSelected ? RecordEmptyPalette.forest : RecordEmptyPalette.primary)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.title)
                .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                .accessibilityIdentifier("creatureDetailRecordEmpty.category.\(category.title)")
            }
        }
        .padding(4)
        .background(RecordEmptyPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordEmpty.categoryPicker")
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("체중 변화")
                .font(.custom("Jua", size: 16, relativeTo: .headline))
                .foregroundStyle(RecordEmptyPalette.primary)
                .accessibilityAddTraits(.isHeader)

            Text("체중을 두 번 이상 기록하면 그래프가 그려져요")
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RecordEmptyPalette.secondary)
                .frame(maxWidth: .infinity, minHeight: 68)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("creatureDetailRecordEmpty.weightChart.empty")
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 132)
        .background(RecordEmptyPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordEmpty.weightChart")
    }

    private var recentRecordSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("최근 기록")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(RecordEmptyPalette.primary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    showNotice(title: "최근 기록", message: "아직 기록이 없어요.")
                } label: {
                    HStack(spacing: 4) {
                        Text("전체 보기")
                        Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                    }
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RecordEmptyPalette.secondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("creatureDetailRecordEmpty.records.all")
            }

            VStack(spacing: 4) {
                Text("아직 기록이 없어요")
                    .font(.custom("Jua", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(RecordEmptyPalette.primary)
                    .accessibilityIdentifier("creatureDetailRecordEmpty.records.empty.title")

                Text("위 버튼으로 첫 기록을 남겨 보세요")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RecordEmptyPalette.secondary)
                    .accessibilityIdentifier("creatureDetailRecordEmpty.records.empty.message")
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(RecordEmptyPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("creatureDetailRecordEmpty.records.empty")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordEmpty.records")
    }

    private var managementSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("관리")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(RecordEmptyPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(managementItems.enumerated()), id: \.offset) { item in
                    let index = item.offset
                    let title = item.element
                    Button {
                        showNotice(title: "준비 중", message: "\(title)은 준비 중이에요.")
                    } label: {
                        HStack {
                            Text(title)
                                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                                .foregroundStyle(RecordEmptyPalette.primary)
                            Spacer()
                            Text("준비 중")
                                .font(.custom("Jua", size: 9, relativeTo: .caption2))
                                .foregroundStyle(RecordEmptyPalette.tertiary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(RecordEmptyPalette.tertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("creatureDetailRecordEmpty.management.\(index)")

                    if index < managementItems.count - 1 {
                        Divider().overlay(RecordEmptyPalette.line).padding(.leading, 14)
                    }
                }
            }
            .background(RecordEmptyPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordEmpty.managementSection")
    }

    private func showNotice(title: String, message: String) {
        noticeTitle = title
        noticeMessage = message
        isNoticePresented = true
    }
}

private enum RecordEmptyPalette {
    static let canvas = Color(recordEmptyHex: 0xFAF7F0)
    static let primary = Color(recordEmptyHex: 0x2B2A26)
    static let secondary = Color(recordEmptyHex: 0x6B675E)
    static let tertiary = Color(recordEmptyHex: 0x8B857A)
    static let forest = Color(recordEmptyHex: 0x2F6B57)
    static let card = Color.white.opacity(0.82)
    static let line = Color(recordEmptyHex: 0xE7E1D6)
    static let divider = Color(recordEmptyHex: 0xE7E1D6).opacity(0.8)
    static let photoPlaceholder = Color(recordEmptyHex: 0xE4DDD3)
    static let photoPlaceholderMark = Color(recordEmptyHex: 0x9C968D)
}

private struct PhotoPlaceholderMark: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(color, lineWidth: 1.25)
                .frame(width: 21, height: 16)

            Path { path in
                path.move(to: CGPoint(x: 5, y: 14))
                path.addLine(to: CGPoint(x: 9, y: 9))
                path.addLine(to: CGPoint(x: 12, y: 12))
                path.addLine(to: CGPoint(x: 16, y: 8))
                path.addLine(to: CGPoint(x: 20, y: 14))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
            .frame(width: 25, height: 20)

            Circle()
                .fill(color)
                .frame(width: 2.5, height: 2.5)
                .offset(x: 5, y: -4)
        }
        .frame(width: 25, height: 20)
        .accessibilityHidden(true)
    }
}

private extension Color {
    init(recordEmptyHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
