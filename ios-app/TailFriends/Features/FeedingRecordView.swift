import SwiftUI
import UIKit

struct FeedingRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isMemoFocused: Bool

    @State private var selectedRecordType: FeedingRecordType = .feeding
    @State private var selectedFood = FeedingFood.cricket
    @State private var quantity = 5
    @State private var didNotEat = false
    @State private var memo = "잘 받아먹음"
    @State private var isNoticePresented = false
    @State private var noticeTitle = ""
    @State private var noticeMessage = ""
    @State private var sheetDragOffset: CGFloat = 0
    @State private var isSheetPresented = true
    @State private var isSheetClosing = false
    @State private var stableFullHeight: CGFloat?
    @State private var stableTopInset: CGFloat?
    @State private var stableBottomInset: CGFloat?
    @State private var keyboardFrameInScreen: CGRect?

    var body: some View {
        GeometryReader { geometry in
            let measuredTopInset = geometry.safeAreaInsets.top
            let measuredBottomInset = geometry.safeAreaInsets.bottom
            let measuredFullHeight = geometry.size.height + measuredTopInset + measuredBottomInset
            let fullHeight = stableFullHeight ?? measuredFullHeight
            let topInset = stableTopInset ?? measuredTopInset
            let bottomInset = stableBottomInset ?? measuredBottomInset
            let sheetHeight = max(500, fullHeight - 294)

            ZStack(alignment: .bottom) {
                homeBackdrop(topInset: topInset, size: CGSize(width: geometry.size.width, height: fullHeight))

                if isSheetPresented {
                    sheet(
                        bottomInset: bottomInset,
                        dismissalDistance: fullHeight,
                        backdropTopInset: topInset,
                        backdropSize: CGSize(width: geometry.size.width, height: fullHeight),
                        backdropVerticalOffset: fullHeight - sheetHeight
                    )
                        .frame(height: sheetHeight)
                        .frame(maxWidth: .infinity)
                        .offset(y: sheetDragOffset)
                }
            }
            .frame(width: geometry.size.width, height: fullHeight)
            .offset(y: -topInset)
            .onAppear {
                if stableFullHeight == nil {
                    stableFullHeight = measuredFullHeight
                    stableTopInset = measuredTopInset
                    stableBottomInset = measuredBottomInset
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return
                }

                keyboardFrameInScreen = keyboardFrame
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardFrameInScreen = nil
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    isMemoFocused = false
                }
                .accessibilityIdentifier("feeding.memo.done")
            }
        }
        .alert(noticeTitle, isPresented: $isNoticePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(noticeMessage)
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

    private func sheet(
        bottomInset: CGFloat,
        dismissalDistance: CGFloat,
        backdropTopInset: CGFloat,
        backdropSize: CGSize,
        backdropVerticalOffset: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            dragHandle(dismissalDistance: dismissalDistance)

            sheetHeader {
                dismissSheet(distance: dismissalDistance)
            }
                .padding(.top, 12)
                .padding(.bottom, 16)

            ScrollViewReader { scrollProxy in
                GeometryReader { scrollGeometry in
                    let scrollFrame = scrollGeometry.frame(in: .global)
                    let keyboardInset = keyboardOverlap(with: scrollFrame)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            recordTypeControl
                            foodSection
                            quantitySection
                            notEatenSection
                            memoSection
                                .id("feeding.memo.focus-target")
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(12, scrollGeometry.size.height - keyboardInset))
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear
                            .frame(height: keyboardInset)
                            .accessibilityHidden(true)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .accessibilityIdentifier("feeding.scroll")
                    .onChange(of: isMemoFocused) { _, isFocused in
                        guard isFocused else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo("feeding.memo.focus-target", anchor: .top)
                        }
                    }
                    .onChange(of: keyboardInset) { _, inset in
                        guard isMemoFocused, inset > 0 else { return }
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.2)) {
                                scrollProxy.scrollTo("feeding.memo.focus-target", anchor: .top)
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                        guard isMemoFocused else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo("feeding.memo.focus-target", anchor: .top)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            saveAction
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, max(12, bottomInset + 8))
        }
        .background {
            GeometryReader { backgroundGeometry in
                ZStack(alignment: .topLeading) {
                    homeBackdrop(topInset: backdropTopInset, size: backdropSize)
                        .blur(radius: 18)
                        .offset(y: -backdropVerticalOffset)

                    LinearGradient(
                        colors: [.white.opacity(0.94), .white.opacity(0.64)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: backgroundGeometry.size.width, height: backgroundGeometry.size.height)
                }
                .frame(
                    width: backgroundGeometry.size.width,
                    height: backgroundGeometry.size.height,
                    alignment: .topLeading
                )
                .clipped()
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 32,
                    topTrailingRadius: 32,
                    style: .continuous
                ))
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func keyboardOverlap(with viewFrame: CGRect) -> CGFloat {
        guard let keyboardFrameInScreen else { return 0 }
        let intersection = viewFrame.intersection(keyboardFrameInScreen)
        guard !intersection.isNull, intersection.height.isFinite else { return 0 }
        return max(0, intersection.height)
    }

    private func dragHandle(dismissalDistance: CGFloat) -> some View {
        Capsule()
            .fill(FeedingPalette.handle)
            .frame(width: 50, height: 5)
            .padding(.top, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 15, alignment: .top)
            .overlay(alignment: .top) {
                Color.clear
                    .frame(width: 120, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("기록 추가 화면 핸들")
                    .accessibilityIdentifier("feeding.sheet.handle")
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { value in
                                sheetDragOffset = max(0, value.translation.height)
                            }
                            .onEnded { value in
                                if value.translation.height >= 110 {
                                    dismissSheet(distance: dismissalDistance)
                                } else {
                                    withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86)) {
                                        sheetDragOffset = 0
                                    }
                                }
                            }
                    )
            }
    }

    private func dismissSheet(distance: CGFloat) {
        guard isSheetPresented, !isSheetClosing else { return }
        isSheetClosing = true
        isMemoFocused = false

        withAnimation(.easeInOut(duration: 0.28)) {
            sheetDragOffset = distance
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSheetPresented = false
            dismiss()
        }
    }

    private func sheetHeader(onClose: @escaping () -> Void) -> some View {
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
                onClose()
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
                    if type == .feeding {
                        selectedRecordType = .feeding
                    } else {
                        noticeTitle = "준비 중"
                        noticeMessage = "\(type.title) 기록은 준비 중이에요."
                        isNoticePresented = true
                    }
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
                            .frame(minWidth: 45, minHeight: 44)
                            .contentShape(Rectangle())
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

            TextField("메모를 입력해 주세요", text: $memo, axis: .vertical)
                .lineLimit(1...4)
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
                .padding(.trailing, isMemoFocused && !memo.isEmpty ? 44 : 0)
                .frame(maxWidth: .infinity, minHeight: 54)
                .overlay(alignment: .trailing) {
                    if isMemoFocused && !memo.isEmpty {
                        Button {
                            memo = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(FeedingPalette.secondary.opacity(0.72))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("메모 지우기")
                        .accessibilityIdentifier("feeding.memo.clear")
                        .zIndex(1)
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
            noticeTitle = "저장 미리보기"
            noticeMessage = "입력한 기록은 이 미리보기에서만 유지되며 실제로 저장되지 않습니다."
            isNoticePresented = true
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
