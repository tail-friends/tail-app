import SwiftUI

@main
struct TailFriendsApp: App {
    var body: some Scene {
        WindowGroup {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-home") {
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
