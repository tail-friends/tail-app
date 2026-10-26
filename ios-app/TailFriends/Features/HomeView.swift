import SwiftUI

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date.now)
    }

    private var heroHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 260 : 214
    }

    private var metricCardHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 172 : 140
    }

    private var navigationMinimumHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 82 : 54
    }

    private var scrollBottomPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 16 : 24
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                HomePalette.canvas
                    .ignoresSafeArea()

                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .padding(.bottom, 25)

                        heroCard
                            .frame(height: heroHeight)
                            .padding(.bottom, 33)

                        feedingCallToAction
                            .padding(.bottom, 40)

                        metrics
                            .padding(.bottom, 12)

                        recentRecords
                    }
                    .frame(maxWidth: 342)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .padding(.bottom, scrollBottomPadding)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("home.scroll")
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomNavigation
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("—")
                .font(.custom("Jua", size: 10, relativeTo: .caption))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(HomePalette.forest, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: 1)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(dateText)
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(HomePalette.tertiary)

                Text("오늘의 사육장")
                    .font(.custom("Jua", size: 20, relativeTo: .title2))
                    .foregroundStyle(HomePalette.forest)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 16))
                    .foregroundStyle(HomePalette.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.8), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("알림")
            .accessibilityIdentifier("home.notification.button")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.header")
    }

    private var heroCard: some View {
        HomeGlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("등록된 친구가 없어요")
                    .font(.custom("Jua", size: 19, relativeTo: .title2))
                    .foregroundStyle(HomePalette.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("친구를 등록하면 여기에 표시돼요")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(HomePalette.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Color.clear
                    .frame(width: 92, height: 80)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    Circle()
                        .fill(HomePalette.muted)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)

                    Text("기록 없음")
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .foregroundStyle(HomePalette.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.8), lineWidth: 1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("home.status")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.hero")
    }

    private var feedingCallToAction: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("급여 기록이 없어요")
                        .font(.custom("Jua", size: 13, relativeTo: .body))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("친구를 등록하면 일정을 확인할 수 있어요")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(HomePalette.softText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HomePalette.forest)
                    .frame(width: 34, height: 34)
                    .background(.white, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 59)
            .background(HomePalette.forest, in: RoundedRectangle(cornerRadius: 22))
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("급여 기록이 없어요. 친구를 등록하면 일정을 확인할 수 있어요")
        .accessibilityIdentifier("home.feeding.button")
    }

    private var metrics: some View {
        HStack(alignment: .top, spacing: 8) {
            metricCard(title: "체중", identifier: "home.weight")
            metricCard(title: "탈피", identifier: "home.molting")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.metrics")
    }

    private func metricCard(title: String, identifier: String) -> some View {
        Button(action: {}) {
            HomeGlassCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.custom("Jua", size: 13, relativeTo: .body))
                            .foregroundStyle(HomePalette.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(HomePalette.tertiary)
                            .accessibilityHidden(true)
                    }

                    Spacer(minLength: 4)

                    Text("기록 없음")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(HomePalette.tertiary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: metricCardHeight)
            .contentShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), 기록 없음")
        .accessibilityIdentifier(identifier)
    }

    private var recentRecords: some View {
        VStack(spacing: 0) {
            HStack {
                Text("최근 기록")
                    .font(.custom("Jua", size: 16, relativeTo: .headline))
                    .foregroundStyle(HomePalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {}) {
                    Text("전체")
                        .font(.custom("Jua", size: 11, relativeTo: .caption))
                        .foregroundStyle(HomePalette.secondary)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("전체 기록 보기")
                .accessibilityIdentifier("home.records.all")
            }

            HomeGlassCard {
                Text("아직 기록이 없어요")
                    .font(.custom("Jua", size: 11, relativeTo: .caption))
                    .foregroundStyle(HomePalette.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 90)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("home.records.empty")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.records")
    }

    private var bottomNavigation: some View {
        HStack(spacing: 8) {
            navigationItem(
                title: "사육장",
                icon: "house.fill",
                selected: true,
                identifier: "habitat"
            )
            navigationItem(
                title: "기록",
                icon: "list.bullet.rectangle",
                selected: false,
                identifier: "records"
            )
            navigationItem(
                title: "내 아이들",
                icon: "pawprint.fill",
                selected: false,
                identifier: "pets"
            )
            navigationItem(
                title: "마이",
                icon: "person.fill",
                selected: false,
                identifier: "profile"
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: 342, minHeight: navigationMinimumHeight)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.76),
                                    .white.opacity(0.38)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: HomePalette.shadow, radius: 16, x: 0, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.bottomNavigation")
    }

    private func navigationItem(
        title: String,
        icon: String,
        selected: Bool,
        identifier: String
    ) -> some View {
        Button(action: {}) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.custom("Jua", size: 10, relativeTo: .caption))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(selected ? HomePalette.forest : HomePalette.tertiary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white.opacity(0.88))
                        .shadow(color: HomePalette.shadow, radius: 3, x: 1, y: 2)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("home.bottomNavigation.\(identifier)")
    }
}

private struct HomeGlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(17)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.76),
                                        .white.opacity(0.38)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.86), lineWidth: 1)
            }
            .shadow(color: HomePalette.shadow, radius: 16, x: 0, y: 12)
    }
}

private enum HomePalette {
    static let canvas = Color(
        .sRGB,
        red: 250.0 / 255.0,
        green: 247.0 / 255.0,
        blue: 240.0 / 255.0,
        opacity: 1
    )
    static let forest = Color(
        .sRGB,
        red: 47.0 / 255.0,
        green: 107.0 / 255.0,
        blue: 87.0 / 255.0,
        opacity: 1
    )
    static let primary = Color(
        .sRGB,
        red: 43.0 / 255.0,
        green: 42.0 / 255.0,
        blue: 38.0 / 255.0,
        opacity: 1
    )
    static let secondary = Color(
        .sRGB,
        red: 107.0 / 255.0,
        green: 103.0 / 255.0,
        blue: 94.0 / 255.0,
        opacity: 1
    )
    static let tertiary = Color(
        .sRGB,
        red: 115.0 / 255.0,
        green: 110.0 / 255.0,
        blue: 101.0 / 255.0,
        opacity: 1
    )
    static let muted = Color(
        .sRGB,
        red: 171.0 / 255.0,
        green: 164.0 / 255.0,
        blue: 152.0 / 255.0,
        opacity: 1
    )
    static let softText = Color(
        .sRGB,
        red: 215.0 / 255.0,
        green: 230.0 / 255.0,
        blue: 220.0 / 255.0,
        opacity: 1
    )
    static let shadow = Color(
        .sRGB,
        red: 61.0 / 255.0,
        green: 51.0 / 255.0,
        blue: 41.0 / 255.0,
        opacity: 0.08
    )
}
