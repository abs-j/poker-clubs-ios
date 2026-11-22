import Foundation
import Observation

@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var name = ""
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    func signIn() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await api.postVoid("/api/identity/sign-in/email", body: SignInBody(email: email.trimmingCharacters(in: .whitespaces), password: password))
        } catch let e as APIError {
            errorMessage = e.errorDescription
            throw e
        }
    }

    func signUp() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await api.postVoid("/api/identity/sign-up/email", body: SignUpBody(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                callbackURL: "https://pokerclubs.abhayjhade.com/dashboard",
                termsAcceptedAt: ISO8601DateFormatter().string(from: Date())
            ))
        } catch let e as APIError {
            errorMessage = e.errorDescription
            throw e
        }
    }

    func requestPasswordReset() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        struct Body: Encodable { let email: String; let redirectTo: String }
        do {
            try await api.postVoid("/api/identity/request-password-reset", body: Body(
                email: email.trimmingCharacters(in: .whitespaces),
                redirectTo: "https://pokerclubs.abhayjhade.com/reset-password"
            ))
        } catch let e as APIError {
            errorMessage = e.errorDescription
            throw e
        }
    }
}
