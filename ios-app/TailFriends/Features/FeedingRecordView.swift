import SwiftUI

struct FeedingRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isMemoFocused: Bool

    @State private var selectedRecordType: FeedingRecordType = .feeding
    @State private var selectedFood = FeedingFood.cricket
    @State private var quantity = 5
    @State private var didNotEat = false
    @State private var memo = "잘 받아먹음"
    @State private var isSavePreviewPresented = false

    var body: some View {
        GeometryReader { geometry in
            let fullHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            let topInset = geometry.safeAreaInsets.top
            let bottomInset = geometry.safeAreaInsets.bottom
            let sheetHeight = max(500, fullHeight - 294)

            ZStack(alignment: .bottom) {
                homeBackdrop(topInset: topInset, size: CGSize(width: geometry.size.width, height: fullHeight))

                sheet(bottomInset: bottomInset)
                    .frame(height: sheetHeight)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: geometry.size.width, height: fullHeight)
            .offset(y: -topInset)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    isMemoFocused = false
                }
                .accessibilityIdentifier("feeding.memo.done")
            }
        }
        .alert("저장 미리보기", isPresented: $isSavePreviewPresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("입력한 기록은 이 미리보기에서만 유지되며 실제로 저장되지 않습니다.")
        }
        .preferredColorScheme(.light)
    }

    private func homeBackdrop(topInset: CGFloat, size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Image("home_background")
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("욱")
                        .font(.custom("Jua", size: 10, relativeTo: .caption))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(FeedingPalette.forest, in: Circle())
                        .overlay { Circle().strokeBorder(.white, lineWidth: 1) }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("10월 20일 화요일")
                            .font(.custom("Jua", size: 11, relativeTo: .caption))
                            .foregroundStyle(FeedingPalette.secondary)
                        Text("욱이의 하루")
                            .font(.custom("Jua", size: 20, relativeTo: .title2))
                            .foregroundStyle(FeedingPalette.forest)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "bell")
                        .font(.system(size: 16))
                        .foregroundStyle(FeedingPalette.forest)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 24)
                .padding(.top, topInset + 4)

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("욱이")
                            .font(.custom("Jua", size: 18, relativeTo: .title3))
                            .foregroundStyle(FeedingPalette.primary)
                        Text("레오파드 게코 · 2살 3개월")
                            .font(.custom("Jua", size: 11, relativeTo: .caption))
                            .foregroundStyle(FeedingPalette.secondary)
                    }

                    Spacer(minLength: 0)

                    Text("조금 출출해요")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(FeedingPalette.primary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 36)
                        .background(.white.opacity(0.55), in: Capsule())
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.86), lineWidth: 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer(minLength: 0)
            }

            Color(feedingHex: 0x2F6B57)
                .opacity(0.18)
                .accessibilityHidden(true)
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private func sheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(FeedingPalette.handle)
                .frame(width: 50, height: 5)
                .padding(.top, 10)
                .accessibilityHidden(true)

            sheetHeader
                .padding(.top, 12)
                .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    recordTypeControl
                    foodSection
                    quantitySection
                    notEatenSection
                    memoSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("feeding.scroll")

            saveAction
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, max(12, bottomInset + 8))
        }
        .background {
            FeedingPalette.sheet
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 32,
                    topTrailingRadius: 32,
                    style: .continuous
                ))
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("기록 추가")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(FeedingPalette.primary)
                    .accessibilityAddTraits(.isHeader)

                Text("욱이 · 10월 20일")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(FeedingPalette.secondary)
            }

            Spacer(minLength: 0)

            Button {
                isMemoFocused = false
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FeedingPalette.primary)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.82), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
            .accessibilityIdentifier("feeding.close")
        }
        .padding(.horizontal, 24)
    }

    private var recordTypeControl: some View {
        HStack(spacing: 4) {
            ForEach(FeedingRecordType.allCases) { type in
                let isSelected = selectedRecordType == type

                Button {
                    isMemoFocused = false
                    selectedRecordType = type
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityHidden(true)
                        Text(type.title)
                            .font(.custom("Jua", size: 13, relativeTo: .subheadline))
                    }
                    .foregroundStyle(isSelected ? FeedingPalette.primary : FeedingPalette.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(.white.opacity(0.96))
                                .shadow(color: FeedingPalette.shadow, radius: 5, x: 0, y: 3)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.title)
                .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                .accessibilityIdentifier("feeding.type.\(type.rawValue)")
            }
        }
        .padding(4)
        .background(FeedingPalette.controlTrack, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feeding.typePicker")
    }

    private var foodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("먹이")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(FeedingPalette.secondary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 6) {
                ForEach(FeedingFood.allCases) { food in
                    let isSelected = selectedFood == food

                    Button {
                        isMemoFocused = false
                        selectedFood = food
                    } label: {
                        Text(food.title)
                            .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                            .foregroundStyle(isSelected ? FeedingPalette.primary : FeedingPalette.secondary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 38)
                            .background {
                                Capsule()
                                    .fill(isSelected ? .white : FeedingPalette.unselectedChip)
                                    .shadow(color: isSelected ? FeedingPalette.shadow : .clear, radius: 4, x: 0, y: 2)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(food.title)
                    .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                    .accessibilityIdentifier("feeding.food.\(food.rawValue)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quantitySection: some View {
        HStack(spacing: 12) {
            Text("수량")
                .font(.custom("Jua", size: 14, relativeTo: .body))
                .foregroundStyle(FeedingPalette.primary)

            Spacer(minLength: 0)

            Button {
                quantity = max(0, quantity - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FeedingPalette.primary)
                    .frame(width: 44, height: 44)
                    .background(.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("수량 줄이기")
            .accessibilityIdentifier("feeding.quantity.decrease")

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(quantity)")
                    .font(.custom("Jua", size: 16, relativeTo: .body))
                    .accessibilityIdentifier("feeding.quantity.value")
                Text("마리")
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
            }
            .foregroundStyle(FeedingPalette.primary)
            .fixedSize()

            Button {
                quantity += 1
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FeedingPalette.primary)
                    .frame(width: 44, height: 44)
                    .background(.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("수량 늘리기")
            .accessibilityIdentifier("feeding.quantity.increase")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(FeedingPalette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feeding.quantity")
    }

    private var notEatenSection: some View {
        Button {
            isMemoFocused = false
            didNotEat.toggle()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("안 먹음")
                        .font(.custom("Jua", size: 14, relativeTo: .body))
                        .foregroundStyle(FeedingPalette.primary)
                    Text("체크하면 다음 급여일 계산에서 빠져요")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(FeedingPalette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ZStack(alignment: didNotEat ? .trailing : .leading) {
                    Capsule()
                        .fill(didNotEat ? FeedingPalette.forest : FeedingPalette.toggleTrack)
                        .frame(width: 48, height: 28)
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .padding(.horizontal, 3)
                }
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(FeedingPalette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("안 먹음")
        .accessibilityValue(didNotEat ? "켬" : "끔")
        .accessibilityAddTraits(didNotEat ? .isSelected : [])
        .accessibilityIdentifier("feeding.notEaten")
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메모")
                .font(.custom("Jua", size: 11, relativeTo: .caption))
                .foregroundStyle(FeedingPalette.secondary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                TextField("메모를 입력해 주세요", text: $memo)
                    .font(.custom("Jua", size: 14, relativeTo: .body))
                    .foregroundStyle(FeedingPalette.primary)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($isMemoFocused)
                    .onSubmit { isMemoFocused = false }
                    .accessibilityLabel("메모")
                    .accessibilityIdentifier("feeding.memo")
                    .onChange(of: memo) { _, newValue in
                        if newValue.count > 300 {
                            memo = String(newValue.prefix(300))
                        }
                    }

                if isMemoFocused && !memo.isEmpty {
                    Button {
                        memo = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(FeedingPalette.secondary.opacity(0.72))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("메모 지우기")
                    .accessibilityIdentifier("feeding.memo.clear")
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var saveAction: some View {
        Button {
            isMemoFocused = false
            isSavePreviewPresented = true
        } label: {
            Text("저장")
                .font(.custom("Jua", size: 14, relativeTo: .body))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(FeedingPalette.forest, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("feeding.save")
    }
}

private enum FeedingRecordType: String, CaseIterable, Identifiable {
    case feeding
    case molting
    case weight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feeding: "급여"
        case .molting: "탈피"
        case .weight: "체중"
        }
    }

    var symbol: String {
        switch self {
        case .feeding: "ladybug.fill"
        case .molting: "square.3.layers.3d"
        case .weight: "scalemass.fill"
        }
    }
}

private enum FeedingFood: String, CaseIterable, Identifiable {
    case cricket
    case mealworm
    case dubia
    case superworm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cricket: "귀뚜라미"
        case .mealworm: "밀웜"
        case .dubia: "두비아"
        case .superworm: "슈퍼웜"
        }
    }
}

private enum FeedingPalette {
    static let sheet = Color(feedingHex: 0xFAF7F0)
    static let primary = Color(feedingHex: 0x2B2A26)
    static let secondary = Color(feedingHex: 0x6B675E)
    static let forest = Color(feedingHex: 0x2F6B57)
    static let card = Color.white.opacity(0.82)
    static let controlTrack = Color.white.opacity(0.42)
    static let unselectedChip = Color.white.opacity(0.54)
    static let toggleTrack = Color(feedingHex: 0xE3DED3)
    static let handle = Color(feedingHex: 0xE4DED2)
    static let shadow = Color(feedingHex: 0x3D3329).opacity(0.14)
}

private extension Color {
    init(feedingHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
