import SwiftUI

struct RegistrationView: View {
    private let contentWidth: CGFloat = 342

    var body: some View {
        ZStack {
            RegistrationPalette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        nameSection
                            .padding(.bottom, 22)

                        speciesSection
                            .padding(.bottom, 22)

                        morphSection
                            .padding(.bottom, 22)

                        sexSection
                            .padding(.bottom, 22)

                        hatchDateSection
                            .padding(.bottom, 22)

                        feedingIntervalSection
                            .padding(.bottom, 22)

                        memoSection
                            .padding(.bottom, 20)

                        photoSection
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("registration.scroll")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveActionPreview
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background {
                    LinearGradient(
                        colors: [
                            RegistrationPalette.backgroundTop.opacity(0.94),
                            RegistrationPalette.backgroundBottom.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
        }
        .preferredColorScheme(.light)
    }

    private var navigationHeader: some View {
        HStack(spacing: 0) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RegistrationPalette.primary)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            Spacer(minLength: 0)
        }
        .overlay {
            Text("새 친구 등록")
                .font(.custom("Jua", size: 15, relativeTo: .headline))
                .foregroundStyle(RegistrationPalette.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 24)
        .padding(.top, 2)
        .frame(maxWidth: .infinity, minHeight: 48)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("registration.header")
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("이름", required: true)

            FormFieldSurface(value: "욱이")

            characterCount("2/30")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("이름, 필수, 욱이, 2/30, 미리보기")
    }

    private var speciesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("종", required: true)

            FormFieldSurface(value: "레오파드 게코", trailingSymbol: "chevron.right")

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .medium))
                    .accessibilityHidden(true)

                Text("종별 사육 계획으로 급여 주기·체형·테마를 채웠어요")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(RegistrationPalette.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(RegistrationPalette.note, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("종, 필수, 레오파드 게코, 종별 사육 계획 안내, 미리보기")
    }

    private var morphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("모프 / 특징")

            FormFieldSurface(value: "탠저린 · 꼬리 재생")

            characterCount("9/40")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("모프 및 특징, 탠저린 · 꼬리 재생, 9/40, 미리보기")
    }

    private var sexSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("성별")

            HStack(spacing: 4) {
                sexOption("수컷", selected: true)
                sexOption("암컷", selected: false)
                sexOption("미구분", selected: false)
            }
            .padding(4)
            .background(RegistrationPalette.controlTrack, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("성별, 수컷 선택, 암컷, 미구분, 미리보기")
        }
    }

    private var hatchDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("해칭일")

            FormFieldSurface(value: "2024.07.12", trailingSymbol: "chevron.right")

            Text("생후 2년 3개월")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(RegistrationPalette.secondary)
                .padding(.top, 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("해칭일, 2024년 7월 12일, 생후 2년 3개월, 미리보기")
    }

    private var feedingIntervalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("급여 주기", required: true)

            FormFieldSurface(value: "4", trailingText: "일")

            Text("성체 기준이에요. 해칭 개체나 번식기라면 바꿔 주세요")
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RegistrationPalette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("급여 주기, 필수, 4일, 성체 기준 안내, 미리보기")
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("메모")

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RegistrationPalette.field)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(RegistrationPalette.fieldBorder, lineWidth: 1)
                }
                .frame(minHeight: 92)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("메모 입력 영역, 미리보기")
    }

    private var photoSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(RegistrationPalette.secondary)
                .frame(width: 40, height: 40)
                .background(RegistrationPalette.note, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("사진 추가")
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                    .foregroundStyle(RegistrationPalette.primary)

                Text("저장하면 사진으로 캐릭터를 만들 수 있어요")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RegistrationPalette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(RegistrationPalette.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 68)
        .background(RegistrationPalette.field, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RegistrationPalette.fieldBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("사진 추가, 저장하면 사진으로 캐릭터를 만들 수 있어요, 미리보기")
    }

    private var saveActionPreview: some View {
        Text("저장")
            .font(.custom("Jua", size: 14, relativeTo: .body))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(RegistrationPalette.action, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("저장, 미리보기이며 동작하지 않습니다")
            .accessibilityIdentifier("registration.save.preview")
    }

    private func sectionLabel(_ title: String, required: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                .foregroundStyle(RegistrationPalette.primary)

            if required {
                Text("필수")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(RegistrationPalette.required)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func characterCount(_ value: String) -> some View {
        Text(value)
            .font(.custom("Jua", size: 10, relativeTo: .caption))
            .foregroundStyle(RegistrationPalette.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, -2)
    }

    private func sexOption(_ title: String, selected: Bool) -> some View {
        Text(title)
            .font(.custom("Jua", size: 12, relativeTo: .subheadline))
            .foregroundStyle(selected ? RegistrationPalette.primary : RegistrationPalette.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if selected {
                    Capsule()
                        .fill(RegistrationPalette.selected)
                        .shadow(color: RegistrationPalette.shadow, radius: 3, x: 0, y: 2)
                }
            }
    }
}

private struct FormFieldSurface: View {
    let value: String
    var trailingSymbol: String? = nil
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(value)
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(RegistrationPalette.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if let trailingText {
                Text(trailingText)
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                    .foregroundStyle(RegistrationPalette.secondary)
            }

            if let trailingSymbol {
                Image(systemName: trailingSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RegistrationPalette.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(RegistrationPalette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(RegistrationPalette.fieldBorder, lineWidth: 1)
        }
    }
}

private enum RegistrationPalette {
    static let background = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let backgroundTop = Color(registrationHex: 0xFBFAF8)
    static let backgroundBottom = Color(registrationHex: 0xF4F2EE)
    static let primary = Color(registrationHex: 0x1E1C1A)
    static let secondary = Color(registrationHex: 0x6C665D)
    static let required = Color(registrationHex: 0xB0705F)
    static let field = Color.white.opacity(0.84)
    static let fieldBorder = Color.white.opacity(0.96)
    static let note = Color(registrationHex: 0xF4ECDD)
    static let controlTrack = Color(registrationHex: 0xFFFFFF8C)
    static let selected = Color.white.opacity(0.94)
    static let action = Color(registrationHex: 0x2F6B57)
    static let shadow = Color(registrationHex: 0x3D3329).opacity(0.12)
}

private extension Color {
    init(registrationHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
