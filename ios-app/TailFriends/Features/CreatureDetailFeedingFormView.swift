import SwiftUI

struct CreatureDetailFeedingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isMemoFocused: Bool

    @State private var selectedFood = "귀뚜라미"
    @State private var quantity = 50
    @State private var didNotEat = false
    @State private var memo = "잘 받아먹음"
    @State private var selectedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 20)) ?? .now
    @State private var isDatePickerPresented = false
    @State private var isNoticePresented = false
    @State private var noticeTitle = ""
    @State private var noticeMessage = ""
    @State private var recentRecords = CreatureRecord.previewRecords

    private let categories: [(title: String, symbol: String)] = [
        ("급여", "takeoutbag.and.cup.and.straw.fill"),
        ("탈피", "square.3.layers.3d"),
        ("체중", "scalemass.fill"),
        ("청소", "sparkles"),
        ("환경", "sun.max.fill")
    ]
    private let foodOptions = ["귀뚜라미", "밀웜", "두비아"]
    private let managementItems = ["성장 앨범", "합사 보기", "번식 기록", "쿨링(휴면) 모드"]

    var body: some View {
        ZStack {
            DetailPalette.canvas.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    heroCard
                    creatureSummary
                    metricsCard
                    categoryPicker
                    feedingForm
                    weightChart
                    recentRecordSection
                    managementSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .frame(maxWidth: 342)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("creatureDetail.scroll")
        }
        .preferredColorScheme(.light)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { isMemoFocused = false }
                    .accessibilityIdentifier("creatureDetail.memo.done")
            }
        }
        .sheet(isPresented: $isDatePickerPresented) {
            datePickerSheet
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
        }
        .alert(noticeTitle, isPresented: $isNoticePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(noticeMessage)
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DetailPalette.photoTop, DetailPalette.photoBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "photo")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(DetailPalette.secondary.opacity(0.38))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DetailPalette.primary)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.82), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("뒤로")
                    .accessibilityIdentifier("creatureDetail.back")

                    Spacer()

                    Button {
                        showNotice(title: "수정 미리보기", message: "친구 정보 수정은 준비 중이에요.")
                    } label: {
                        Text("수정")
                            .font(.custom("Jua", size: 13, relativeTo: .subheadline))
                            .foregroundStyle(DetailPalette.primary)
                            .frame(minWidth: 60, minHeight: 44)
                            .background(.white.opacity(0.82), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("creatureDetail.edit")
                }

                HStack {
                    Text("오늘 밥 먹는 날!")
                        .font(.custom("Jua", size: 12, relativeTo: .caption))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(DetailPalette.forest, in: Capsule())
                    Spacer()
                }

                Spacer(minLength: 0)

                HStack {
                    Text("사막 · 평소")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(DetailPalette.primary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(.white.opacity(0.84), in: Capsule())
                    Spacer()
                }
            }
            .padding(12)
        }
        .frame(height: 204)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.78), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetail.hero")
    }

    private var creatureSummary: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text("욱이")
                    .font(.custom("Jua", size: 20, relativeTo: .title2))
                    .foregroundStyle(DetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)

                Text("레오파드 게코 · 탄제린 · 수컷 · 생후 1년 7개월")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(DetailPalette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("creatureDetail.description")
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricsCard: some View {
        HStack(spacing: 0) {
            metric(title: "다음 급여", value: "오늘", detail: "4일 주기", identifier: "feeding")
            metricDivider
            metric(title: "마지막 탈피", value: "12일 전", detail: "평균 21일", identifier: "molting")
            metricDivider
            metric(title: "체중", value: "53.4g", detail: "+1.4g", identifier: "weight")
        }
        .padding(.vertical, 15)
        .background(DetailPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.85), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetail.metrics")
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(DetailPalette.divider)
            .frame(width: 1, height: 42)
            .accessibilityHidden(true)
    }

    private func metric(title: String, value: String, detail: String, identifier: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(DetailPalette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value)
                .font(.custom("Jua", size: 15, relativeTo: .body))
                .foregroundStyle(DetailPalette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(detail)
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(DetailPalette.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("creatureDetail.metric.\(identifier)")
    }

    private var categoryPicker: some View {
        HStack(spacing: 2) {
            ForEach(categories, id: \.title) { category in
                Button {
                    guard category.title == "급여" else {
                        showNotice(title: "준비 중", message: "\(category.title) 기록은 준비 중이에요.")
                        return
                    }
                    isMemoFocused = false
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(category.title)
                            .font(.custom("Jua", size: 11, relativeTo: .caption))
                    }
                    .foregroundStyle(category.title == "급여" ? DetailPalette.forest : DetailPalette.secondary)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background {
                        if category.title == "급여" {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(.white.opacity(0.92))
                                .shadow(color: DetailPalette.shadow, radius: 5, x: 0, y: 2)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.title)
                .accessibilityValue(category.title == "급여" ? "선택됨" : "선택 안 됨")
                .accessibilityIdentifier("creatureDetail.category.\(category.title)")
            }
        }
        .padding(4)
        .background(DetailPalette.track, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetail.categoryPicker")
    }

    private var feedingForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("급여 기록")
                    .font(.custom("Jua", size: 17, relativeTo: .headline))
                    .foregroundStyle(DetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("직전 기록으로 채웠어요")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(DetailPalette.tertiary)
            }

            Button {
                isMemoFocused = false
                isDatePickerPresented = true
            } label: {
                HStack {
                    Text("날짜")
                        .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                        .foregroundStyle(DetailPalette.secondary)
                    Spacer()
                    Text(dateLabel)
                        .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                        .foregroundStyle(DetailPalette.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DetailPalette.tertiary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("creatureDetail.date")

            VStack(alignment: .leading, spacing: 8) {
                Text("먹이 종류")
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                    .foregroundStyle(DetailPalette.secondary)

                HStack(spacing: 8) {
                    ForEach(foodOptions, id: \.self) { food in
                        let isSelected = food == selectedFood
                        Button {
                            isMemoFocused = false
                            selectedFood = food
                        } label: {
                            Text(food)
                                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                                .foregroundStyle(isSelected ? DetailPalette.forest : DetailPalette.secondary)
                                .padding(.horizontal, 13)
                                .frame(minHeight: 38)
                                .background(isSelected ? .white : DetailPalette.chip, in: Capsule())
                                .overlay {
                                    Capsule().strokeBorder(isSelected ? .white : .clear, lineWidth: 1)
                                }
                                .shadow(color: isSelected ? DetailPalette.shadow : .clear, radius: 4, x: 0, y: 2)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(food)
                        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
                        .accessibilityIdentifier("creatureDetail.food.\(food)")
                    }
                }
            }

            HStack(spacing: 10) {
                Text("개수")
                    .font(.custom("Jua", size: 13, relativeTo: .body))
                    .foregroundStyle(DetailPalette.primary)
                Spacer()
                countButton(symbol: "minus", label: "개수 줄이기", identifier: "creatureDetail.quantity.decrease") {
                    quantity = max(0, quantity - 1)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(quantity)")
                        .font(.custom("Jua", size: 15, relativeTo: .body))
                        .accessibilityIdentifier("creatureDetail.quantity.value")
                    Text("마리")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                }
                .foregroundStyle(DetailPalette.primary)
                .fixedSize()
                countButton(symbol: "plus", label: "개수 늘리기", identifier: "creatureDetail.quantity.increase") {
                    quantity += 1
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(DetailPalette.control, in: RoundedRectangle(cornerRadius: 17, style: .continuous))

            Button {
                isMemoFocused = false
                didNotEat.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: didNotEat ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(didNotEat ? DetailPalette.forest : DetailPalette.tertiary)
                    Text("안 먹음")
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .foregroundStyle(DetailPalette.primary)
                    Spacer()
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("안 먹음")
            .accessibilityValue(didNotEat ? "켬" : "끔")
            .accessibilityIdentifier("creatureDetail.notEaten")

            VStack(alignment: .leading, spacing: 7) {
                Text("메모 (선택)")
                    .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                    .foregroundStyle(DetailPalette.secondary)

                TextField("메모를 입력해 주세요", text: $memo, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.custom("Jua", size: 13, relativeTo: .body))
                    .foregroundStyle(DetailPalette.primary)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($isMemoFocused)
                    .onSubmit { isMemoFocused = false }
                    .accessibilityLabel("메모")
                    .accessibilityIdentifier("creatureDetail.memo")
                    .onChange(of: memo) { _, value in
                        if value.count > 300 { memo = String(value.prefix(300)) }
                    }
                    .padding(.trailing, isMemoFocused && !memo.isEmpty ? 44 : 0)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay(alignment: .trailing) {
                        if isMemoFocused && !memo.isEmpty {
                            Button { memo = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(DetailPalette.secondary.opacity(0.72))
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("메모 지우기")
                            .accessibilityIdentifier("creatureDetail.memo.clear")
                        }
                    }
                    .padding(.horizontal, 13)
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(DetailPalette.line, lineWidth: 1)
                    }
            }

            HStack(spacing: 10) {
                Button {
                    isMemoFocused = false
                    resetForm()
                } label: {
                    Text("취소")
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .foregroundStyle(DetailPalette.secondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(DetailPalette.control, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("creatureDetail.cancel")

                Button {
                    isMemoFocused = false
                    showNotice(title: "저장 미리보기", message: "입력한 기록은 이 화면 미리보기에서만 유지되며 실제로 저장되지 않습니다.")
                } label: {
                    Text("저장")
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(DetailPalette.forest, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("creatureDetail.save")
            }
        }
        .padding(16)
        .background(DetailPalette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetail.feedingForm")
    }

    private func countButton(symbol: String, label: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DetailPalette.primary)
                .frame(width: 34, height: 34)
                .background(.white, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        let previewDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 20)) ?? .now
        return Calendar.current.isDate(selectedDate, inSameDayAs: previewDate)
            ? "오늘 · 10월 20일"
            : formatter.string(from: selectedDate)
    }

    private var datePickerSheet: some View {
        VStack(spacing: 12) {
            HStack {
                Text("날짜 선택")
                    .font(.custom("Jua", size: 17, relativeTo: .headline))
                    .foregroundStyle(DetailPalette.primary)
                Spacer()
                Button("완료") { isDatePickerPresented = false }
                    .font(.custom("Jua", size: 13, relativeTo: .body))
                    .accessibilityIdentifier("creatureDetail.date.done")
            }
            .padding(.horizontal, 20)
            DatePicker("날짜", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(DetailPalette.forest)
                .padding(.horizontal, 12)
        }
        .padding(.top, 20)
        .background(DetailPalette.canvas.ignoresSafeArea())
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("체중 변화")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(DetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("최근 53.4g (+1.4g)")
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(DetailPalette.forest)
            }

            ZStack {
                VStack {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(DetailPalette.line)
                            .frame(height: 1)
                        Spacer(minLength: 0)
                    }
                }
                WeightTrendShape()
                    .stroke(DetailPalette.forest, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .padding(.vertical, 8)
                Circle()
                    .fill(DetailPalette.forest)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .position(x: 300, y: 20)
            }
            .frame(height: 82)
            .accessibilityHidden(true)

            HStack {
                Text("최소 41.0g · 5월")
                Spacer()
                Text("최대 53.4g · 10월 20일")
            }
            .font(.custom("Jua", size: 9, relativeTo: .caption2))
            .foregroundStyle(DetailPalette.tertiary)
        }
        .padding(16)
        .background(DetailPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("creatureDetail.weightChart")
    }

    private var recentRecordSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("최근 기록")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(DetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showNotice(title: "최근 기록", message: "전체 기록 보기는 준비 중이에요.")
                } label: {
                    HStack(spacing: 4) {
                        Text("전체 보기")
                        Image(systemName: "chevron.right")
                    }
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .foregroundStyle(DetailPalette.secondary)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("creatureDetail.records.all")
            }

            VStack(spacing: 0) {
                ForEach(recentRecords) { record in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(record.kind == .feeding ? DetailPalette.forest : DetailPalette.clay)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.title)
                                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                                .foregroundStyle(DetailPalette.primary)
                            Text(record.date)
                                .font(.custom("Jua", size: 9, relativeTo: .caption2))
                                .foregroundStyle(DetailPalette.tertiary)
                        }
                        Spacer()
                        Button {
                            recentRecords.removeAll { $0.id == record.id }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DetailPalette.tertiary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(record.title) 기록 삭제")
                        .accessibilityIdentifier("creatureDetail.record.delete.\(record.id)")
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 58)
                    if record.id != recentRecords.last?.id {
                        Divider().overlay(DetailPalette.line).padding(.leading, 32)
                    }
                }
            }
            .background(DetailPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
            }
        }
    }

    private var managementSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("관리")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(DetailPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(managementItems.enumerated()), id: \.offset) { item in
                    let index = item.offset
                    let title = item.element
                    Button {
                        showNotice(title: "준비 중", message: "\(title)은 준비 중이에요.")
                    } label: {
                        HStack {
                            Text(title)
                                .font(.custom("Jua", size: 12, relativeTo: .subheadline))
                                .foregroundStyle(DetailPalette.primary)
                            Spacer()
                            Text("준비 중")
                                .font(.custom("Jua", size: 9, relativeTo: .caption2))
                                .foregroundStyle(DetailPalette.tertiary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DetailPalette.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("creatureDetail.management.\(index)")
                    if index < 3 {
                        Divider().overlay(DetailPalette.line).padding(.leading, 14)
                    }
                }
            }
            .background(DetailPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
            }
        }
    }

    private func showNotice(title: String, message: String) {
        noticeTitle = title
        noticeMessage = message
        isNoticePresented = true
    }

    private func resetForm() {
        selectedFood = "귀뚜라미"
        quantity = 50
        didNotEat = false
        memo = "잘 받아먹음"
        selectedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 20)) ?? .now
    }
}

private struct CreatureRecord: Identifiable {
    enum Kind: Equatable { case weight, feeding }

    let id: String
    let kind: Kind
    let title: String
    let date: String

    static let previewRecords = [
        CreatureRecord(id: "weight-1020", kind: .weight, title: "53.4g · +1.4g", date: "10월 20일"),
        CreatureRecord(id: "feeding-1016", kind: .feeding, title: "귀뚜라미 50마리", date: "10월 16일"),
        CreatureRecord(id: "weight-1013", kind: .weight, title: "52.0g · +0.5g", date: "10월 13일")
    ]
}

private struct WeightTrendShape: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0, y: 0.82),
            CGPoint(x: 0.18, y: 0.68),
            CGPoint(x: 0.34, y: 0.75),
            CGPoint(x: 0.51, y: 0.46),
            CGPoint(x: 0.67, y: 0.53),
            CGPoint(x: 0.83, y: 0.28),
            CGPoint(x: 1, y: 0.12)
        ]
        var path = Path()
        for (index, point) in points.enumerated() {
            let scaled = CGPoint(x: point.x * rect.width, y: point.y * rect.height)
            if index == 0 { path.move(to: scaled) } else { path.addLine(to: scaled) }
        }
        return path
    }
}

private enum DetailPalette {
    static let canvas = Color(detailHex: 0xFAF7F0)
    static let primary = Color(detailHex: 0x2B2A26)
    static let secondary = Color(detailHex: 0x6B675E)
    static let tertiary = Color(detailHex: 0x8B857A)
    static let forest = Color(detailHex: 0x2F6B57)
    static let card = Color.white.opacity(0.82)
    static let track = Color.white.opacity(0.42)
    static let chip = Color.white.opacity(0.52)
    static let control = Color.white.opacity(0.68)
    static let line = Color(detailHex: 0xE7E1D6)
    static let divider = Color(detailHex: 0xE7E1D6).opacity(0.8)
    static let photoTop = Color(detailHex: 0xDAD6C9)
    static let photoBottom = Color(detailHex: 0xC8C5B9)
    static let clay = Color(detailHex: 0xB78E71)
    static let shadow = Color(detailHex: 0x3D3329).opacity(0.1)
}

private extension Color {
    init(detailHex hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
