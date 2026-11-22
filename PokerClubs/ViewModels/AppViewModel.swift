import Foundation
import Observation

@Observable
final class AppViewModel {
    var session: MemberSession?
    var me: MeResponse?
    var isLoading = true
    var isAuthenticated = false

    private let api = APIClient.shared

    var activeClub: ActiveClub? { me?.active }
    var currency: String { activeClub?.currency ?? "USD" }
    var clubs: [ClubMembership] { me?.clubs ?? [] }
    var user: UserInfo? { me?.user }

    func bootstrap() async {
        await checkSession()
    }

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let s: MemberSession = try await api.get("/api/auth/member/session")
            session = s
            isAuthenticated = s.authenticated
            if s.authenticated {
                await loadMe()
            }
        } catch {
            isAuthenticated = false
        }
    }

    func loadMe() async {
        do {
            me = try await api.get("/api/clubs/me")
        } catch {
            // ignore — session check handles auth state
        }
    }

    func switchClub(slug: String) async {
        do {
            try await api.postVoid("/api/clubs/active", body: SetActiveClubBody(slug: slug))
            await loadMe()
        } catch {}
    }

    func signOut() async {
        try? await api.postVoid("/api/identity/sign-out")
        api.clearCookies()
        session = nil
        me = nil
        isAuthenticated = false
    }
}
