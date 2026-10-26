import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedInput: RegistrationInput?

    @State private var name = "욱이"
    @State private var species = "레오파드 게코"
    @State private var morph = "탠저린 · 꼬리 재생"
    @State private var sex: RegistrationSex = .male
    @State private var hatchDate = Calendar.current.date(
        from: DateComponents(year: 2024, month: 7, day: 12)
    ) ?? .now
    @State private var feedingInterval = "4"
    @State private var memo = "온순함, 손을 좋아함"
    @State private var hasEditedMemo = false
    @State private var isDatePickerPresented = false
    @State private var isSaveMessagePresented = false

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
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .accessibilityIdentifier("registration.scroll")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveAction
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background {
                    LinearGradient(
                        colors: [
                            RegistrationPalette.backgroundTop,
                            RegistrationPalette.backgroundBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    focusedInput = nil
                }
                .accessibilityIdentifier("registration.keyboard.done")
            }
        }
        .sheet(isPresented: $isDatePickerPresented) {
            hatchDatePicker
        }
        .alert("저장 미리보기", isPresented: $isSaveMessagePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("입력한 정보는 이 미리보기에서만 유지되며 실제로 저장되지 않습니다.")
        }
        .preferredColorScheme(.light)
    }

    private var navigationHeader: some View {
        HStack(spacing: 0) {
            Button {
                focusedInput = nil
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RegistrationPalette.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")
            .accessibilityIdentifier("registration.back")

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
        .accessibilityIdentifier("registration.header")
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("이름", required: true)

            EditableFormField(
                title: "이름",
                placeholder: "이름을 입력해 주세요",
                text: $name,
                accessibilityIdentifier: "registration.name",
                characterLimit: 30,
                focusedInput: $focusedInput,
                focusValue: .name
            )

            characterCount(name, limit: 30, identifier: "registration.name.count")
        }
    }

    private var speciesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("종", required: true)

            EditableFormField(
                title: "종",
                placeholder: "종을 입력해 주세요",
                text: $species,
                accessibilityIdentifier: "registration.species",
                trailingSymbol: "chevron.right",
                focusedInput: $focusedInput,
                focusValue: .species
            )

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
    }

    private var morphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("모프 / 특징")

            EditableFormField(
                title: "모프 및 특징",
                placeholder: "모프나 특징을 입력해 주세요",
                text: $morph,
                accessibilityIdentifier: "registration.morph",
                characterLimit: 40,
                focusedInput: $focusedInput,
                focusValue: .morph
            )

            characterCount(morph, limit: 40, identifier: "registration.morph.count")
        }
    }

    private var sexSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("성별")

            HStack(spacing: 4) {
                ForEach(RegistrationSex.allCases) { option in
                    sexOption(option)
                }
            }
            .padding(4)
            .background(RegistrationPalette.controlTrack, in: Capsule())
        }
    }

    private var hatchDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("해칭일")

            Button {
                focusedInput = nil
                isDatePickerPresented = true
            } label: {
                FormFieldSurface(
                    value: formattedHatchDate,
                    trailingSymbol: "chevron.right"
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("해칭일, \(formattedHatchDate)")
            .accessibilityIdentifier("registration.hatchDate")

            Text(hatchAgeDescription)
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(RegistrationPalette.secondary)
                .padding(.top, 1)
        }
    }

    private var feedingIntervalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("급여 주기", required: true)

            EditableFormField(
                title: "급여 주기",
                placeholder: "일수 입력",
                text: $feedingInterval,
                accessibilityIdentifier: "registration.feedingInterval",
                trailingText: "일",
                usesNumberPad: true,
                keepsDigitsOnly: true,
                focusedInput: $focusedInput,
                focusValue: .feedingInterval
            )

            Text("성체 기준이에요. 해칭 개체나 번식기라면 바꿔 주세요")
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RegistrationPalette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("메모")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RegistrationPalette.field)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(RegistrationPalette.fieldBorder, lineWidth: 1)
                    }

                if memo.isEmpty {
                    Text("메모를 입력해 주세요")
                        .font(.custom("Jua", size: 12, relativeTo: .body))
                        .foregroundStyle(RegistrationPalette.secondary.opacity(0.72))
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .accessibilityHidden(true)
                }

                TextEditor(text: $memo)
                    .font(.custom("Jua", size: 12, relativeTo: .body))
                    .foregroundStyle(RegistrationPalette.primary)
                    .scrollContentBackground(.hidden)
                    .focused($focusedInput, equals: .memo)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .accessibilityLabel("메모")
                    .accessibilityIdentifier("registration.memo")
            }
            .frame(minHeight: 92)
            .onChange(of: memo) { _, newValue in
                hasEditedMemo = true
                if newValue.count > 300 {
                    memo = String(newValue.prefix(300))
                }
            }

            characterCount(
                memo,
                limit: 300,
                identifier: "registration.memo.count",
                displayCount: hasEditedMemo ? memo.count : 13
            )
        }
    }

    private var saveAction: some View {
        VStack(spacing: 6) {
            Text("저장하면 사진으로 캐릭터를 만들 수 있어요")
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(RegistrationPalette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("registration.save.guidance")

            Button {
                focusedInput = nil
                isSaveMessagePresented = true
            } label: {
                Text("저장")
                    .font(.custom("Jua", size: 14, relativeTo: .body))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RegistrationPalette.action, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("registration.save")
        }
    }

    private var hatchDatePicker: some View {
        NavigationStack {
            DatePicker(
                "해칭일",
                selection: $hatchDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal, 12)
            .accessibilityIdentifier("registration.hatchDate.picker")
            .navigationTitle("해칭일 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isDatePickerPresented = false
                    }
                    .accessibilityIdentifier("registration.hatchDate.cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        isDatePickerPresented = false
                    }
                    .accessibilityIdentifier("registration.hatchDate.done")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var formattedHatchDate: String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: hatchDate)
        guard let year = parts.year, let month = parts.month, let day = parts.day else {
            return ""
        }
        return String(format: "%04d.%02d.%02d", year, month, day)
    }

    private var hatchAgeDescription: String {
        guard hatchDate <= Date() else { return "해칭 예정" }
        let age = Calendar.current.dateComponents([.year, .month], from: hatchDate, to: Date())
        return "생후 \(age.year ?? 0)년 \(age.month ?? 0)개월"
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

    private func characterCount(
        _ value: String,
        limit: Int,
        identifier: String,
        displayCount: Int? = nil
    ) -> some View {
        Text("\(displayCount ?? value.count)/\(limit)")
            .font(.custom("Jua", size: 10, relativeTo: .caption))
            .foregroundStyle(RegistrationPalette.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, -2)
            .accessibilityIdentifier(identifier)
    }

    private func sexOption(_ option: RegistrationSex) -> some View {
        let isSelected = sex == option

        return Button {
            sex = option
        } label: {
            Text(option.title)
                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                .foregroundStyle(isSelected ? RegistrationPalette.primary : RegistrationPalette.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(RegistrationPalette.selected)
                            .shadow(color: RegistrationPalette.shadow, radius: 3, x: 0, y: 2)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("성별 \(option.title)")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("registration.sex.\(option.id)")
    }
}

private struct EditableFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let accessibilityIdentifier: String
    var characterLimit: Int? = nil
    var trailingSymbol: String? = nil
    var trailingText: String? = nil
    var usesNumberPad = false
    var keepsDigitsOnly = false
    @FocusState.Binding var focusedInput: RegistrationInput?
    let focusValue: RegistrationInput

    private var isFocused: Bool {
        focusedInput == focusValue
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField(title, text: $text, prompt: Text(placeholder))
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(RegistrationPalette.primary)
                .textInputAutocapitalization(.never)
                .keyboardType(usesNumberPad ? .numberPad : .default)
                .submitLabel(.done)
                .focused($focusedInput, equals: focusValue)
                .onSubmit { focusedInput = nil }
                .accessibilityLabel(title)
                .accessibilityIdentifier(accessibilityIdentifier)

            if isFocused && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(RegistrationPalette.secondary.opacity(0.72))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title) 지우기")
                .accessibilityIdentifier("\(accessibilityIdentifier).clear")
            }

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
        .onChange(of: text) { _, newValue in
            var updatedValue = newValue

            if keepsDigitsOnly {
                updatedValue = updatedValue.filter(\.isNumber)
            }

            if let characterLimit, updatedValue.count > characterLimit {
                updatedValue = String(updatedValue.prefix(characterLimit))
            }

            if updatedValue != newValue {
                text = updatedValue
            }
        }
    }
}

private struct FormFieldSurface: View {
    let value: String
    var trailingSymbol: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(value)
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(RegistrationPalette.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

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

private enum RegistrationInput: Hashable {
    case name
    case species
    case morph
    case feedingInterval
    case memo
}

private enum RegistrationSex: String, CaseIterable, Identifiable {
    case male
    case female
    case unspecified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "수컷"
        case .female: return "암컷"
        case .unspecified: return "미구분"
        }
    }
}

private enum RegistrationPalette {
    static let background = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let backgroundTop = Color(registrationHex: 0xF8F5F0)
    static let backgroundBottom = Color(registrationHex: 0xE8EAE3)
    static let primary = Color(registrationHex: 0x1E1C1A)
    static let secondary = Color(registrationHex: 0x6C665D)
    static let required = Color(registrationHex: 0xB0705F)
    static let field = Color.white.opacity(0.84)
    static let fieldBorder = Color.white.opacity(0.96)
    static let note = Color.white.opacity(0.75)
    static let controlTrack = Color.white.opacity(0.55)
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
