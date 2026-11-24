import SwiftUI

struct RecordListView: View {
    let onBack: () -> Void

    @State private var selectedFilter: RecordListFilter = .all
    @State private var isNoticePresented = false
    @State private var noticeMessage = ""

    private var visibleGroups: [RecordListGroup] {
        RecordListGroup.samples.compactMap { group in
            let records = group.records.filter { selectedFilter.includes($0) }
            guard !records.isEmpty else { return nil }
            return RecordListGroup(id: group.id, dateTitle: group.dateTitle, records: records)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RecordListPalette.canvas
                    .ignoresSafeArea()

                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    navigationHeader
                        .padding(.horizontal, 16)

                    filterBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 22)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(visibleGroups) { group in
                                dateGroup(group)
                            }

                            if visibleGroups.isEmpty {
                                Text("선택한 유형의 기록이 없어요")
                                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                                    .foregroundStyle(RecordListPalette.tertiary)
                                    .frame(maxWidth: .infinity, minHeight: 96)
                                    .accessibilityIdentifier("recordList.empty")
                            }
                        }
                        .frame(maxWidth: 342)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("recordList.scroll")
                }
                .padding(.top, 10)
            }
        }
        .preferredColorScheme(.light)
        .alert("준비 중", isPresented: $isNoticePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(noticeMessage)
        }
    }

    private var navigationHeader: some View {
        ZStack {
            Text("기록 전체")
                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                .foregroundStyle(RecordListPalette.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("recordList.title")

            HStack(spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RecordListPalette.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
                .accessibilityIdentifier("recordList.back")

                Spacer(minLength: 8)

                Button {
                    showNotice("08-3 친구 선택 화면은 준비 중이에요.")
                } label: {
                    HStack(spacing: 5) {
                        Text("육이")
                            .font(.custom("Jua", size: 10, relativeTo: .caption))
                            .foregroundStyle(RecordListPalette.secondary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(RecordListPalette.tertiary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 12)
                    .frame(minWidth: 64, minHeight: 34)
                    .background(.white.opacity(0.76), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(RecordListPalette.border.opacity(0.82), lineWidth: 1)
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("친구 육이 선택")
                .accessibilityIdentifier("recordList.petSelector")
            }
        }
        .frame(height: 44)
    }

    private var filterBar: some View {
        HStack(spacing: 7) {
            ForEach(RecordListFilter.allCases) { filter in
                let isSelected = selectedFilter == filter

                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.title)
                        .font(.custom("Jua", size: 9, relativeTo: .caption))
                        .foregroundStyle(isSelected ? RecordListPalette.primary : RecordListPalette.secondary)
                        .padding(.horizontal, 11)
                        .frame(minHeight: 32)
                        .background {
                            Capsule()
                                .fill(.white.opacity(0.82))
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    isSelected ? RecordListPalette.border.opacity(0.48) : RecordListPalette.border.opacity(0.76),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: isSelected ? RecordListPalette.shadow : .clear,
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(filter.title)
                .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("recordList.filter.\(filter.rawValue)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recordList.filters")
    }

    private func dateGroup(_ group: RecordListGroup) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(group.dateTitle)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RecordListPalette.secondary)
                .accessibilityIdentifier("recordList.date.\(group.id)")

            VStack(spacing: 0) {
                ForEach(Array(group.records.enumerated()), id: \.element.id) { index, record in
                    recordRow(record, minimumHeight: group.records.count == 1 ? 76 : 68.5)

                    if index < group.records.count - 1 {
                        Rectangle()
                            .fill(RecordListPalette.border.opacity(0.66))
                            .frame(height: 1)
                            .padding(.leading, 60)
                            .padding(.trailing, 12)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.70))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(RecordListPalette.border.opacity(0.52), lineWidth: 1)
            }
            .shadow(color: RecordListPalette.shadow, radius: 16, x: 0, y: 5)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("recordList.group.\(group.id)")
        }
    }

    private func recordRow(_ record: RecordListRecord, minimumHeight: CGFloat) -> some View {
        Button {
            showNotice("08-1 기록 상세 화면은 준비 중이에요.")
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.88))
                        .frame(width: 36, height: 36)

                    switch record.kind {
                    case .weight:
                        Image("icon/weight")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    case .feeding:
                        Image("icon/feed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    case .shedding:
                        StackedSheddingLayers()
                            .stroke(
                                RecordListPalette.primary,
                                style: StrokeStyle(lineWidth: 4 / 3, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 16, height: 16)
                    }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.kind.title)
                        .font(.custom("Jua", size: 10, relativeTo: .caption))
                        .foregroundStyle(RecordListPalette.primary)

                    Text(record.detail)
                        .font(.custom("Jua", size: 9, relativeTo: .caption2))
                        .foregroundStyle(RecordListPalette.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                Text(record.time)
                    .font(.custom("Jua", size: 9, relativeTo: .caption))
                    .foregroundStyle(RecordListPalette.tertiary)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(record.kind.title), \(record.detail), \(record.time)")
        .accessibilityIdentifier("recordList.record.\(record.id)")
    }

    private func showNotice(_ message: String) {
        noticeMessage = message
        isNoticePresented = true
    }
}

private enum RecordListFilter: String, CaseIterable, Identifiable {
    case all
    case feeding
    case shedding
    case weight
    case memo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "전체"
        case .feeding: "급여"
        case .shedding: "탈피"
        case .weight: "체중"
        case .memo: "메모"
        }
    }

    func includes(_ record: RecordListRecord) -> Bool {
        switch self {
        case .all: true
        case .feeding: record.kind == .feeding
        case .shedding: record.kind == .shedding
        case .weight: record.kind == .weight
        case .memo: record.hasMemo
        }
    }
}

private enum RecordListKind {
    case feeding
    case shedding
    case weight

    var title: String {
        switch self {
        case .feeding: "급여"
        case .shedding: "탈피"
        case .weight: "체중"
        }
    }
}

private struct RecordListRecord: Identifiable {
    let id: String
    let kind: RecordListKind
    let detail: String
    let time: String
    let hasMemo: Bool
}

private struct RecordListGroup: Identifiable {
    let id: String
    let dateTitle: String
    let records: [RecordListRecord]

    static let samples = [
        RecordListGroup(
            id: "2026-10-20",
            dateTitle: "오늘 · 10월 20일",
            records: [
                RecordListRecord(id: "weight-1020", kind: .weight, detail: "53.4g · +1.4g", time: "09:12", hasMemo: false),
                RecordListRecord(id: "feeding-1020", kind: .feeding, detail: "귀뚜라미 50마리 · 칼슘", time: "09:05", hasMemo: false)
            ]
        ),
        RecordListGroup(
            id: "2026-10-17",
            dateTitle: "10월 17일",
            records: [
                RecordListRecord(id: "feeding-1017", kind: .feeding, detail: "귀뚜라미 50마리 · 잘 받아먹음", time: "20:30", hasMemo: true)
            ]
        ),
        RecordListGroup(
            id: "2026-10-13",
            dateTitle: "10월 13일",
            records: [
                RecordListRecord(id: "weight-1013", kind: .weight, detail: "52.0g · +1g", time: "10:00", hasMemo: false)
            ]
        ),
        RecordListGroup(
            id: "2026-10-08",
            dateTitle: "10월 8일",
            records: [
                RecordListRecord(id: "shedding-1008", kind: .shedding, detail: "완전 탈피 · 발가락 확인", time: "07:40", hasMemo: true),
                RecordListRecord(id: "feeding-1008", kind: .feeding, detail: "밀웜 4마리", time: "19:10", hasMemo: false)
            ]
        )
    ]
}

private struct StackedSheddingLayers: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 24
        let scaleY = rect.height / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        path.move(to: point(12, 2))
        path.addLine(to: point(22, 7))
        path.addLine(to: point(12, 12))
        path.addLine(to: point(2, 7))
        path.closeSubpath()

        path.move(to: point(2, 17))
        path.addLine(to: point(12, 22))
        path.addLine(to: point(22, 17))

        path.move(to: point(2, 12))
        path.addLine(to: point(12, 17))
        path.addLine(to: point(22, 12))

        return path
    }
}

private enum RecordListPalette {
    static let canvas = Color(red: 250 / 255, green: 247 / 255, blue: 240 / 255)
    static let primary = Color(red: 43 / 255, green: 42 / 255, blue: 38 / 255)
    static let secondary = Color(red: 107 / 255, green: 103 / 255, blue: 94 / 255)
    static let tertiary = Color(red: 115 / 255, green: 110 / 255, blue: 101 / 255)
    static let border = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255)
    static let shadow = Color(red: 43 / 255, green: 42 / 255, blue: 38 / 255).opacity(0.055)
}
