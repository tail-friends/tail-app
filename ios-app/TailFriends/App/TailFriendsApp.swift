import SwiftUI

@main
struct TailFriendsApp: App {
    var body: some Scene {
        WindowGroup {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-registration") {
                RegistrationView()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-detail-feeding") {
                CreatureDetailFeedingPreviewHost()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-feeding-record") {
                FeedingRecordView()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-home") {
                HomeView()
            } else {
                LoginView()
            }
#else
            LoginView()
#endif
        }
    }
}

#if DEBUG
private struct CreatureDetailFeedingPreviewHost: View {
    @State private var isDetailPresented = true

    var body: some View {
        Group {
            if isDetailPresented {
                CreatureDetailFeedingFormView(onBack: { isDetailPresented = false })
            } else {
                HomeView()
            }
        }
    }
}
#endif
