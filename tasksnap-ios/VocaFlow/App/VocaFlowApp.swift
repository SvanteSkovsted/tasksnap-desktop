import SwiftUI

@main
struct VocaFlowApp: App {
    @StateObject private var authState = AuthState()
    @StateObject private var trigger   = RecordingTrigger.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isLoggedIn {
                    HomeView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authState)
            .environmentObject(trigger)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                trigger.checkUserDefaults()
            }
        }
    }
}
