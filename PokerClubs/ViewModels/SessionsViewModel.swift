import Foundation
import Observation

@Observable
final class SessionsViewModel {
    var sessions: [PokerSession] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let r: SessionsResponse = try await api.get("/api/clubs/current/sessions")
            sessions = r.sessions.sorted { $0.date > $1.date }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteSession(id: String) async {
        do {
            try await api.delete("/api/clubs/current/sessions/\(id)")
            sessions.removeAll { $0.id == id }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
