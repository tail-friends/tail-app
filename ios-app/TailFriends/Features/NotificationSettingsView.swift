import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedingEnabled = true
    @State private var sheddingEnabled = true
    @State private var weightEnabled = false
    @State private var growthNewsEnabled = true
    @State private var eventNewsEnabled = false
    @State private var feedingTime = Calendar.current.date(
        from: DateComponents(hour: 20, minute: 0)
    ) ?? .now
    @State private var quietStart = Calendar.current.date(
        from: DateComponents(hour: 22, minute: 0)
    ) ?? .now
    @State private var quietEnd = Calendar.current.date(
        from: DateComponents(hour: 8, minute: 0)
    ) ?? .now
    @State private var activeTimeSheet: NotificationTimeSheet?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NotificationPalette.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    navigationHeader
                        .padding(.top, 4)
                        .padding(.bottom, 34)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            section(title: "돌봄 알림") {
                                NotificationCard {
                                    VStack(spacing: 0) {
                                        toggleRow(
                                            title: "급여 알림",
                                            subtitle: "급여 주기에 맞춰 알려드려요",
                                            isOn: $feedingEnabled,
                                            identifier: "notification.feeding"
                                        )
                                        divider
                                        timeRow(
                                            title: "알림 시간",
                                            value: feedingTime.formatted(
                                                .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits)
                                            ),
                                            identifier: "notification.feedingTime"
                                        ) {
                                            activeTimeSheet = .feeding
                                        }
                                        divider
                                        toggleRow(
                                            title: "탈피 예정 알림",
                                            subtitle: "예상일 3일 전",
                                            isOn: $sheddingEnabled,
                                            identifier: "notification.shedding"
                                        )
                                        divider
                                        toggleRow(
                                            title: "체중 측정 알림",
                                            subtitle: "매주 화요일",
                                            isOn: $weightEnabled,
                                            identifier: "notification.weight"
                                        )
                                    }
                                }
                            }

                            section(title: "소식") {
                                NotificationCard {
                                    VStack(spacing: 0) {
                                        toggleRow(
                                            title: "캐릭터 성장 소식",
                                            isOn: $growthNewsEnabled,
                                            identifier: "notification.growthNews"
                                        )
                                        divider
                                        toggleRow(
                                            title: "이벤트·혜택",
                                            isOn: $eventNewsEnabled,
                                            identifier: "notification.events"
                                        )
                                    }
                                }
                            }

                            section(title: "방해 금지") {
                                NotificationCard {
                                    Button {
                                        activeTimeSheet = .quietHours
                                    } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("방해 금지 시간")
                                                    .font(.custom("Jua", size: 14, relativeTo: .body))
                                                    .foregroundStyle(NotificationPalette.title)
                                                Text("이 시간에는 알림을 보내지 않아요")
                                                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                                                    .foregroundStyle(NotificationPalette.secondary)
                                            }

                                            Spacer(minLength: 0)

                                            Text("\(quietStart.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))) – \(quietEnd.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))")
                                                .font(.custom("Jua", size: 13, relativeTo: .body))
                                                .foregroundStyle(NotificationPalette.secondary)
                                                .fixedSize()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(NotificationPalette.secondary)
                                        }
                                        .frame(minHeight: 72)
                                        .padding(.horizontal, 20)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("방해 금지 시간, \(quietStart.formatted(date: .omitted, time: .shortened))부터 \(quietEnd.formatted(date: .omitted, time: .shortened))까지")
                                    .accessibilityIdentifier("notification.quietHours")
                                }
                            }
                        }
                        .padding(.bottom, 28)
                    }
                    .accessibilityIdentifier("notification.scroll")
                }
                .frame(maxWidth: 342)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 24)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .preferredColorScheme(.light)
        .sheet(item: $activeTimeSheet) { sheet in
            timePickerSheet(sheet)
                .presentationDetents([.height(sheet == .feeding ? 330 : 620)])
                .presentationDragIndicator(.visible)
        }
    }

    private var navigationHeader: some View {
        ZStack {
            VStack(spacing: 8) {
                Capsule()
                    .fill(NotificationPalette.pink)
                    .frame(width: 28, height: 2)
                Text("알림 설정")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(NotificationPalette.title)
            }

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NotificationPalette.title)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
                .accessibilityIdentifier("notification.back")

                Spacer()
            }
        }
        .frame(height: 60)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(NotificationPalette.pink)
                .frame(width: 28, height: 2)
                .offset(y: 10)
                .accessibilityHidden(true)
        }
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.custom("Jua", size: 12, relativeTo: .caption))
                .foregroundStyle(NotificationPalette.secondary)
                .padding(.leading, 0)
            content()
        }
        .accessibilityElement(children: .contain)
    }

    private func toggleRow(
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        identifier: String
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Jua", size: 14, relativeTo: .body))
                    .foregroundStyle(NotificationPalette.title)
                if let subtitle {
                    Text(subtitle)
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(NotificationPalette.secondary)
                }
            }
            Spacer(minLength: 0)
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(NotificationPalette.toggleOn)
                .accessibilityLabel(title)
                .accessibilityIdentifier(identifier)
                .frame(minWidth: 44, minHeight: 44)
        }
        .frame(minHeight: subtitle == nil ? 52 : 70)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
    }

    private func timeRow(title: String, value: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.custom("Jua", size: 14, relativeTo: .body))
                    .foregroundStyle(NotificationPalette.title)
                Spacer()
                Text(value)
                    .font(.custom("Jua", size: 14, relativeTo: .body))
                    .foregroundStyle(NotificationPalette.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NotificationPalette.secondary)
            }
            .frame(minHeight: 54)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var divider: some View {
        Rectangle()
            .fill(NotificationPalette.divider)
            .frame(height: 1)
            .padding(.horizontal, 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func timePickerSheet(_ sheet: NotificationTimeSheet) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(sheet == .feeding ? "알림 시간" : "방해 금지 시간")
                    .font(.custom("Jua", size: 18, relativeTo: .title3))
                    .foregroundStyle(NotificationPalette.title)
                Spacer()
                Button("완료") { activeTimeSheet = nil }
                    .font(.custom("Jua", size: 15, relativeTo: .body))
                    .foregroundStyle(NotificationPalette.toggleOn)
                    .accessibilityIdentifier("notification.time.done")
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            if sheet == .feeding {
                DatePicker("알림 시간", selection: $feedingTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .accessibilityIdentifier("notification.time.feedingPicker")
            } else {
                VStack(spacing: 0) {
                    DatePicker("시작", selection: $quietStart, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .accessibilityIdentifier("notification.time.quietStartPicker")
                    DatePicker("종료", selection: $quietEnd, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .accessibilityIdentifier("notification.time.quietEndPicker")
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NotificationPalette.background.ignoresSafeArea())
    }
}

private struct NotificationCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(.white.opacity(0.91))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: Color(red: 0.33, green: 0.29, blue: 0.18).opacity(0.08), radius: 16, x: 0, y: 10)
    }
}

private enum NotificationTimeSheet: String, Identifiable {
    case feeding
    case quietHours

    var id: String { rawValue }
}

private enum NotificationPalette {
    static let background = LinearGradient(
        colors: [Color(red: 0.99, green: 0.98, blue: 0.95), Color(red: 0.96, green: 0.97, blue: 0.91), Color(red: 0.99, green: 0.98, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let title = Color(red: 0.16, green: 0.16, blue: 0.14)
    static let secondary = Color(red: 0.48, green: 0.47, blue: 0.42)
    static let divider = Color(red: 0.87, green: 0.85, blue: 0.79).opacity(0.65)
    static let toggleOn = Color(red: 0.19, green: 0.43, blue: 0.36)
    static let pink = Color(red: 0.94, green: 0.28, blue: 0.70)
}
