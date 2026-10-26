import SwiftUI

struct LoginView: View {
    var body: some View {
        GeometryReader { geometry in
            let topInset = geometry.safeAreaInsets.top
            let bottomShift = max(0, geometry.safeAreaInsets.bottom - 24)
            let isCompactHeight = geometry.size.height < 750
            let characterTopGap = isCompactHeight ? 72 : max(96, 244 - topInset - bottomShift)
            let characterSlotHeight = isCompactHeight ? 48 : 94.5
            let brandGapHeight = isCompactHeight ? 32 : 72.75
            let providerGapHeight: CGFloat = isCompactHeight ? 88 : 170

            ZStack(alignment: .top) {
                Color(hex: 0xFAF7F0)
                    .ignoresSafeArea()

                Image("login_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: characterTopGap)

                        Color.clear
                            .frame(width: 63, height: characterSlotHeight)
                            .accessibilityHidden(true)

                        Color.clear
                            .frame(height: brandGapHeight)

                        brand

                        Color.clear
                            .frame(height: providerGapHeight)

                        providerButtons

                        Color.clear
                            .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .padding(.horizontal, 26)
                }
                .accessibilityIdentifier("login.scroll")
            }
        }
        .preferredColorScheme(.light)
    }

    private var brand: some View {
        VStack(spacing: 15) {
            Text("Tail")
                .font(.custom("Jua", size: 24, relativeTo: .title2))
                .foregroundStyle(Color(hex: 0x2B2A26))
                .frame(minHeight: 32)
                .accessibilityIdentifier("login.brand")

            Text("기록할수록 닮아가는 나의 파충류")
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(Color(hex: 0x6B675E))
                .frame(minHeight: 19)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("login.tagline")
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 73)
    }

    private var providerButtons: some View {
        VStack(spacing: 8) {
            LoginProviderButton(
                title: "Apple로 계속하기",
                identifier: "login.apple.button",
                provider: .apple,
                background: Color(hex: 0x2F6B57),
                foreground: .white
            )

            LoginProviderButton(
                title: "카카오로 계속하기",
                identifier: "login.kakao.button",
                provider: .kakao,
                background: Color(hex: 0xFEE500),
                foreground: Color(hex: 0x3B3631)
            )

            LoginProviderButton(
                title: "Google로 계속하기",
                identifier: "login.google.button",
                provider: .google,
                background: .white,
                foreground: Color(hex: 0x3B3631),
                border: Color(hex: 0xDEDAD2)
            )

            Text("계속하면 이용약관 및 개인정보처리방침에 동의하게 됩니다")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(Color(hex: 0x736E65))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 0)
                .accessibilityIdentifier("login.terms")
        }
        .frame(maxWidth: 342)
    }
}

private struct LoginProviderButton: View {
    let title: String
    let identifier: String
    let provider: Provider
    let background: Color
    let foreground: Color
    var border: Color? = nil

    var body: some View {
        Button(action: {}) {
            ZStack {
                Text(title)
                    .font(.custom("Jua", size: 14, relativeTo: .body))
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                HStack {
                    icon
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(background, in: Capsule())
            .overlay {
                if let border {
                    Capsule()
                        .strokeBorder(border, lineWidth: 1)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
        .frame(minHeight: 50)
    }

    @ViewBuilder
    private var icon: some View {
        switch provider {
        case .apple:
            Image("social_apple")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)
        case .kakao:
            Image("social_kakao")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)
        case .google:
            Image("social_google")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)
        }
    }

    enum Provider {
        case apple
        case kakao
        case google
    }
}

private extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
