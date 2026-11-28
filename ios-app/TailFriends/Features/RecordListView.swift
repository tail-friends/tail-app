import SwiftUI

struct RecordListView: View {
    let onBack: () -> Void

    @State private var recordGroups = RecordListGroup.samples
    @State private var selectedFilter: RecordListFilter = .all
    @State private var editSession: RecordListEditSession?
#if DEBUG
    @State private var isFriendSelectionPresented = ProcessInfo.processInfo.arguments.contains("--preview-friend-selection")
#else
    @State private var isFriendSelectionPresented = false
#endif
#if DEBUG
    @State private var friendSelection: FriendSelectionState = {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--preview-friend-selection-all") {
            return .all
        }
        if arguments.contains("--preview-friend-selection-none") {
            return .none
        }
        if arguments.contains("--preview-friend-selection-empty") {
            return .friend("chito")
        }
        return .friend(FriendSelectionFriend.idWithLocalRecordSamples)
    }()
#else
    @State private var friendSelection: FriendSelectionState = .friend(FriendSelectionFriend.idWithLocalRecordSamples)
#endif
    @State private var isNoticePresented = false
    @State private var noticeMessage = ""

    private var selectedFriendName: String {
        switch friendSelection {
        case .all:
            return "전체 친구"
        case .none:
            return "선택 없음"
        case .friend(let id):
            return FriendSelectionFriend.samples.first(where: { $0.id == id })?.name ?? "육이"
        }
    }

    private var petSelectorAccessibilityLabel: String {
        friendSelection == .none ? "선택된 친구 없음" : "친구 \(selectedFriendName) 선택"
    }

    private var selectedFriendHasLocalRecords: Bool {
        switch friendSelection {
        case .all:
            return true
        case .none:
            return false
        case .friend(let id):
            return id == FriendSelectionFriend.idWithLocalRecordSamples
        }
    }

    private var emptyRecordMessage: String {
        selectedFriendHasLocalRecords ? "선택한 유형의 기록이 없어요" : "아직 기록이 없어요"
    }

    private var visibleGroups: [RecordListGroup] {
        guard selectedFriendHasLocalRecords else { return [] }
        return recordGroups.compactMap { group in
            let records = group.records.filter { selectedFilter.includes($0) }
            guard !records.isEmpty else { return nil }
            return RecordListGroup(
                id: group.id,
                dateTitle: group.dateTitle,
                date: group.date,
                records: records
            )
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
                                Text(emptyRecordMessage)
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
                .accessibilityHidden(editSession != nil)

                if let editSession {
                    FeedingRecordEditView(
                        initialData: editSession.data,
                        onBack: cancelEditing,
                        onSave: { updatedData in
                            saveEditedRecord(updatedData, id: editSession.recordID)
                        }
                    )
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }
            }
        }
        .preferredColorScheme(.light)
        .alert("준비 중", isPresented: $isNoticePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(noticeMessage)
        }
        .sheet(isPresented: $isFriendSelectionPresented) {
            FriendSelectionSheet(selectionState: $friendSelection)
                .presentationDetents([.height(479)])
                .presentationCornerRadius(28)
                .presentationDragIndicator(.hidden)
                .presentationBackground(.white)
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
                    isFriendSelectionPresented = true
                } label: {
                    HStack(spacing: 5) {
                        Text(selectedFriendName)
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
                .accessibilityLabel(petSelectorAccessibilityLabel)
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
            if let feedingData = record.feedingData {
                withAnimation(.easeInOut(duration: 0.2)) {
                    editSession = RecordListEditSession(recordID: record.id, data: feedingData)
                }
            } else {
                showNotice("이 기록의 상세 화면은 준비 중이에요.")
            }
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

    private func cancelEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            editSession = nil
        }
    }

    private func saveEditedRecord(_ data: FeedingRecordEditData, id: String) {
        guard let sourceGroupIndex = recordGroups.firstIndex(where: { group in
            group.records.contains(where: { $0.id == id })
        }),
        let sourceRecordIndex = recordGroups[sourceGroupIndex].records.firstIndex(where: { $0.id == id }) else {
            cancelEditing()
            return
        }

        var updatedRecord = recordGroups[sourceGroupIndex].records[sourceRecordIndex]
        updatedRecord.feedingData = data
        updatedRecord.detail = data.listDetail
        updatedRecord.hasMemo = !data.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let destinationID = RecordListGroup.dateID(for: data.date)
        let sourceID = recordGroups[sourceGroupIndex].id

        if destinationID == sourceID {
            recordGroups[sourceGroupIndex].dateTitle = RecordListGroup.dateTitle(for: data.date)
            recordGroups[sourceGroupIndex].records[sourceRecordIndex] = updatedRecord
        } else {
            recordGroups[sourceGroupIndex].records.remove(at: sourceRecordIndex)
            if recordGroups[sourceGroupIndex].records.isEmpty {
                recordGroups.remove(at: sourceGroupIndex)
            }

            if let destinationIndex = recordGroups.firstIndex(where: { $0.id == destinationID }) {
                recordGroups[destinationIndex].records.append(updatedRecord)
                recordGroups[destinationIndex].records.sort { $0.time > $1.time }
            } else {
                recordGroups.append(
                    RecordListGroup(
                        id: destinationID,
                        dateTitle: RecordListGroup.dateTitle(for: data.date),
                        date: Calendar.current.startOfDay(for: data.date),
                        records: [updatedRecord]
                    )
                )
            }
            recordGroups.sort { $0.date > $1.date }
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            editSession = nil
        }
    }
}

private struct RecordListEditSession {
    let recordID: String
    let data: FeedingRecordEditData
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
    var detail: String
    let time: String
    var hasMemo: Bool
    var feedingData: FeedingRecordEditData? = nil
}

private struct RecordListGroup: Identifiable {
    var id: String
    var dateTitle: String
    let date: Date
    var records: [RecordListRecord]

    static func dateID(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func dateTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M월 d일"
        let dateText = formatter.string(from: date)

        return Calendar.current.isDate(date, inSameDayAs: sampleDate(day: 20))
            ? "오늘 · \(dateText)"
            : dateText
    }

    private static func sampleDate(day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: day)) ?? .now
    }

    static let samples = [
        RecordListGroup(
            id: "2026-10-20",
            dateTitle: "오늘 · 10월 20일",
            date: sampleDate(day: 20),
            records: [
                RecordListRecord(id: "weight-1020", kind: .weight, detail: "53.4g · +1.4g", time: "09:12", hasMemo: false),
                RecordListRecord(
                    id: "feeding-1020",
                    kind: .feeding,
                    detail: "귀뚜라미 50마리 · 칼슘",
                    time: "09:05",
                    hasMemo: false,
                    feedingData: FeedingRecordEditData(
                        date: sampleDate(day: 20),
                        food: "귀뚜라미",
                        quantity: 50,
                        didNotEat: false,
                        memo: "칼슘"
                    )
                )
            ]
        ),
        RecordListGroup(
            id: "2026-10-17",
            dateTitle: "10월 17일",
            date: sampleDate(day: 17),
            records: [
                RecordListRecord(
                    id: "feeding-1017",
                    kind: .feeding,
                    detail: "귀뚜라미 50마리 · 잘 받아먹음",
                    time: "20:30",
                    hasMemo: true,
                    feedingData: FeedingRecordEditData(
                        date: sampleDate(day: 17),
                        food: "귀뚜라미",
                        quantity: 50,
                        didNotEat: false,
                        memo: "잘 받아먹음"
                    )
                )
            ]
        ),
        RecordListGroup(
            id: "2026-10-13",
            dateTitle: "10월 13일",
            date: sampleDate(day: 13),
            records: [
                RecordListRecord(id: "weight-1013", kind: .weight, detail: "52.0g · +1g", time: "10:00", hasMemo: false)
            ]
        ),
        RecordListGroup(
            id: "2026-10-08",
            dateTitle: "10월 8일",
            date: sampleDate(day: 8),
            records: [
                RecordListRecord(id: "shedding-1008", kind: .shedding, detail: "완전 탈피 · 발가락 확인", time: "07:40", hasMemo: true),
                RecordListRecord(
                    id: "feeding-1008",
                    kind: .feeding,
                    detail: "밀웜 4마리",
                    time: "19:10",
                    hasMemo: false,
                    feedingData: FeedingRecordEditData(
                        date: sampleDate(day: 8),
                        food: "밀웜",
                        quantity: 4,
                        didNotEat: false,
                        memo: ""
                    )
                )
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
