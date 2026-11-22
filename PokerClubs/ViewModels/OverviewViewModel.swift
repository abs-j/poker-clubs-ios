import Foundation
import Observation

@Observable
final class OverviewViewModel {
    var dashboard: PokerDashboard?
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    var leaderboard: [PlayerStanding] { dashboard?.leaderboard ?? [] }
    var recentSessions: [PokerSession] { Array((dashboard?.allSessions ?? []).prefix(5)) }
    var totals: DashboardTotals? { dashboard?.totals }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            dashboard = try await api.get("/api/poker/dashboard")
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
