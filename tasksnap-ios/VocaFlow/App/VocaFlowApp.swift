import SwiftUI

@main
struct VocaFlowApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            if authState.isLoggedIn {
                RecordingScreen()
                    .environmentObject(authState)
            } else {
                LoginView()
                    .environmentObject(authState)
            }
        }
    }
}
