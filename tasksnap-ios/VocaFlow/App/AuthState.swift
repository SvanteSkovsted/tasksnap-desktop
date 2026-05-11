import Foundation

@MainActor
final class AuthState: ObservableObject {
    @Published private(set) var isLoggedIn: Bool

    init() {
        isLoggedIn = KeychainService.shared.userId != nil
    }

    func logIn(userId: String, token: String) {
        KeychainService.shared.userId      = userId
        KeychainService.shared.accessToken = token
        isLoggedIn = true
    }

    func logOut() {
        KeychainService.shared.clearAll()
        isLoggedIn = false
    }
}
