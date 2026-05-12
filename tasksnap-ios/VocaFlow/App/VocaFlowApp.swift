import SwiftUI

@main
struct VocaFlowApp: App {
    @StateObject private var authState = AuthState()
    @State private var onboardingDone = UserDefaults.standard.bool(forKey: "vocaflow.onboardingComplete")

    var body: some Scene {
        WindowGroup {
            Group {
                if !onboardingDone {
                    OnboardingView(isComplete: $onboardingDone)
                } else if authState.isLoggedIn {
                    RecordingScreen()
                        .environmentObject(authState)
                } else {
                    LoginView()
                        .environmentObject(authState)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: onboardingDone)
            .animation(.easeInOut(duration: 0.35), value: authState.isLoggedIn)
        }
    }
}
