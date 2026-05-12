import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authState: AuthState

    @State private var email      = ""
    @State private var password   = ""
    @State private var isLoading  = false
    @State private var errorMsg: String?

    // Entry animations
    @State private var logoOffset: CGFloat = -30
    @State private var logoOpacity: Double = 0
    @State private var formOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    logo
                        .padding(.top, 80)
                        .padding(.bottom, 56)

                    form
                        .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear(perform: animateIn)
    }

    // MARK: - Logo

    private var logo: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dark)
                    .frame(width: 84, height: 84)
                    .shadow(color: Color.dark.opacity(0.25), radius: 20, y: 8)

                Image(systemName: "mic.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(Color.cream)
            }

            VStack(spacing: 6) {
                Text("VocaFlow")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.dark)

                Text("Voice to task, instantly")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.dark.opacity(0.45))
            }
        }
        .offset(y: logoOffset)
        .opacity(logoOpacity)
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 14) {
            inputField(placeholder: "Email", text: $email,
                       keyboard: .emailAddress, secure: false)

            inputField(placeholder: "Password", text: $password,
                       keyboard: .default, secure: true)

            if let err = errorMsg {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            signInButton
                .padding(.top, 8)

            signUpPrompt
                .padding(.top, 16)
        }
        .opacity(formOpacity)
    }

    private func inputField(placeholder: String, text: Binding<String>,
                            keyboard: UIKeyboardType, secure: Bool) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 16))
        .foregroundColor(Color.dark)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dark.opacity(0.10), lineWidth: 1)
        )
    }

    private var signInButton: some View {
        Button(action: signIn) {
            ZStack {
                if isLoading {
                    ProgressView().tint(Color.cream)
                } else {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.cream)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.dark)
                    .shadow(color: Color.dark.opacity(0.3), radius: 12, y: 4)
            )
        }
        .disabled(isLoading || email.isEmpty || password.isEmpty)
        .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.2), value: email.isEmpty || password.isEmpty)
    }

    private var signUpPrompt: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundColor(Color.dark.opacity(0.45))
            Button("Sign up") {
                // Placeholder — link to sign-up flow when ready
            }
            .foregroundColor(Color.dark)
            .fontWeight(.medium)
        }
        .font(.system(size: 14))
    }

    // MARK: - Actions

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            logoOffset  = 0
            logoOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            formOpacity = 1
        }
    }

    private func signIn() {
        isLoading = true
        errorMsg  = nil
        Task {
            do {
                let session = try await SupabaseService.shared.login(email: email, password: password)
                await MainActor.run { authState.logIn(userId: session.user.id, token: session.access_token) }
            } catch {
                await MainActor.run {
                    errorMsg  = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
