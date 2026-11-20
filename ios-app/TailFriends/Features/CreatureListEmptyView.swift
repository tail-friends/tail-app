import SwiftUI

struct CreatureListEmptyView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isRegistrationPresented = false
    @State private var selectedViewMode: CreatureListViewMode = .list
    var showsBottomNavigation = true

    private var navigationMinimumHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 82 : 54
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CreatureListPalette.canvas
                    .ignoresSafeArea()

                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 6)

                    Spacer(minLength: 20)

                    emptyState
                        .offset(y: -102)

                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .bottom) {
                if showsBottomNavigation {
                    bottomNavigation
                        .padding(.horizontal, 24)
                        .offset(y: geometry.safeAreaInsets.bottom - 24)
                        .frame(maxWidth: .infinity)
                }
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
                    .font(.custom("Jua", size: 22, relativeTo: .title2))
                    .foregroundStyle(CreatureListPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("creatureList.title")

                Text("등록순 · 7마리")
                    .font(.custom("Jua", size: 12, relativeTo: .caption))
                    .foregroundStyle(CreatureListPalette.secondary)
                    .accessibilityIdentifier("creatureList.sortCount")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            viewModeControl

            Button {
                isRegistrationPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(CreatureListPalette.forest, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("개체 등록")
            .accessibilityIdentifier("creatureList.registration.plus")
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureList.header")
    }

    private var viewModeControl: some View {
        HStack(spacing: 2) {
            viewModeButton(title: "목록", mode: .list, identifier: "list")
            viewModeButton(title: "휠", mode: .wheel, identifier: "wheel")
        }
        .padding(4)
        .background(.white.opacity(0.48), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureList.mode")
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
                .foregroundStyle(isSelected ? CreatureListPalette.primary : CreatureListPalette.tertiary)
                .frame(minWidth: mode == .list ? 46 : 42, minHeight: 36)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.94))
                            .shadow(color: CreatureListPalette.shadow, radius: 3, x: 0, y: 2)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 보기")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("creatureList.mode.\(identifier)")
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Circle()
                .stroke(
                    CreatureListPalette.placeholder,
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 6])
                )
                .frame(width: 118, height: 118)
                .accessibilityHidden(true)

            Text("첫 개체를 등록해 보세요")
                .font(.custom("Jua", size: 18, relativeTo: .headline))
                .foregroundStyle(CreatureListPalette.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
                .accessibilityIdentifier("creatureList.empty.title")

            Text("이름·종·급여 주기만 있으면 시작할 수 있어요")
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(CreatureListPalette.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .accessibilityIdentifier("creatureList.empty.subtitle")

            Button {
                isRegistrationPresented = true
            } label: {
                Text("개체 등록하기")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(width: 248, height: 60)
                    .background(CreatureListPalette.forest, in: Capsule())
                    .shadow(color: CreatureListPalette.shadow, radius: 14, x: 0, y: 8)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .accessibilityIdentifier("creatureList.empty.register")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureList.emptyState")
    }

    private var bottomNavigation: some View {
        HStack(spacing: 8) {
            navigationItem(title: "사육장", icon: "icon/home", selected: false, identifier: "habitat")
            navigationItem(title: "기록", icon: "icon/record", selected: false, identifier: "records")
            navigationItem(title: "내 아이들", icon: "icon/egg", selected: true, identifier: "pets")
            navigationItem(title: "마이", icon: "icon/user", selected: false, identifier: "profile")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: 342, minHeight: navigationMinimumHeight)
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
        .shadow(color: CreatureListPalette.shadow, radius: 16, x: 0, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureList.bottomNavigation")
    }

    private func navigationItem(
        title: String,
        icon: String,
        selected: Bool,
        identifier: String
    ) -> some View {
        VStack(spacing: 2) {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)

            Text(title)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(selected ? CreatureListPalette.forest : CreatureListPalette.tertiary)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background {
            if selected {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white.opacity(0.88))
                    .shadow(color: CreatureListPalette.shadow, radius: 3, x: 1, y: 2)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("creatureList.bottomNavigation.\(identifier)")
    }
}

private enum CreatureListPalette {
    static let canvas = Color(creatureListHex: 0xFAF7F0)
    static let forest = Color(creatureListHex: 0x2F6B57)
    static let primary = Color(creatureListHex: 0x2B2A26)
    static let secondary = Color(creatureListHex: 0x6B675E)
    static let tertiary = Color(creatureListHex: 0x736E65)
    static let placeholder = Color(creatureListHex: 0xDED9CC)
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
