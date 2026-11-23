import SwiftUI

struct CareCalendarView: View {
    let onBack: () -> Void

    @State private var displayedMonth: Date
    @State private var selectedDate: Date

    private let locale = Locale(identifier: "ko_KR")

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
        let referenceDate = Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: 20))!
        _selectedDate = State(initialValue: referenceDate)
        _displayedMonth = State(initialValue: Self.calendar.dateInterval(of: .month, for: referenceDate)!.start)
    }

    fileprivate static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 1
        return calendar
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Self.calendar
        formatter.timeZone = Self.calendar.timeZone
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    private var selectedDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Self.calendar
        formatter.timeZone = Self.calendar.timeZone
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: selectedDate)
    }

    private var monthDays: [Int?] {
        guard
            let monthInterval = Self.calendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = Self.calendar.range(of: .day, in: .month, for: displayedMonth)
        else {
            return []
        }

        let leadingDays = Self.calendar.component(.weekday, from: monthInterval.start) - 1
        return Array(repeating: nil, count: leadingDays) + dayRange.map(Optional.some)
    }

    private var recordsForSelectedDate: [CareCalendarRecord] {
        CareCalendarRecord.samples.filter {
            Self.calendar.isDate($0.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CareCalendarPalette.canvas
                    .ignoresSafeArea()

                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        navigationHeader
                            .padding(.bottom, 16)

                        monthCard

                        legend
                            .padding(.top, 20)

                        Text(selectedDateTitle)
                            .font(.custom("Jua", size: 12, relativeTo: .caption))
                            .foregroundStyle(CareCalendarPalette.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 24)
                            .accessibilityIdentifier("careCalendar.selectedDate")

                        recordList
                            .padding(.top, 22)
                    }
                    .frame(maxWidth: 342)
                    .padding(.horizontal, 24)
                    .padding(.top, 11)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("careCalendar.scroll")
            }
        }
        .preferredColorScheme(.light)
    }

    private var navigationHeader: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CareCalendarPalette.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")
            .accessibilityIdentifier("careCalendar.back")

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CareCalendarPalette.secondary)
                        .frame(width: 28, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("이전 달")
                .accessibilityIdentifier("careCalendar.month.previous")

                Text(monthTitle)
                    .font(.custom("Jua", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(CareCalendarPalette.primary)
                    .lineLimit(1)
                    .fixedSize()
                    .accessibilityIdentifier("careCalendar.month")

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CareCalendarPalette.secondary)
                        .frame(width: 28, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("다음 달")
                .accessibilityIdentifier("careCalendar.month.next")
            }
            .accessibilityElement(children: .contain)

            Spacer(minLength: 0)

            Button(action: selectToday) {
                Text("오늘")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(CareCalendarPalette.secondary)
                    .frame(width: 54, height: 34)
                    .background(.white.opacity(0.84), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("careCalendar.today")
        }
        .frame(height: 44)
    }

    private var monthCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.custom("Jua", size: 10, relativeTo: .caption))
                        .foregroundStyle(CareCalendarPalette.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("일요일부터 토요일까지")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayButton(day)
                    } else {
                        Color.clear
                            .frame(height: 40)
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityIdentifier("careCalendar.days")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 13)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: CareCalendarPalette.shadow, radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("careCalendar.monthCard")
    }

    private func dayButton(_ day: Int) -> some View {
        let date = dateInDisplayedMonth(day)
        let isSelected = Self.calendar.isDate(date, inSameDayAs: selectedDate)
        let markers = CareCalendarRecord.categories(for: date)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(CareCalendarPalette.primary)

                HStack(spacing: 3) {
                    ForEach(markers, id: \.self) { category in
                        Circle()
                            .fill(category.color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.9))
                        .shadow(color: CareCalendarPalette.shadow, radius: 5, x: 0, y: 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day)일")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("careCalendar.day.\(day)")
    }

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(CareCalendarCategory.allCases) { category in
                HStack(spacing: 4) {
                    Circle()
                        .strokeBorder(category.color, lineWidth: category == .planned ? 1 : 0)
                        .background {
                            if category != .planned {
                                Circle().fill(category.color)
                            }
                        }
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)

                    Text(category.title)
                        .font(.custom("Jua", size: 10, relativeTo: .caption))
                        .foregroundStyle(CareCalendarPalette.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("careCalendar.legend")
    }

    @ViewBuilder
    private var recordList: some View {
        if recordsForSelectedDate.isEmpty {
            Text("등록된 기록이 없어요")
                .font(.custom("Jua", size: 12, relativeTo: .caption))
                .foregroundStyle(CareCalendarPalette.secondary)
                .frame(maxWidth: .infinity, minHeight: 62)
                .accessibilityIdentifier("careCalendar.emptyRecords")
        } else {
            VStack(spacing: 0) {
                ForEach(Array(recordsForSelectedDate.enumerated()), id: \.element.id) { index, record in
                    recordRow(record)
                    if index < recordsForSelectedDate.count - 1 {
                        Rectangle()
                            .fill(CareCalendarPalette.divider)
                            .frame(height: 1)
                            .padding(.leading, 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
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
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.86), lineWidth: 1)
            }
            .shadow(color: CareCalendarPalette.shadow, radius: 12, x: 0, y: 6)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("careCalendar.records")
        }
    }

    private func recordRow(_ record: CareCalendarRecord) -> some View {
        HStack(spacing: 12) {
            Image(record.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.9), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(CareCalendarPalette.primary)
                    .accessibilityIdentifier("careCalendar.record.\(record.id).title")

                Text(record.detail)
                    .font(.custom("Jua", size: 9, relativeTo: .caption2))
                    .foregroundStyle(CareCalendarPalette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityIdentifier("careCalendar.record.\(record.id).detail")
            }

            Spacer(minLength: 8)

            Text(record.time)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(CareCalendarPalette.secondary)
                .accessibilityIdentifier("careCalendar.record.\(record.id).time")
        }
        .frame(minHeight: 70)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("careCalendar.record.\(record.id)")
    }

    private func dateInDisplayedMonth(_ day: Int) -> Date {
        Self.calendar.date(byAdding: .day, value: day - 1, to: displayedMonth) ?? displayedMonth
    }

    private func changeMonth(by offset: Int) {
        guard let updatedMonth = Self.calendar.date(byAdding: .month, value: offset, to: displayedMonth),
              let monthInterval = Self.calendar.dateInterval(of: .month, for: updatedMonth),
              let dayRange = Self.calendar.range(of: .day, in: .month, for: updatedMonth)
        else {
            return
        }

        let selectedDay = Self.calendar.component(.day, from: selectedDate)
        displayedMonth = monthInterval.start
        selectedDate = dateInDisplayedMonth(min(selectedDay, dayRange.count))
    }

    private func selectToday() {
        let today = Self.calendar.startOfDay(for: Date())
        displayedMonth = Self.calendar.dateInterval(of: .month, for: today)?.start ?? today
        selectedDate = today
    }
}

private enum CareCalendarCategory: String, CaseIterable, Hashable, Identifiable {
    case feeding
    case weight
    case shedding
    case planned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feeding: "급여"
        case .weight: "체중"
        case .shedding: "탈피"
        case .planned: "예정"
        }
    }

    var color: Color {
        switch self {
        case .feeding: CareCalendarPalette.primary
        case .weight: CareCalendarPalette.muted
        case .shedding: CareCalendarPalette.forest
        case .planned: CareCalendarPalette.forest
        }
    }
}

private struct CareCalendarRecord: Identifiable {
    let id: String
    let date: Date
    let category: CareCalendarCategory
    let title: String
    let detail: String
    let time: String
    let assetName: String

    static let samples: [CareCalendarRecord] = {
        let date = CareCalendarView.calendar.date(from: DateComponents(year: 2026, month: 10, day: 20))!
        return [
            CareCalendarRecord(
                id: "weight",
                date: date,
                category: .weight,
                title: "체중",
                detail: "53.4g · +1.4g",
                time: "09:12",
                assetName: "icon/weight"
            ),
            CareCalendarRecord(
                id: "feeding",
                date: date,
                category: .feeding,
                title: "급여",
                detail: "귀뚜라미 50마리 · 칼슘",
                time: "09:05",
                assetName: "icon/feed"
            )
        ]
    }()

    static func categories(for date: Date) -> [CareCalendarCategory] {
        let calendar = CareCalendarView.calendar
        guard calendar.component(.year, from: date) == 2026,
              calendar.component(.month, from: date) == 10
        else {
            return []
        }

        let sample: [Int: [CareCalendarCategory]] = [
            6: [.weight, .shedding],
            8: [.feeding, .shedding],
            10: [.feeding],
            12: [.feeding],
            14: [.shedding],
            17: [.feeding],
            20: [.feeding, .weight],
            22: [.planned]
        ]
        return sample[calendar.component(.day, from: date)] ?? []
    }
}

private enum CareCalendarPalette {
    static let canvas = Color(.sRGB, red: 250 / 255, green: 247 / 255, blue: 240 / 255, opacity: 1)
    static let forest = Color(.sRGB, red: 47 / 255, green: 107 / 255, blue: 87 / 255, opacity: 1)
    static let primary = Color(.sRGB, red: 43 / 255, green: 42 / 255, blue: 38 / 255, opacity: 1)
    static let secondary = Color(.sRGB, red: 107 / 255, green: 103 / 255, blue: 94 / 255, opacity: 1)
    static let muted = Color(.sRGB, red: 171 / 255, green: 164 / 255, blue: 152 / 255, opacity: 1)
    static let divider = Color(.sRGB, red: 225 / 255, green: 220 / 255, blue: 211 / 255, opacity: 0.7)
    static let shadow = Color(.sRGB, red: 61 / 255, green: 51 / 255, blue: 41 / 255, opacity: 0.08)
}
