import SwiftUI

struct FeedingRecordEditData {
    var date: Date
    var food: String
    var quantity: Int
    var didNotEat: Bool
    var memo: String

    var listDetail: String {
        let amount = didNotEat ? "안 먹음" : "\(quantity)마리"
        let feeding = didNotEat ? "\(food) · \(amount)" : "\(food) \(amount)"
        let note = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? feeding : "\(feeding) · \(note)"
    }
}

struct FeedingRecordEditView: View {
    let initialData: FeedingRecordEditData
    let onBack: () -> Void
    let onSave: (FeedingRecordEditData) -> Void

    @FocusState private var isMemoFocused: Bool
    @State private var selectedDate: Date
    @State private var selectedFood: String
    @State private var quantity: Int
    @State private var didNotEat: Bool
    @State private var memo: String
    @State private var isDatePickerPresented = false

    private let foodOptions = ["귀뚜라미", "밀웜", "듀비아"]

    init(
        initialData: FeedingRecordEditData,
        onBack: @escaping () -> Void,
        onSave: @escaping (FeedingRecordEditData) -> Void
    ) {
        self.initialData = initialData
        self.onBack = onBack
        self.onSave = onSave
        _selectedDate = State(initialValue: initialData.date)
        _selectedFood = State(initialValue: initialData.food)
        _quantity = State(initialValue: initialData.quantity)
        _didNotEat = State(initialValue: initialData.didNotEat)
        _memo = State(initialValue: initialData.memo)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                EditPalette.canvas
                    .ignoresSafeArea()

                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    navigationHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    recordTypePill
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            formCard

                            Text("저장하면 다음 급여일과 경고를 다시 계산해요")
                                .font(.custom("Jua", size: 10, relativeTo: .caption))
                                .foregroundStyle(EditPalette.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .accessibilityIdentifier("feedingEdit.helper")
                        }
                        .frame(maxWidth: 342)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 84)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                saveButton
                    .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.light)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { isMemoFocused = false }
                    .accessibilityIdentifier("feedingEdit.memo.done")
            }
        }
        .sheet(isPresented: $isDatePickerPresented) {
            datePickerSheet
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
        }
    }

    private var navigationHeader: some View {
        ZStack {
            Text("기록 수정")
                .font(.custom("Jua", size: 14, relativeTo: .subheadline))
                .foregroundStyle(EditPalette.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("feedingEdit.title")

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(EditPalette.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
                .accessibilityIdentifier("feedingEdit.back")

                Spacer()
            }
        }
        .frame(height: 44)
    }

    private var recordTypePill: some View {
        HStack(spacing: 8) {
            Image("icon/feed")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)

            Text("급여")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(EditPalette.primary)

            Text("· 기록 종류는 바꿀 수 없어요")
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(EditPalette.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 42)
        .background(.white.opacity(0.78), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(EditPalette.border.opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("feedingEdit.recordType")
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                isMemoFocused = false
                isDatePickerPresented = true
            } label: {
                HStack {
                    Text("날짜")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(EditPalette.secondary)

                    Spacer()

                    Text(dateLabel)
                        .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                        .foregroundStyle(EditPalette.primary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(EditPalette.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("날짜, \(dateLabel)")
            .accessibilityIdentifier("feedingEdit.date")

            VStack(alignment: .leading, spacing: 4) {
                Text("먹이 종류")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(EditPalette.secondary)

                HStack(spacing: 6) {
                    ForEach(foodOptions, id: \.self) { food in
                        let isSelected = selectedFood == food

                        Button {
                            isMemoFocused = false
                            selectedFood = food
                        } label: {
                            Text(food)
                                .font(.custom("Jua", size: 10, relativeTo: .caption))
                                .foregroundStyle(isSelected ? EditPalette.forest : EditPalette.secondary)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 34)
                                .background(isSelected ? .white : EditPalette.chip, in: Capsule())
                                .overlay {
                                    Capsule()
                                        .strokeBorder(
                                            isSelected ? EditPalette.border.opacity(0.56) : .clear,
                                            lineWidth: 1
                                        )
                                }
                                .shadow(
                                    color: isSelected ? EditPalette.shadow : .clear,
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(food)
                        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("feedingEdit.food.\(food)")
                    }
                }
            }

            quantityControl

            Button {
                isMemoFocused = false
                didNotEat.toggle()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: didNotEat ? "checkmark.square.fill" : "square")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(didNotEat ? EditPalette.forest : EditPalette.tertiary)
                        .accessibilityHidden(true)

                    Text("안 먹음")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(EditPalette.primary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("안 먹음")
            .accessibilityValue(didNotEat ? "켬" : "끔")
            .accessibilityIdentifier("feedingEdit.notEaten")

            VStack(alignment: .leading, spacing: 4) {
                Text("메모")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(EditPalette.secondary)

                TextField("메모를 입력해 주세요", text: $memo, axis: .vertical)
                    .lineLimit(1...2)
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(EditPalette.primary)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($isMemoFocused)
                    .onSubmit { isMemoFocused = false }
                    .accessibilityLabel("메모")
                    .accessibilityIdentifier("feedingEdit.memo")
                    .padding(.horizontal, 11)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(EditPalette.border.opacity(0.72), lineWidth: 1)
                    }
                    .onChange(of: memo) { _, value in
                        if value.count > 300 { memo = String(value.prefix(300)) }
                    }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(EditPalette.border.opacity(0.54), lineWidth: 1)
        }
        .shadow(color: EditPalette.shadow, radius: 14, x: 0, y: 5)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feedingEdit.form")
    }

    private var quantityControl: some View {
        HStack(spacing: 8) {
            Text("개수")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(EditPalette.secondary)

            Spacer()

            quantityButton(symbol: "minus", label: "개수 줄이기", identifier: "feedingEdit.quantity.decrease") {
                quantity = max(0, quantity - 1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(quantity)")
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                    .foregroundStyle(EditPalette.primary)
                    .accessibilityIdentifier("feedingEdit.quantity.value")

                Text("마리")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(EditPalette.secondary)
            }
            .fixedSize()
            .frame(minWidth: 52)

            quantityButton(symbol: "plus", label: "개수 늘리기", identifier: "feedingEdit.quantity.increase") {
                quantity += 1
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(EditPalette.control, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func quantityButton(
        symbol: String,
        label: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(EditPalette.secondary)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.85), in: Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }

    private var saveButton: some View {
        Button {
            isMemoFocused = false
            onSave(
                FeedingRecordEditData(
                    date: selectedDate,
                    food: selectedFood,
                    quantity: quantity,
                    didNotEat: didNotEat,
                    memo: memo
                )
            )
        } label: {
            Text("저장")
                .font(.custom("Jua", size: 13, relativeTo: .body))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 49)
                .background(EditPalette.forest, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("feedingEdit.save")
    }

    private var datePickerSheet: some View {
        VStack(spacing: 12) {
            HStack {
                Text("날짜 선택")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(EditPalette.primary)

                Spacer()

                Button("완료") { isDatePickerPresented = false }
                    .font(.custom("Jua", size: 12, relativeTo: .body))
                    .accessibilityIdentifier("feedingEdit.date.done")
            }
            .padding(.horizontal, 20)

            DatePicker("날짜", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(EditPalette.forest)
                .accessibilityIdentifier("feedingEdit.datePicker")
                .padding(.horizontal, 12)
        }
        .padding(.top, 20)
        .background(EditPalette.canvas.ignoresSafeArea())
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: selectedDate)
    }
}

private enum EditPalette {
    static let canvas = Color(red: 250 / 255, green: 247 / 255, blue: 240 / 255)
    static let primary = Color(red: 43 / 255, green: 42 / 255, blue: 38 / 255)
    static let secondary = Color(red: 107 / 255, green: 103 / 255, blue: 94 / 255)
    static let tertiary = Color(red: 115 / 255, green: 110 / 255, blue: 101 / 255)
    static let border = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255)
    static let forest = Color(red: 47 / 255, green: 107 / 255, blue: 87 / 255)
    static let chip = Color(red: 242 / 255, green: 239 / 255, blue: 231 / 255)
    static let control = Color(red: 245 / 255, green: 242 / 255, blue: 235 / 255)
    static let shadow = Color(red: 43 / 255, green: 42 / 255, blue: 38 / 255).opacity(0.07)
}
