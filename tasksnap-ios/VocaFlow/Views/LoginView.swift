import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authState: AuthState

    @State private var email      = ""
    @State private var password   = ""
    @State private var isLoading  = false
    @State private var errorMsg: String?
    @State private var logoScale: CGFloat = 0.7

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#1A1A1A"))
                                .frame(width: 90, height: 90)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(logoScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                                logoScale = 1
                            }
                        }

                        Text("VocaFlow")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("Voice to task, instantly")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 72)
                    .padding(.bottom, 52)

                    // Form
                    VStack(spacing: 14) {
                        Group {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()

                            SecureField("Password", text: $password)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )

                        if let error = errorMsg {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        Button(action: signIn) {
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "#1A1A1A"))
                            .foregroundColor(Color.cream)
                            .cornerRadius(14)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.55 : 1)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 28)
                }
            }
        }
    }

    private func signIn() {
        isLoading = true
        errorMsg  = nil

        Task {
            do {
                let session = try await SupabaseService.shared.login(email: email, password: password)
                await MainActor.run {
                    authState.logIn(userId: session.user.id, token: session.access_token)
                }
            } catch {
                await MainActor.run {
                    errorMsg  = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
