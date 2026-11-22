import SwiftUI

struct CreatureListLoadingView: View {
    @State private var hasLoaded = false
    @State private var isRegistrationPresented = false
    @State private var selectedViewMode: CreatureListViewMode = .list

    var automaticallyAdvances = true

    var body: some View {
        GeometryReader { _ in
            ZStack {
                CreatureListLoadingPalette.canvas
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)

                    if hasLoaded {
                        loadedList
                            .transition(.opacity)
                            .padding(.top, 18)
                    } else {
                        skeletonList
                            .transition(.opacity)
                            .padding(.top, 18)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .task {
            guard automaticallyAdvances else { return }
            try? await Task.sleep(for: .milliseconds(2_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                hasLoaded = true
            }
        }
        .fullScreenCover(isPresented: $isRegistrationPresented) {
            RegistrationView()
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("내 아이들")
                    .font(.custom("Jua", size: 13, relativeTo: .title3))
                    .foregroundStyle(CreatureListLoadingPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("creatureListLoading.title")

                Text("등록순 · 7마리")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(CreatureListLoadingPalette.secondary)
                    .accessibilityIdentifier("creatureListLoading.sortCount")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            viewModeControl

            Button {
                isRegistrationPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .frame(width: 36, height: 36)
                    .background(CreatureListLoadingPalette.forest, in: Circle())
                    .contentShape(Circle())
                    .padding(4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("개체 등록")
            .accessibilityIdentifier("creatureListLoading.registration.plus")
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListLoading.header")
    }

    private var viewModeControl: some View {
        HStack(spacing: 2) {
            viewModeButton(title: "목록", mode: .list, identifier: "list")
            viewModeButton(title: "휠", mode: .wheel, identifier: "wheel")
        }
        .padding(3)
        .frame(width: 77, height: 34)
        .background(.white.opacity(0.48), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListLoading.mode")
    }

    private func viewModeButton(
        title: String,
        mode: CreatureListViewMode,
        identifier: String
    ) -> some View {
        let isSelected = selectedViewMode == mode

        return Button {
            selectedViewMode = mode
        } label: {
            Text(title)
                .font(.custom("Jua", size: 13, relativeTo: .subheadline))
                .foregroundStyle(isSelected ? CreatureListLoadingPalette.primary : CreatureListLoadingPalette.tertiary)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.94))
                            .shadow(color: CreatureListLoadingPalette.shadow, radius: 3, x: 0, y: 2)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 보기")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("creatureListLoading.mode.\(identifier)")
    }

    private var skeletonList: some View {
        VStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                CreatureListSkeletonCard()
                    .accessibilityIdentifier("creatureListLoading.skeleton.\(index)")
            }
        }
        .frame(width: 342, height: 508, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListLoading.skeletonList")
    }

    private var loadedList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(CreatureListPreviewEntry.samples) { entry in
                    CreatureListPreviewCard(entry: entry)
                }
            }
            .frame(width: 342)
            .padding(.bottom, 112)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("creatureListLoading.loadedList")
    }

}

private struct CreatureListSkeletonCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(CreatureListLoadingPalette.skeleton)
                .frame(width: 48, height: 48)
                .opacity(0.6)

            VStack(spacing: 8) {
                Capsule()
                    .fill(CreatureListLoadingPalette.skeleton)
                    .frame(width: 90, height: 10)
                    .opacity(0.6)

                Capsule()
                    .fill(CreatureListLoadingPalette.skeleton)
                    .frame(width: 150, height: 10)
                    .opacity(0.6)
            }
            .frame(width: 248, height: 28, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 342, height: 78)
        .background(CreatureListLoadingPalette.canvas, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(CreatureListLoadingPalette.canvas, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("개체 목록 불러오는 중")
    }
}

private struct CreatureListPreviewCard: View {
    let entry: CreatureListPreviewEntry

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.avatarToken.fill)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(entry.initial)
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .tracking(-0.1)
                        .foregroundStyle(.white)
                        .frame(height: 16)
                }
                .overlay {
                    if entry.avatarToken.hasWhiteBorder {
                        Circle()
                            .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    }
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(entry.name)
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .tracking(-0.1)
                        .foregroundStyle(CreatureListLoadingPalette.primary)
                        .frame(minHeight: 19, alignment: .center)
                        .accessibilityIdentifier("creatureListLoading.card.\(entry.id).name")

                    Text(entry.species)
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(CreatureListLoadingPalette.tertiary)
                        .lineLimit(1)
                        .frame(minHeight: 14, alignment: .center)
                        .accessibilityIdentifier("creatureListLoading.card.\(entry.id).species")
                }

                HStack(spacing: 4) {
                    ForEach(entry.statuses) { status in
                        CreatureListStatusLabel(status: status)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.weight)
                    .font(.custom("Jua", size: 13, relativeTo: .body))
                    .tracking(-0.1)
                    .foregroundStyle(CreatureListLoadingPalette.primary)
                    .frame(minHeight: 19, alignment: .trailing)
                    .accessibilityIdentifier("creatureListLoading.card.\(entry.id).weight")

                Text("최근 체중")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(CreatureListLoadingPalette.tertiary)
                    .frame(minHeight: 14, alignment: .trailing)
                    .accessibilityIdentifier("creatureListLoading.card.\(entry.id).weightLabel")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 342, height: 78)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.78), .white.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListLoading.card.\(entry.id)")
    }
}

private struct CreatureListStatusLabel: View {
    let status: CreatureListStatus

    var body: some View {
        if let style = status.style {
            Text(status.title)
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .frame(minHeight: 14, alignment: .center)
                .foregroundStyle(style.foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(style.fill, in: Capsule())
                .accessibilityIdentifier("creatureListLoading.status.\(status.id)")
        } else {
            Text(status.title)
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .frame(minHeight: 14, alignment: .center)
                .accessibilityIdentifier("creatureListLoading.status.\(status.id)")
        }
    }
}

private struct CreatureListPreviewEntry: Identifiable {
    let id: Int
    let name: String
    let initial: String
    let avatarToken: CreatureListAvatarToken
    let species: String
    let weight: String
    let statuses: [CreatureListStatus]

    static let samples = [
        CreatureListPreviewEntry(
            id: 1,
            name: "욱이",
            initial: "욱",
            avatarToken: .forest,
            species: "레오파드 게코 · 탠저린",
            weight: "53.4g",
            statuses: [.todayFeeding]
        ),
        CreatureListPreviewEntry(
            id: 2,
            name: "치토",
            initial: "치",
            avatarToken: .forest,
            species: "비어디드 드래곤 · 하이포",
            weight: "412g",
            statuses: [.dueTomorrow, .weightDrop]
        ),
        CreatureListPreviewEntry(
            id: 3,
            name: "레오",
            initial: "레",
            avatarToken: .forest,
            species: "크레스티드 게코 · 할리퀸",
            weight: "38.2g",
            statuses: [.overdue]
        ),
        CreatureListPreviewEntry(
            id: 4,
            name: "세라",
            initial: "세",
            avatarToken: .forest,
            species: "볼 파이톤 · 바나나",
            weight: "1,240g",
            statuses: [.dueInSixDays]
        ),
        CreatureListPreviewEntry(
            id: 5,
            name: "토토",
            initial: "토",
            avatarToken: .sand400,
            species: "육지거북 · 헤르만",
            weight: "860g",
            statuses: [.hibernating]
        ),
        CreatureListPreviewEntry(
            id: 6,
            name: "루비",
            initial: "루",
            avatarToken: .forest,
            species: "콘스네이크 · 아멜",
            weight: "—",
            statuses: [.noRecord]
        ),
        CreatureListPreviewEntry(
            id: 7,
            name: "하루",
            initial: "하",
            avatarToken: .forest,
            species: "펫테일 게코",
            weight: "46.0g",
            statuses: [.dueInTwoDays]
        )
    ]
}

private enum CreatureListAvatarToken: Equatable {
    case forest
    case sand400

    var fill: Color {
        switch self {
        case .forest: CreatureListLoadingPalette.forest
        case .sand400: CreatureListLoadingPalette.sand400
        }
    }

    var hasWhiteBorder: Bool {
        self == .forest
    }
}

private struct CreatureListStatus: Identifiable {
    let id: String
    let title: String
    let style: CreatureListStatusStyle?

    static let todayFeeding = CreatureListStatus(
        id: "todayFeeding",
        title: "오늘 급여",
        style: CreatureListStatusStyle(fill: Color(creatureListHex: 0xFBEBD3), foreground: Color(creatureListHex: 0x96570C))
    )
    static let dueTomorrow = CreatureListStatus(
        id: "dueTomorrow",
        title: "D-1",
        style: CreatureListStatusStyle(fill: Color(creatureListHex: 0xE4EEDF), foreground: Color(creatureListHex: 0x336B41))
    )
    static let weightDrop = CreatureListStatus(
        id: "weightDrop",
        title: "체중 12% 감소",
        style: CreatureListStatusStyle(fill: Color(creatureListHex: 0xFBE3DF), foreground: Color(creatureListHex: 0xB23B30))
    )
    static let overdue = CreatureListStatus(
        id: "overdue",
        title: "2일 지남",
        style: CreatureListStatusStyle(fill: Color(creatureListHex: 0xFBE3DF), foreground: Color(creatureListHex: 0xB23B30))
    )
    static let dueInSixDays = CreatureListStatus(
        id: "dueInSixDays",
        title: "D-6",
        style: CreatureListStatusStyle(fill: Color(creatureListHex: 0xE4EEDF), foreground: Color(creatureListHex: 0x336B41))
    )
    static let hibernating = CreatureListStatus(id: "hibernating", title: "휴면 중", style: nil)
    static let noRecord = CreatureListStatus(id: "noRecord", title: "기록 없음", style: nil)
    static let dueInTwoDays = CreatureListStatus(id: "dueInTwoDays", title: "D-2", style: nil)
}

private struct CreatureListStatusStyle {
    let fill: Color
    let foreground: Color
}

private enum CreatureListLoadingPalette {
    static let canvas = Color(creatureListHex: 0xFAF7F0)
    static let forest = Color(creatureListHex: 0x2F6B57)
    static let sand400 = Color(creatureListHex: 0x736E65)
    static let primary = Color(creatureListHex: 0x2B2A26)
    static let secondary = Color(creatureListHex: 0x736E65)
    static let tertiary = Color(creatureListHex: 0x736E65)
    static let skeleton = Color(creatureListHex: 0xE6E1D6)
    static let shadow = Color(creatureListHex: 0x3D3329).opacity(0.12)
}

private enum CreatureListViewMode {
    case list
    case wheel
}

private extension Color {
    init(creatureListHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
