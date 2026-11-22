import SwiftUI

struct CreatureListErrorView: View {
    @State private var isRegistrationPresented = false
    @State private var selectedViewMode: CreatureListErrorViewMode = .list

    /// The retry flow is injected by the owner when its behavior is defined.
    var onRetry: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
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

                    Spacer(minLength: 0)

                    errorState
                        .offset(y: -118)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .bottom) {
                connectionToast
                    .padding(.horizontal, 24)
                    .padding(.bottom, 74)
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
                    .foregroundStyle(CreatureListErrorPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("creatureListError.title")

                Text("등록순 · 7마리")
                    .font(.custom("Jua", size: 12, relativeTo: .caption))
                    .foregroundStyle(CreatureListErrorPalette.secondary)
                    .accessibilityIdentifier("creatureListError.sortCount")
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
                    .background(CreatureListErrorPalette.forest, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("개체 등록")
            .accessibilityIdentifier("creatureListError.registration.plus")
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListError.header")
    }

    private var viewModeControl: some View {
        HStack(spacing: 2) {
            viewModeButton(title: "목록", mode: .list, identifier: "list")
            viewModeButton(title: "휠", mode: .wheel, identifier: "wheel")
        }
        .padding(4)
        .background(.white.opacity(0.48), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListError.mode")
    }

    private func viewModeButton(
        title: String,
        mode: CreatureListErrorViewMode,
        identifier: String
    ) -> some View {
        let isSelected = selectedViewMode == mode

        return Button {
            selectedViewMode = mode
        } label: {
            Text(title)
                .font(.custom("Jua", size: 13, relativeTo: .subheadline))
                .foregroundStyle(
                    isSelected
                        ? CreatureListErrorPalette.primary
                        : CreatureListErrorPalette.tertiary
                )
                .frame(minWidth: mode == .list ? 46 : 42, minHeight: 36)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.94))
                            .shadow(
                                color: CreatureListErrorPalette.shadow,
                                radius: 3,
                                x: 0,
                                y: 2
                            )
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 보기")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("creatureListError.mode.\(identifier)")
    }

    private var errorState: some View {
        VStack(spacing: 0) {
            Circle()
                .stroke(
                    CreatureListErrorPalette.placeholder,
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 6])
                )
                .frame(width: 88, height: 88)
                .accessibilityHidden(true)

            Text("목록을 불러오지 못했어요")
                .font(.custom("Jua", size: 18, relativeTo: .headline))
                .foregroundStyle(CreatureListErrorPalette.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("creatureListError.message.title")

            Text("잠시 후 다시 시도해 주세요")
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(CreatureListErrorPalette.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
                .accessibilityIdentifier("creatureListError.message.subtitle")

            Button {
                onRetry?()
            } label: {
                Text("다시 시도")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(CreatureListErrorPalette.forest)
                    .frame(width: 200, height: 52)
                    .background(.white, in: Capsule())
                    .shadow(color: CreatureListErrorPalette.shadow, radius: 12, x: 0, y: 6)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .accessibilityIdentifier("creatureListError.retry")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureListError.state")
    }

    private var connectionToast: some View {
        Text("인터넷 연결을 확인해 주세요")
            .font(.custom("Jua", size: 13, relativeTo: .body))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 38)
            .background(Color.black.opacity(0.86), in: Capsule())
            .accessibilityIdentifier("creatureListError.connectionToast")
    }
}

private enum CreatureListErrorPalette {
    static let forest = Color(rgb: 0x2F6B57)
    static let primary = Color(rgb: 0x2B2A26)
    static let secondary = Color(rgb: 0x6B675E)
    static let tertiary = Color(rgb: 0x736E65)
    static let placeholder = Color(rgb: 0xDED9CC)
    static let shadow = Color(rgb: 0x3D3329).opacity(0.12)
}

private enum CreatureListErrorViewMode {
    case list
    case wheel
}

private extension Color {
    init(rgb: UInt) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }
}
