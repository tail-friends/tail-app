import SwiftUI

@main
struct TailFriendsApp: App {
    var body: some Scene {
        WindowGroup {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-registration") {
                RegistrationView()
            } else if ProcessInfo.processInfo.arguments.contains("--preview-creature-detail-feeding") {
                CreatureDetailFeedingFormView()
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
