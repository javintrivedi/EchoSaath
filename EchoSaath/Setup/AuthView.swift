import SwiftUI

struct AuthView: View {
    @State private var selection: AuthMode = .login

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Picker("Authentication", selection: $selection) {
                    Text("Login").tag(AuthMode.login)
                    Text("Sign Up").tag(AuthMode.signup)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch selection {
                    case .login:
                        LoginFormView()
                    case .signup:
                        SignupFormView()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(selection == .login ? "Login" : "Sign Up")
    }
}

private enum AuthMode { case login, signup }

private struct LoginFormView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email").font(.caption).foregroundStyle(.secondary)
                TextField("name@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password").font(.caption).foregroundStyle(.secondary)
                SecureField("••••••••", text: $password)
                    .textContentType(.password)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: login) {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("Login").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isLoading)
        }
    }

    private func login() {
        errorMessage = nil
        guard validateEmail(email), !password.isEmpty else {
            errorMessage = "Please enter a valid email and password."
            return
        }
        isLoading = true
        // TODO: Integrate real auth API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            // Persist auth/onboarding completion so the app shows Home next time
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            // Navigate to RootView by replacing the window's root controller
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                window.rootViewController = UIHostingController(rootView: RootView())
                window.makeKeyAndVisible()
            }
        }
    }
}

private struct SignupFormView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name").font(.caption).foregroundStyle(.secondary)
                TextField("Jane Doe", text: $name)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Email").font(.caption).foregroundStyle(.secondary)
                TextField("name@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password").font(.caption).foregroundStyle(.secondary)
                SecureField("Create a password", text: $password)
                    .textContentType(.newPassword)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password").font(.caption).foregroundStyle(.secondary)
                SecureField("Re-enter password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: signup) {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("Create Account").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isLoading)
        }
    }

    private func signup() {
        errorMessage = nil
        guard !name.isEmpty, validateEmail(email), password.count >= 6, password == confirmPassword else {
            errorMessage = "Please complete all fields. Password must be at least 6 characters and match."
            return
        }
        isLoading = true
        // TODO: Integrate real sign-up API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
        }
    }
}

// MARK: - Helpers
private func validateEmail(_ email: String) -> Bool {
    let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
    return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
}

#Preview {
    NavigationStack { AuthView() }
}
