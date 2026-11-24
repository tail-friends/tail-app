import SwiftUI

@main
struct TailFriendsApp: App {
    var body: some Scene {
        WindowGroup {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-care-weekly") {
                MainTabHostView(initialTab: .records, startsWithCareWeekly: true)
            } else if ProcessInfo.processInfo.arguments.contains("--preview-care-calendar") {
                MainTabHostView(initialTab: .records, startsWithCareCalendar: true)
            } else if ProcessInfo.processInfo.arguments.contains("--preview-record-list") {
                MainTabHostView(initialTab: .habitat, startsWithRecordList: true)
            } else if ProcessInfo.processInfo.arguments.contains("--preview-care-dial") {
                MainTabHostView(initialTab: .records)
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-list-empty") {
                MainTabHostView(initialTab: .pets)
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-list-loading") {
                MainTabHostView(
                    initialTab: .pets,
                    showsCreatureListLoadingPreview: true,
                    automaticallyAdvances: !ProcessInfo.processInfo.arguments
                        .contains("--preview-creature-list-loading-static")
                )
            } else if ProcessInfo.processInfo.arguments.contains("--preview-registration") {
                RegistrationView()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-detail-record-empty") {
                CreatureDetailRecordEmptyPreviewHost()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-detail-feeding") {
                CreatureDetailFeedingPreviewHost()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-detail-record-delete") {
                CreatureDetailRecordDeletePreviewHost()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-detail-health-warning") {
                CreatureDetailHealthWarningPreviewHost()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-feeding-record") {
                FeedingRecordView()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-home") {
                HomeView()
            } else {
                LoginView()
            }
#else
            LoginView()
#endif
        }
    }
}

enum MainTab: String {
    case habitat
    case records
    case pets
    case profile

    var title: String {
        switch self {
        case .habitat: "사육장"
        case .records: "기록"
        case .pets: "내 아이들"
        case .profile: "마이"
        }
    }

    var icon: String {
        switch self {
        case .habitat: "icon/home"
        case .records: "icon/record"
        case .pets: "icon/egg"
        case .profile: "icon/user"
        }
    }
}

private struct MainTabHostView: View {
    @State private var selectedTab: MainTab
    @State private var isCareWeeklyVisible: Bool
    @State private var isCareCalendarVisible: Bool
    @State private var isRecordListVisible: Bool
    @State private var careCalendarOrigin: CareCalendarOrigin
    @State private var isUnavailableNoticePresented = false
    @State private var unavailableNoticeMessage = ""
    private let showsCreatureListLoadingPreview: Bool
    private let automaticallyAdvances: Bool

    init(
        initialTab: MainTab,
        showsCreatureListLoadingPreview: Bool = false,
        automaticallyAdvances: Bool = true,
        startsWithCareWeekly: Bool = false,
        startsWithCareCalendar: Bool = false,
        startsWithRecordList: Bool = false
    ) {
        _selectedTab = State(initialValue: initialTab)
        _isCareWeeklyVisible = State(initialValue: startsWithCareWeekly)
        _isCareCalendarVisible = State(initialValue: startsWithCareCalendar)
        _isRecordListVisible = State(initialValue: startsWithRecordList)
        _careCalendarOrigin = State(initialValue: startsWithCareWeekly ? .weekly : .today)
        self.showsCreatureListLoadingPreview = showsCreatureListLoadingPreview
        self.automaticallyAdvances = automaticallyAdvances
    }

    private var navigationAccessibilityPrefix: String {
        switch selectedTab {
        case .habitat: "home.bottomNavigation"
        case .records: "feeding.bottomNavigation"
        case .pets: "creatureList.bottomNavigation"
        case .profile: "main.bottomNavigation"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if isRecordListVisible {
                        RecordListView(onBack: returnFromRecordList)
                    } else {
                        HomeView(
                            showsBottomNavigation: false,
                            onAllRecordsTap: showRecordList
                        )
                    }
                }
                    .opacity(selectedTab == .habitat ? 1 : 0)
                    .allowsHitTesting(selectedTab == .habitat)
                    .accessibilityHidden(selectedTab != .habitat)

                Group {
                    if isCareCalendarVisible {
                        CareCalendarView(onBack: returnFromCareCalendar)
                    } else if isCareWeeklyVisible {
                        CareWeeklyView(
                            onTodayTap: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    isCareWeeklyVisible = false
                                }
                            },
                            onCalendarTap: {
                                showCareCalendar(from: .weekly)
                            }
                        )
                    } else {
                        CareDialView(onDestinationTap: handleCareDialDestination)
                    }
                }
                    .opacity(selectedTab == .records ? 1 : 0)
                    .allowsHitTesting(selectedTab == .records)
                    .accessibilityHidden(selectedTab != .records)

                Group {
                    if showsCreatureListLoadingPreview {
                        CreatureListLoadingView(automaticallyAdvances: automaticallyAdvances)
                    } else {
                        CreatureListEmptyView(showsBottomNavigation: false)
                    }
                }
                    .opacity(selectedTab == .pets ? 1 : 0)
                    .allowsHitTesting(selectedTab == .pets)
                    .accessibilityHidden(selectedTab != .pets)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.18), value: selectedTab)
            .animation(.easeInOut(duration: 0.18), value: isRecordListVisible)
            .overlay(alignment: .bottom) {
                if !isCareCalendarVisible && !isRecordListVisible {
                    MainTabBar(
                        selectedTab: $selectedTab,
                        accessibilityPrefix: navigationAccessibilityPrefix,
                        onUnavailableTabTap: showUnavailableNotice(for:)
                    )
                    .padding(.horizontal, 24)
                    .offset(y: geometry.safeAreaInsets.bottom - 24)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .alert("준비 중", isPresented: $isUnavailableNoticePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(unavailableNoticeMessage)
        }
        .preferredColorScheme(.light)
    }

    private func showUnavailableNotice(for tab: MainTab) {
        unavailableNoticeMessage = "마이 화면은 준비 중이에요."
        isUnavailableNoticePresented = true
    }

    private func showCareDialDestinationNotice(_ destination: CareDialDestination) {
        unavailableNoticeMessage = destination.noticeMessage
        isUnavailableNoticePresented = true
    }

    private func showRecordList() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isRecordListVisible = true
        }
    }

    private func returnFromRecordList() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isRecordListVisible = false
        }
    }

    private func showCareCalendar(from origin: CareCalendarOrigin) {
        careCalendarOrigin = origin
        withAnimation(.easeInOut(duration: 0.18)) {
            isCareCalendarVisible = true
        }
    }

    private func returnFromCareCalendar() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isCareCalendarVisible = false
            isCareWeeklyVisible = careCalendarOrigin == .weekly
        }
    }

    private func handleCareDialDestination(_ destination: CareDialDestination) {
        switch destination {
        case .week:
            withAnimation(.easeInOut(duration: 0.18)) {
                isCareWeeklyVisible = true
            }
        case .calendar:
            showCareCalendar(from: .today)
        case .feeding:
            showCareDialDestinationNotice(destination)
        }
    }

    private enum CareCalendarOrigin {
        case today
        case weekly
    }
}

private struct MainTabBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selectedTab: MainTab
    let accessibilityPrefix: String
    let onUnavailableTabTap: (MainTab) -> Void

    private var minimumHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 82 : 54
    }

    var body: some View {
        HStack(spacing: 8) {
            tabButton(.habitat)
            tabButton(.records)
            tabButton(.pets)
            tabButton(.profile)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: 342, minHeight: minimumHeight)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
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
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: Color(red: 0.24, green: 0.20, blue: 0.16).opacity(0.12), radius: 16, x: 0, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityPrefix)
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            switch tab {
            case .habitat, .records, .pets:
                selectedTab = tab
            case .profile:
                onUnavailableTabTap(tab)
            }
        } label: {
            VStack(spacing: 2) {
                Image(tab.icon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)

                Text(tab.title)
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? Color(red: 0x2F / 255, green: 0x6B / 255, blue: 0x57 / 255) : Color(red: 0x73 / 255, green: 0x6E / 255, blue: 0x65 / 255))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white.opacity(0.88))
                        .shadow(color: Color(red: 0.24, green: 0.20, blue: 0.16).opacity(0.12), radius: 3, x: 1, y: 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("\(accessibilityPrefix).\(tab.rawValue)")
    }
}

#if DEBUG
private struct CreatureDetailRecordEmptyPreviewHost: View {
    @State private var isDetailPresented = true

    var body: some View {
        Group {
            if isDetailPresented {
                CreatureDetailRecordEmptyView(onBack: { isDetailPresented = false })
            } else {
                HomeView()
            }
        }
    }
}

private struct CreatureDetailFeedingPreviewHost: View {
    @State private var isDetailPresented = true

    var body: some View {
        Group {
            if isDetailPresented {
                CreatureDetailFeedingFormView(onBack: { isDetailPresented = false })
            } else {
                HomeView()
            }
        }
    }
}

private struct CreatureDetailRecordDeletePreviewHost: View {
    @State private var isDetailPresented = true

    var body: some View {
        Group {
            if isDetailPresented {
                CreatureDetailRecordDeleteView(onBack: { isDetailPresented = false })
            } else {
                HomeView()
            }
        }
    }
}

private struct CreatureDetailHealthWarningPreviewHost: View {
    @State private var isDetailPresented = true

    var body: some View {
        Group {
            if isDetailPresented {
                CreatureDetailRecordDeleteView(
                    onBack: { isDetailPresented = false },
                    showsHealthWarning: true
                )
            } else {
                HomeView()
            }
        }
    }
}
#endif
