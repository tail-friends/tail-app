import SwiftUI

struct FriendSelectionFriend: Identifiable, Equatable {
    static let idWithLocalRecordSamples = "yukyi"

    let id: String
    let name: String
    let species: String
    let initial: String
    let avatarTone: FriendAvatarTone

    static let samples = [
        FriendSelectionFriend(id: idWithLocalRecordSamples, name: "육이", species: "레오파드 게코", initial: "육", avatarTone: .forest),
        FriendSelectionFriend(id: "chito", name: "치토", species: "비어디드 드래곤", initial: "치", avatarTone: .forest),
        FriendSelectionFriend(id: "leo", name: "레오", species: "크레스티드 게코", initial: "레", avatarTone: .forest),
        FriendSelectionFriend(id: "sera", name: "세라", species: "볼 파이톤", initial: "세", avatarTone: .forest),
        FriendSelectionFriend(id: "toto", name: "토토", species: "육지거북", initial: "토", avatarTone: .sand),
        FriendSelectionFriend(id: "ruby", name: "루비", species: "콘스네이크", initial: "루", avatarTone: .forest),
        FriendSelectionFriend(id: "haru", name: "하루", species: "펫테일 게코", initial: "하", avatarTone: .forest)
    ]
}

enum FriendAvatarTone: Equatable {
    case forest
    case sand
}

enum FriendSelectionState: Equatable {
    case all
    case none
    case friend(String)

    func isSelected(friendID: String) -> Bool {
        switch self {
        case .all:
            return true
        case .none:
            return false
        case .friend(let selectedID):
            return selectedID == friendID
        }
    }
}

struct FriendSelectionSheet: View {
    @Binding var selectionState: FriendSelectionState

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(FriendSelectionPalette.handle)
                .frame(width: 36, height: 4)
                .accessibilityHidden(true)

            header

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    allFriendsRow

                    ForEach(Array(FriendSelectionFriend.samples.enumerated()), id: \.element.id) { index, friend in
                        friendRow(friend, showsSeparator: index < FriendSelectionFriend.samples.count - 1)
                    }
                }
                .frame(maxWidth: 338)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("friendSelection.scroll")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 34)
        .background(FriendSelectionPalette.sheet)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(FriendSelectionPalette.sheetBorder, lineWidth: 1)
                .accessibilityHidden(true)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("친구 선택")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(FriendSelectionPalette.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("friendSelection.title")

                Text("기록을 볼 친구를 골라 주세요")
                    .font(.custom("Jua", size: 12, relativeTo: .caption))
                    .foregroundStyle(FriendSelectionPalette.secondary)
                    .accessibilityIdentifier("friendSelection.subtitle")
            }

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FriendSelectionPalette.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
            .accessibilityIdentifier("friendSelection.close")
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private var allFriendsRow: some View {
        Button {
            selectionState = selectionState == .all ? .none : .all
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("전체 친구")
                        .font(.custom("Jua", size: 14, relativeTo: .body))
                        .foregroundStyle(FriendSelectionPalette.primary)

                    Text("7마리")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(FriendSelectionPalette.tertiary)
                }

                Spacer(minLength: 8)

                selectionIndicator(isSelected: selectionState == .all)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("전체 친구, 7마리")
        .accessibilityValue(selectionState == .all ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(selectionState == .all ? .isSelected : [])
        .accessibilityIdentifier("friendSelection.all")
    }

    private func friendRow(_ friend: FriendSelectionFriend, showsSeparator: Bool) -> some View {
        let isSelected = selectionState.isSelected(friendID: friend.id)

        return VStack(spacing: 0) {
            Button {
                selectionState = .friend(friend.id)
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(friend.avatarTone == .sand ? FriendSelectionPalette.avatarSand : FriendSelectionPalette.forest)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Text(friend.initial)
                                .font(.custom("Jua", size: 16, relativeTo: .body))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(friend.name)
                            .font(.custom("Jua", size: 13, relativeTo: .body))
                            .foregroundStyle(FriendSelectionPalette.primary)
                            .accessibilityIdentifier("friendSelection.friend.\(friend.id).name")

                        Text(friend.species)
                            .font(.custom("Jua", size: 10, relativeTo: .caption))
                            .foregroundStyle(FriendSelectionPalette.secondary)
                            .accessibilityIdentifier("friendSelection.friend.\(friend.id).species")
                    }

                    Spacer(minLength: 8)

                    selectionIndicator(isSelected: isSelected)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(FriendSelectionPalette.selectedSurface)
                    }
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(FriendSelectionPalette.selectedBorder, lineWidth: 1)
                    }
                }
                .shadow(
                    color: isSelected ? FriendSelectionPalette.selectedShadow : .clear,
                    radius: 6,
                    x: 0,
                    y: 2
                )
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(friend.name), \(friend.species)")
            .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("friendSelection.friend.\(friend.id)")

            if showsSeparator {
                Rectangle()
                    .fill(FriendSelectionPalette.separator)
                    .frame(height: 1)
            }
        }
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        Circle()
            .fill(isSelected ? FriendSelectionPalette.forest : .clear)
            .frame(width: 22, height: 22)
            .overlay {
                Circle()
                    .strokeBorder(
                        isSelected ? FriendSelectionPalette.forest : FriendSelectionPalette.border,
                        lineWidth: 1.5
                    )
            }
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityHidden(true)
    }
}

private enum FriendSelectionPalette {
    static let sheet = Color.white
    static let sheetBorder = Color.white.opacity(0.9)
    static let primary = Color(red: 43 / 255, green: 42 / 255, blue: 38 / 255)
    static let secondary = Color(red: 107 / 255, green: 103 / 255, blue: 94 / 255)
    static let tertiary = Color(red: 115 / 255, green: 110 / 255, blue: 101 / 255)
    static let forest = Color(red: 47 / 255, green: 107 / 255, blue: 87 / 255)
    static let avatarSand = Color(red: 115 / 255, green: 110 / 255, blue: 101 / 255)
    static let border = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255)
    static let handle = Color(red: 222 / 255, green: 217 / 255, blue: 204 / 255)
    static let selectedSurface = Color.white
    static let selectedBorder = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255).opacity(0.82)
    static let selectedShadow = Color(red: 43 / 255, green: 42 / 255, blue: 38 / 255).opacity(0.055)
    static let separator = Color(red: 230 / 255, green: 225 / 255, blue: 214 / 255).opacity(0.82)
}
