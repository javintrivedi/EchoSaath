import SwiftUI
import Combine
import Security

// MARK: - Keychain Helper
private enum KeychainHelper {
    static func save(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveString(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(data, forKey: key)
    }

    static func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Auth View Model
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()

    @Published var isLoggedIn: Bool = false
    @Published var currentUserName: String = ""
    @Published var currentUserEmail: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let emailKey = "echosaath_user_email"
    private let passwordKey = "echosaath_user_password"
    private let nameKey = "echosaath_user_name"
    private let sessionKey = "echosaath_session_active"

    private init() {
        // Restore session
        if UserDefaults.standard.bool(forKey: sessionKey) {
            isLoggedIn = true
            currentUserName = KeychainHelper.loadString(forKey: nameKey) ?? ""
            currentUserEmail = KeychainHelper.loadString(forKey: emailKey) ?? ""
        }
    }

    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String, confirmPassword: String) {
        errorMessage = nil

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true

        // Simulate brief network delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }

            // Store credentials securely in Keychain
            KeychainHelper.saveString(name, forKey: self.nameKey)
            KeychainHelper.saveString(email, forKey: self.emailKey)
            KeychainHelper.saveString(password, forKey: self.passwordKey)

            // Set session
            UserDefaults.standard.set(true, forKey: self.sessionKey)
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

            self.currentUserName = name
            self.currentUserEmail = email
            self.isLoading = false
            self.isLoggedIn = true

            // Send welcome email via SendGrid
            NotificationService.shared.sendWelcomeEmail(name: name, email: email)
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        errorMessage = nil

        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }

            let storedEmail = KeychainHelper.loadString(forKey: self.emailKey)
            let storedPassword = KeychainHelper.loadString(forKey: self.passwordKey)

            guard let storedEmail, let storedPassword,
                  email.lowercased() == storedEmail.lowercased(),
                  password == storedPassword else {
                self.isLoading = false
                self.errorMessage = "Incorrect email or password. Sign up first if you haven't."
                return
            }

            let storedName = KeychainHelper.loadString(forKey: self.nameKey) ?? ""

            UserDefaults.standard.set(true, forKey: self.sessionKey)

            self.currentUserName = storedName
            self.currentUserEmail = storedEmail
            self.isLoading = false
            self.isLoggedIn = true
        }
    }

    // MARK: - Logout
    func logout() {
        UserDefaults.standard.set(false, forKey: sessionKey)
        currentUserName = ""
        currentUserEmail = ""
        isLoggedIn = false
    }

    // MARK: - Helpers
    private func validateEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
