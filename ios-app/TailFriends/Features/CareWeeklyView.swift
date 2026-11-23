import SwiftUI

struct CareWeeklyView: View {
    let onTodayTap: () -> Void
    let onCalendarTap: () -> Void

    @State private var selectedDate = 20

    private let days = CareWeeklyDay.week

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CareWeeklyPalette.canvas
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
                        topControls
                            .frame(height: 36)
                            .offset(y: 15)
                            .padding(.bottom, 35)

                        Text("이번 주 육이는\n잘 지냈어요")
                            .font(.custom("Jua", size: 21, relativeTo: .title2))
                            .foregroundStyle(CareWeeklyPalette.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("careWeekly.headline")

                        Text("10월 14일 – 10월 20일")
                            .font(.custom("Jua", size: 12, relativeTo: .caption))
                            .foregroundStyle(CareWeeklyPalette.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 26)
                            .padding(.bottom, 22)
                            .accessibilityIdentifier("careWeekly.dateRange")

                        weeklyCalendar
                            .padding(.bottom, 20)

                        summaryCards
                            .frame(height: 68)
                            .padding(.bottom, 16)

                        sheddingNotice
                            .frame(height: 62)
                            .offset(y: 5)
                    }
                    .frame(maxWidth: 342)
                    .padding(.horizontal, 24)
                    .padding(.top, 5)
                    .padding(.bottom, 116)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var topControls: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                periodButton(title: "오늘", selected: false, identifier: "today", action: onTodayTap)
                periodButton(title: "주간", selected: true, identifier: "week", action: {})
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("careWeekly.periodSwitch")

            Spacer(minLength: 0)

            Button(action: onCalendarTap) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CareWeeklyPalette.primary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.86), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("캘린더")
            .accessibilityIdentifier("careWeekly.calendar")
        }
    }

    private func periodButton(
        title: String,
        selected: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Jua", size: 12, relativeTo: .caption))
                .foregroundStyle(selected ? CareWeeklyPalette.forest : CareWeeklyPalette.secondary)
                .frame(width: 44, height: selected ? 30 : 36)
                .frame(maxHeight: .infinity)
                .background {
                    if selected {
                        Capsule()
                            .fill(.white.opacity(0.88))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 36)
        .accessibilityLabel(title)
        .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("careWeekly.period.\(identifier)")
    }

    private var weeklyCalendar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                rowLabels
                    .frame(width: 37)

                HStack(spacing: 2) {
                    ForEach(days) { day in
                        dayColumn(day)
                    }
                }
            }
            .frame(height: 142)

            HStack(alignment: .firstTextBaseline) {
                Text("기록한 날 4일 / 7일")
                    .accessibilityIdentifier("careWeekly.recordedDays")

                Spacer(minLength: 6)

                Text("탈피 예정 · 10월 29일")
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("careWeekly.nextShedding")
            }
            .font(.custom("Jua", size: 10, relativeTo: .caption))
            .foregroundStyle(CareWeeklyPalette.secondary)
            .padding(.horizontal, 5)
        }
        .padding(.horizontal, 12)
        .padding(.top, 15)
        .padding(.bottom, 15)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.72), .white.opacity(0.34)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.84), lineWidth: 1)
        }
        .shadow(color: CareWeeklyPalette.shadow, radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("careWeekly.calendarGrid")
    }

    private var rowLabels: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 43)

            Text("급여")
                .frame(height: 31)
            Text("체중")
                .frame(height: 31)
            Text("탈피")
                .frame(height: 31)
        }
        .font(.custom("Jua", size: 9, relativeTo: .caption2))
        .foregroundStyle(CareWeeklyPalette.secondary)
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private func dayColumn(_ day: CareWeeklyDay) -> some View {
        let isSelected = selectedDate == day.date

        return Button {
            selectedDate = day.date
        } label: {
            VStack(spacing: 0) {
                Text(day.weekday)
                    .font(.custom("Jua", size: 9, relativeTo: .caption2))
                    .foregroundStyle(CareWeeklyPalette.secondary)
                    .frame(height: 17)

                Text("\(day.date)")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(CareWeeklyPalette.primary)
                    .frame(height: 26)

                careDot(day.hasFeeding, color: CareWeeklyPalette.primary)
                careDot(day.hasWeight, color: CareWeeklyPalette.primary)
                careDot(false, color: CareWeeklyPalette.muted.opacity(0.66))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 142)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.84))
                        .shadow(color: CareWeeklyPalette.shadow, radius: 5, x: 0, y: 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.weekday)요일 \(day.date)일")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("careWeekly.day.\(day.date)")
    }

    private func careDot(_ isRecorded: Bool, color: Color) -> some View {
        Circle()
            .fill(color.opacity(isRecorded ? 1 : 0.3))
            .frame(width: isRecorded ? 11 : 6, height: isRecorded ? 11 : 6)
            .frame(maxWidth: .infinity)
            .frame(height: 31)
            .accessibilityHidden(true)
    }

    private var summaryCards: some View {
        HStack(spacing: 8) {
            summaryCard(title: "급여", value: "3회", identifier: "feeding")
            summaryCard(title: "체중", value: "+1.4 g", identifier: "weight")
            summaryCard(title: "탈피", value: "0회", identifier: "shedding")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("careWeekly.summaryCards")
    }

    private func summaryCard(title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(CareWeeklyPalette.secondary)

            Text(value)
                .font(.custom("Jua", size: 15, relativeTo: .body))
                .foregroundStyle(CareWeeklyPalette.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .padding(.leading, 13)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.42))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: CareWeeklyPalette.shadow, radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("careWeekly.summary.\(identifier)")
    }

    private var sheddingNotice: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("다음 주쯤 탈피가 예상돼요")
                    .font(.custom("Jua", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("습식 은신처를 준비하고 습도를 60%로 맞춰 주세요")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .background(CareWeeklyPalette.forest, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: CareWeeklyPalette.shadow, radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("careWeekly.sheddingNotice")
    }
}

private struct CareWeeklyDay: Identifiable {
    let weekday: String
    let date: Int
    let hasFeeding: Bool
    let hasWeight: Bool

    var id: Int { date }

    static let week = [
        CareWeeklyDay(weekday: "수", date: 14, hasFeeding: true, hasWeight: false),
        CareWeeklyDay(weekday: "목", date: 15, hasFeeding: false, hasWeight: true),
        CareWeeklyDay(weekday: "금", date: 16, hasFeeding: true, hasWeight: false),
        CareWeeklyDay(weekday: "토", date: 17, hasFeeding: false, hasWeight: false),
        CareWeeklyDay(weekday: "일", date: 18, hasFeeding: false, hasWeight: false),
        CareWeeklyDay(weekday: "월", date: 19, hasFeeding: false, hasWeight: false),
        CareWeeklyDay(weekday: "화", date: 20, hasFeeding: true, hasWeight: true)
    ]
}

private enum CareWeeklyPalette {
    static let canvas = Color(.sRGB, red: 250 / 255, green: 247 / 255, blue: 240 / 255, opacity: 1)
    static let forest = Color(.sRGB, red: 47 / 255, green: 107 / 255, blue: 87 / 255, opacity: 1)
    static let primary = Color(.sRGB, red: 43 / 255, green: 42 / 255, blue: 38 / 255, opacity: 1)
    static let secondary = Color(.sRGB, red: 107 / 255, green: 103 / 255, blue: 94 / 255, opacity: 1)
    static let muted = Color(.sRGB, red: 171 / 255, green: 164 / 255, blue: 152 / 255, opacity: 1)
    static let shadow = Color(.sRGB, red: 61 / 255, green: 51 / 255, blue: 41 / 255, opacity: 0.08)
}
