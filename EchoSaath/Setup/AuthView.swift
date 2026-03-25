import SwiftUI

struct AuthView: View {
    @ObservedObject var authVM = AuthViewModel.shared
    @State private var selection: AuthMode = .login

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo area
                    VStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )

                        Text("EchoSaath")
                            .font(.title.bold())
                            .foregroundStyle(.primary)

                        Text("Your safety companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Segmented picker
                    Picker("Authentication", selection: $selection) {
                        Text("Login").tag(AuthMode.login)
                        Text("Sign Up").tag(AuthMode.signup)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Form card
                    Group {
                        switch selection {
                        case .login:
                            LoginFormView()
                        case .signup:
                            SignupFormView()
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Error message
                    if let error = authVM.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle(selection == .login ? "Welcome Back" : "Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(authVM.isLoading)
        .animation(.easeInOut(duration: 0.25), value: authVM.errorMessage)
    }
}

private enum AuthMode { case login, signup }

// MARK: - Login Form
private struct LoginFormView: View {
    @ObservedObject var authVM = AuthViewModel.shared
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email").font(.caption.bold()).foregroundStyle(.secondary)
                TextField("name@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Password").font(.caption.bold()).foregroundStyle(.secondary)
                SecureField("••••••••", text: $password)
                    .textContentType(.password)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            Button(action: { authVM.login(email: email, password: password) }) {
                HStack(spacing: 8) {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Login").fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .pink.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .disabled(authVM.isLoading)
        }
    }
}

// MARK: - Signup Form
private struct SignupFormView: View {
    @ObservedObject var authVM = AuthViewModel.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name").font(.caption.bold()).foregroundStyle(.secondary)
                TextField("Jane Doe", text: $name)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Email").font(.caption.bold()).foregroundStyle(.secondary)
                TextField("name@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Password").font(.caption.bold()).foregroundStyle(.secondary)
                SecureField("Minimum 6 characters", text: $password)
                    .textContentType(.newPassword)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password").font(.caption.bold()).foregroundStyle(.secondary)
                SecureField("Re-enter password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            Button(action: {
                authVM.signUp(name: name, email: email, password: password, confirmPassword: confirmPassword)
            }) {
                HStack(spacing: 8) {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Create Account").fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .pink.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .disabled(authVM.isLoading)
        }
    }
}

#Preview {
    NavigationStack {
        AuthView()
    }
}
