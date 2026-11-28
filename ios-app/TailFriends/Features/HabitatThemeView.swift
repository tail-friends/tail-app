import SwiftUI

struct HabitatThemeView: View {
    @Environment(\.dismiss) private var dismiss
    private let onBack: (() -> Void)?
    @State private var showsUnavailableToast = false

    private let themes = HabitatTheme.allCases
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        ZStack(alignment: .top) {
            HabitatThemePalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationHeader
                    .padding(.top, 4)

                Text("개체 상세 맨 위 사육장 배경이 바뀌어요")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(HabitatThemePalette.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 17)
                    .padding(.bottom, 20)

                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    ForEach(themes) { theme in
                        themeCard(theme)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)

            if showsUnavailableToast {
                Text("준비 중")
                    .font(.custom("Jua", size: 13, relativeTo: .body))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .background(Color.black.opacity(0.76), in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 34)
                    .transition(.opacity)
                    .accessibilityIdentifier("habitatTheme.toast")
            }
        }
        .preferredColorScheme(.light)
    }

    private var navigationHeader: some View {
        ZStack {
            VStack(spacing: 8) {
                Capsule()
                    .fill(HabitatThemePalette.pink)
                    .frame(width: 28, height: 2)
                Text("사육장 테마")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(HabitatThemePalette.title)
            }

            HStack {
                Button {
                    if let onBack { onBack() } else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HabitatThemePalette.title)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
                .accessibilityIdentifier("habitatTheme.back")

                Spacer()
            }
        }
        .frame(height: 60)
    }

    private func themeCard(_ theme: HabitatTheme) -> some View {
        Button {
            guard theme != .desert else { return }
            withAnimation(.easeInOut(duration: 0.2)) { showsUnavailableToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.2)) { showsUnavailableToast = false }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(HabitatThemePalette.imageWell)
                    Image(systemName: theme == .customPhoto ? "photo" : "photo")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(HabitatThemePalette.imageMark)
                }
                .frame(height: 91)

                HStack(spacing: 4) {
                    Text(theme.title)
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text(theme.status)
                        .font(.custom("Jua", size: 10, relativeTo: .caption2))
                        .fixedSize()
                }
                .foregroundStyle(HabitatThemePalette.title)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(HabitatThemePalette.border.opacity(theme == .desert ? 0.0 : 0.5), lineWidth: 1)
            }
            .opacity(theme.isAvailable ? 1 : 0.45)
            .frame(height: 145)
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.title), \(theme.status)")
        .accessibilityIdentifier("habitatTheme.\(theme.rawValue)")
    }
}

private enum HabitatTheme: String, CaseIterable, Identifiable {
    case desert, rainforest, rockyCanyon, waterside, moonlitNight, customPhoto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .desert: "사막"
        case .rainforest: "열대우림"
        case .rockyCanyon: "바위 협곡"
        case .waterside: "물가"
        case .moonlitNight: "달밤"
        case .customPhoto: "내 사육장 사진으로"
        }
    }

    var status: String {
        switch self {
        case .desert: "사용 중"
        case .customPhoto: "확장"
        default: "미리보기"
        }
    }

    var isAvailable: Bool { self == .desert }
}

private enum HabitatThemePalette {
    static let background = LinearGradient(
        colors: [Color(red: 0.99, green: 0.98, blue: 0.95), Color(red: 0.96, green: 0.97, blue: 0.91), Color(red: 0.99, green: 0.98, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let title = Color(red: 0.16, green: 0.16, blue: 0.14)
    static let tertiary = Color(red: 115 / 255, green: 110 / 255, blue: 101 / 255)
    static let imageWell = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255).opacity(0.9)
    static let imageMark = Color(red: 0.70, green: 0.67, blue: 0.61)
    static let border = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255)
    static let pink = Color(red: 0.94, green: 0.28, blue: 0.70)
}
