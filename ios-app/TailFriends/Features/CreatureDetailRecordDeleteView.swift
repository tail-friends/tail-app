import SwiftUI

struct CreatureDetailRecordDeleteView: View {
    @Environment(\.dismiss) private var dismiss

    var onBack: (() -> Void)? = nil

    @State private var selectedCategory = "급여"
    @State private var records = DetailRecord.previewRecords
    @State private var armedDeleteID: String? = "feeding-1016"
    @State private var isNoticePresented = false
    @State private var noticeTitle = ""
    @State private var noticeMessage = ""

    private let categories: [(title: String, symbol: String)] = [
        ("급여", "takeoutbag.and.cup.and.straw.fill"),
        ("탈피", "square.3.layers.3d"),
        ("체중", "scalemass.fill"),
        ("청소", "sparkles"),
        ("환경", "sun.max.fill")
    ]

    private let managementItems = ["성장 앨범", "합사 보기", "번식 기록", "쿨링(휴면) 모드"]

    var body: some View {
        ZStack {
            RecordDetailPalette.canvas.ignoresSafeArea()

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
            .accessibilityIdentifier("creatureDetailRecordDelete.scroll")
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
                .fill(
                    LinearGradient(
                        colors: [RecordDetailPalette.photoTop, RecordDetailPalette.photoBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "photo")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(RecordDetailPalette.secondary.opacity(0.38))
                .accessibilityHidden(true)

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
                            .foregroundStyle(RecordDetailPalette.primary)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.82), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("뒤로")
                    .accessibilityIdentifier("creatureDetailRecordDelete.back")

                    Spacer()

                    Button {
                        showNotice(title: "수정 미리보기", message: "친구 정보 수정은 준비 중이에요.")
                    } label: {
                        Text("수정")
                            .font(.custom("Jua", size: 13, relativeTo: .subheadline))
                            .foregroundStyle(RecordDetailPalette.primary)
                            .frame(minWidth: 60, minHeight: 44)
                            .background(.white.opacity(0.82), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("creatureDetailRecordDelete.edit")
                }

                HStack {
                    Spacer()
                    Text("오늘 밥 먹는 날!")
                        .font(.custom("Jua", size: 12, relativeTo: .caption))
                        .foregroundStyle(RecordDetailPalette.primary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(.white.opacity(0.84), in: Capsule())
                }

                Spacer(minLength: 0)

                HStack {
                    Text("사막 · 평소")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(RecordDetailPalette.primary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(.white.opacity(0.84), in: Capsule())
                    Spacer()
                }
            }
            .padding(12)
        }
        .frame(height: 228)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.78), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordDelete.hero")
    }

    private var creatureSummary: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text("욱이")
                    .font(.custom("Jua", size: 20, relativeTo: .title2))
                    .foregroundStyle(RecordDetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)

                Text("레오파드 게코 · 탄제린 · 수컷 · 생후 1년 7개월")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(RecordDetailPalette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("creatureDetailRecordDelete.description")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricsCard: some View {
        HStack(spacing: 0) {
            metric(title: "다음 급여", value: "오늘", detail: "4일 주기")
            metricDivider
            metric(title: "마지막 탈피", value: "12일 전", detail: "평균 21일")
            metricDivider
            metric(title: "체중", value: "53.4g", detail: "+1.4g")
        }
        .padding(.vertical, 29)
        .background(RecordDetailPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.85), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordDelete.metrics")
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(RecordDetailPalette.divider)
            .frame(width: 1, height: 42)
            .accessibilityHidden(true)
    }

    private func metric(title: String, value: String, detail: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RecordDetailPalette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value)
                .font(.custom("Jua", size: 15, relativeTo: .body))
                .foregroundStyle(RecordDetailPalette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(detail)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RecordDetailPalette.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var categoryPicker: some View {
        HStack(spacing: 2) {
            ForEach(categories, id: \.title) { category in
                let isSelected = selectedCategory == category.title
                let isAvailable = ["급여", "탈피", "체중"].contains(category.title)
                Button {
                    selectedCategory = category.title
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(category.title)
                            .font(.custom("Jua", size: 11, relativeTo: .caption))
                    }
                    .foregroundStyle(isAvailable ? RecordDetailPalette.primary : RecordDetailPalette.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.title)
                .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                .accessibilityIdentifier("creatureDetailRecordDelete.category.\(category.title)")
            }
        }
        .padding(4)
        .background(RecordDetailPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordDelete.categoryPicker")
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("체중 변화")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(RecordDetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("최근 53.4g (+1.4g)")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RecordDetailPalette.primary)
            }

            GeometryReader { geometry in
                let inset: CGFloat = 8
                let plotRect = CGRect(
                    x: 0,
                    y: 0,
                    width: max(0, geometry.size.width - inset),
                    height: max(0, geometry.size.height - inset * 2)
                )
                let endpoint = DetailWeightTrendShape.endpoint(in: plotRect)

                ZStack(alignment: .topLeading) {
                    VStack {
                        ForEach(0..<3) { _ in
                            Rectangle()
                                .fill(RecordDetailPalette.secondary.opacity(0.35))
                                .frame(height: 1)
                            Spacer(minLength: 0)
                        }
                    }
                    DetailWeightTrendShape()
                        .stroke(
                            RecordDetailPalette.primary,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        .padding(.vertical, inset)
                        .padding(.trailing, inset)
                    Circle()
                        .fill(RecordDetailPalette.primary)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .position(x: endpoint.x, y: inset + endpoint.y)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(height: 120)
            .accessibilityHidden(true)

            HStack {
                Text("최소 41.0g · 5월")
                Spacer()
                Text("최대 53.4g · 10월 20일")
            }
            .font(.custom("Jua", size: 9, relativeTo: .caption2))
            .foregroundStyle(RecordDetailPalette.tertiary)
        }
        .padding(16)
        .frame(height: 210)
        .background(RecordDetailPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordDelete.weightChart")
    }

    private var recentRecordSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("최근 기록")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(RecordDetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showNotice(title: "최근 기록", message: "전체 기록 보기는 준비 중이에요.")
                } label: {
                    HStack(spacing: 4) {
                        Text("전체 보기")
                        Image(systemName: "chevron.right")
                    }
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RecordDetailPalette.secondary)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("creatureDetailRecordDelete.records.all")
            }

            VStack(spacing: 0) {
                ForEach(records) { record in
                    recordRow(record)
                    if record.id != records.last?.id {
                        Divider()
                            .overlay(RecordDetailPalette.line)
                            .padding(.leading, 32)
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(RecordDetailPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("creatureDetailRecordDelete.records")
        }
    }

    private func recordRow(_ record: DetailRecord) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(record.kind == .feeding ? RecordDetailPalette.primary : RecordDetailPalette.delete)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.kind.title)
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                    .foregroundStyle(RecordDetailPalette.primary)
                Text(record.detail)
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RecordDetailPalette.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(record.date)
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(RecordDetailPalette.secondary)
                .fixedSize()

            if armedDeleteID == record.id {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        records.removeAll { $0.id == record.id }
                        armedDeleteID = nil
                    }
                } label: {
                    Text("삭제")
                        .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 42)
                        .background(RecordDetailPalette.delete, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(record.kind.title) \(record.date) 기록 삭제")
                .accessibilityIdentifier("creatureDetailRecordDelete.confirmDelete.\(record.id)")
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        armedDeleteID = record.id
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(RecordDetailPalette.tertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(record.kind.title) \(record.date) 삭제 버튼 표시")
                .accessibilityIdentifier("creatureDetailRecordDelete.revealDelete.\(record.id)")
            }
        }
        .frame(minHeight: 62)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetailRecordDelete.record.\(record.id)")
    }

    private var managementSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("관리")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(RecordDetailPalette.primary)
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
                                .foregroundStyle(RecordDetailPalette.primary)
                            Spacer()
                            Text("준비 중")
                                .font(.custom("Jua", size: 9, relativeTo: .caption2))
                                .foregroundStyle(RecordDetailPalette.tertiary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(RecordDetailPalette.track, in: Capsule())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(RecordDetailPalette.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("creatureDetailRecordDelete.management.\(index)")
                    if index < managementItems.count - 1 {
                        Divider().overlay(RecordDetailPalette.line).padding(.leading, 14)
                    }
                }
            }
            .background(RecordDetailPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
            }
        }
    }

    private func showNotice(title: String, message: String) {
        noticeTitle = title
        noticeMessage = message
        isNoticePresented = true
    }
}

private struct DetailRecord: Identifiable {
    enum Kind: Equatable {
        case weight
        case feeding

        var title: String {
            switch self {
            case .weight: "체중"
            case .feeding: "급여"
            }
        }
    }

    let id: String
    let kind: Kind
    let detail: String
    let date: String

    static let previewRecords = [
        DetailRecord(id: "weight-1020", kind: .weight, detail: "53.4g · +1.4g", date: "10.20"),
        DetailRecord(id: "feeding-1016", kind: .feeding, detail: "귀뚜라미 50마리", date: "10.16"),
        DetailRecord(id: "weight-1013", kind: .weight, detail: "52.0g · +0.5g", date: "10.13")
    ]
}

private struct DetailWeightTrendShape: Shape {
    private static let normalizedPoints: [CGPoint] = [
        CGPoint(x: 0, y: 0.82),
        CGPoint(x: 0.18, y: 0.68),
        CGPoint(x: 0.34, y: 0.75),
        CGPoint(x: 0.51, y: 0.46),
        CGPoint(x: 0.67, y: 0.53),
        CGPoint(x: 0.83, y: 0.28),
        CGPoint(x: 1, y: 0.12)
    ]

    static func endpoint(in rect: CGRect) -> CGPoint {
        guard let point = normalizedPoints.last else { return .zero }
        return CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
    }

    func path(in rect: CGRect) -> Path {
        let points = Self.normalizedPoints.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        guard let first = points.first else { return Path() }

        var path = Path()
        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let beforePrevious = points[max(0, index - 2)]
            let afterCurrent = points[min(points.count - 1, index + 1)]
            let control1 = CGPoint(
                x: previous.x + (current.x - beforePrevious.x) / 6,
                y: previous.y + (current.y - beforePrevious.y) / 6
            )
            let control2 = CGPoint(
                x: current.x - (afterCurrent.x - previous.x) / 6,
                y: current.y - (afterCurrent.y - previous.y) / 6
            )
            path.addCurve(to: current, control1: control1, control2: control2)
        }
        return path
    }
}

private enum RecordDetailPalette {
    static let canvas = Color(recordDetailHex: 0xFAF7F0)
    static let primary = Color(recordDetailHex: 0x2B2A26)
    static let secondary = Color(recordDetailHex: 0x6B675E)
    static let tertiary = Color(recordDetailHex: 0x8B857A)
    static let card = Color.white.opacity(0.82)
    static let track = Color.white.opacity(0.42)
    static let line = Color(recordDetailHex: 0xE7E1D6)
    static let divider = Color(recordDetailHex: 0xE7E1D6).opacity(0.8)
    static let photoTop = Color(recordDetailHex: 0xDAD6C9)
    static let photoBottom = Color(recordDetailHex: 0xC8C5B9)
    static let delete = Color(recordDetailHex: 0xB78E71)
}

private extension Color {
    init(recordDetailHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
