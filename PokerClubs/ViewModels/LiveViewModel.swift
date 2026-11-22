import Foundation
import Observation

@Observable
final class LiveViewModel {
    var activity: LiveActivityResponse?
    var role: LiveSessionRole?
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    var session: LiveSession? { activity?.session }
    var entries: [LiveEntry] { activity?.allEntries.reversed() ?? [] }
    var standings: [LiveStanding] {
        (activity?.allStandings ?? []).sorted { abs($0.resolvedNet) > abs($1.resolvedNet) }
    }
    var hasOpenSession: Bool { session?.isOpen == true }
    var canManage: Bool { role?.resolvedIsHost == true }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        async let activityTask: LiveActivityResponse = api.get("/api/poker/live-activity")
        async let roleTask: LiveSessionRole = api.get("/api/poker/live-session/role")
        do {
            let (a, r) = try await (activityTask, roleTask)
            activity = a
            role = r
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func startSession() async {
        errorMessage = nil
        do {
            let _: StartSessionResponse = try await api.post("/api/poker/live-session/start", body: EmptyBody())
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func endSession() async {
        errorMessage = nil
        do {
            try await api.postVoid("/api/poker/live-session/end")
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func reopenSession() async {
        errorMessage = nil
        do {
            let _: StartSessionResponse = try await api.post("/api/poker/live-session/reopen", body: EmptyBody())
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func addEntry(playerName: String, type: String, amount: Double) async {
        errorMessage = nil
        do {
            let _: AddLiveEntryResponse = try await api.post("/api/poker/live-activity", body: AddLiveEntryBody(
                amount: amount,
                type: type,
                attributedPlayer: playerName.isEmpty ? nil : playerName
            ))
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteEntry(id: String, reason: String) async {
        errorMessage = nil
        do {
            try await api.delete("/api/poker/live-activity/\(id)", body: DeleteLiveEntryBody(comment: reason))
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func setHost(name: String) async {
        errorMessage = nil
        do {
            let _: LiveSessionRole = try await api.post("/api/poker/live-session/host", body: SetHostBody(name: name))
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct EmptyBody: Encodable {}
