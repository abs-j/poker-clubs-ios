import Foundation

// MARK: - Auth & Session

struct MemberSession: Codable {
    let authenticated: Bool
    let memberName: String?
    let platformAdmin: Bool
    let club: SessionClub?
}

struct SessionClub: Codable {
    let id: String
    let slug: String
    let name: String
    let role: String
}

// MARK: - Me / User

struct MeResponse: Codable {
    let user: UserInfo
    let clubs: [ClubMembership]
    let active: ActiveClub?
}

struct UserInfo: Codable {
    let id: String
    let name: String
    let email: String
}

struct ClubMembership: Codable, Identifiable {
    let id: String
    let slug: String
    let name: String
    let role: String
    let currency: String?
}

struct ActiveClub: Codable {
    let id: String
    let slug: String
    let name: String
    let role: String
    let currency: String?
    let timezone: String?
}

// MARK: - Dashboard

struct PokerDashboard: Codable {
    let leaderboard: [PlayerStanding]?
    let sessions: [PokerSession]?
    let nights: [PokerSession]?
    let monthly: [MonthlySummary]?
    let quarterly: [QuarterlySummary]?
    let tournaments: [TournamentSnapshot]?
    let totals: DashboardTotals?
    let title: String?

    var allSessions: [PokerSession] { sessions ?? nights ?? [] }
}

struct DashboardTotals: Codable {
    let sessions: Int?
    let players: Int?
    let buyIn: Double?
    let cashOut: Double?
}

struct PlayerStanding: Codable, Identifiable {
    let rank: Int?
    let name: String
    let buyInTotal: Double?
    let cashOutTotal: Double?
    let profitTotal: Double?
    let gamesPlayed: Int?
    let winPercentage: Double?
    let maxWin: Double?
    let maxLoss: Double?
    let isClubContributor: Bool?

    var id: String { name }

    var profit: Double { profitTotal ?? ((cashOutTotal ?? 0) - (buyInTotal ?? 0)) }
}

struct PokerSession: Codable, Identifiable {
    let id: String
    let date: String
    let gameNumber: Int?
    let players: [SessionPlayer]
    let notes: String?
    let jackpot: Double?

    var biggestWinner: SessionPlayer? {
        players.max { ($0.net ?? 0) < ($1.net ?? 0) }
    }

    var totalBuyIn: Double {
        players.reduce(0) { $0 + $1.buyIn }
    }
}

struct SessionPlayer: Codable, Identifiable {
    let name: String
    let buyIn: Double
    let cashOut: Double?
    let net: Double?

    var id: String { name }
    var resolvedNet: Double { net ?? ((cashOut ?? 0) - buyIn) }
}

struct MonthlySummary: Codable, Identifiable {
    let month: String
    let sessionCount: Int?
    let sessions: Int?
    let totalBuyIn: Double?
    let uniquePlayers: Int?
    let players: Int?

    var id: String { month }
    var resolvedSessionCount: Int { sessionCount ?? sessions ?? 0 }
    var resolvedPlayers: Int { uniquePlayers ?? players ?? 0 }
}

struct QuarterlySummary: Codable, Identifiable {
    let quarter: String
    let sessionCount: Int?
    let totalBuyIn: Double?

    var id: String { quarter }
}

struct TournamentSnapshot: Codable, Identifiable {
    let id: String
    let name: String?
    let date: String
    let players: [TournamentSnapshotPlayer]?
    let totalCollected: Double?
}

struct TournamentSnapshotPlayer: Codable, Identifiable {
    let name: String
    let buyIn: Double?
    let payout: Double?
    let profit: Double?

    var id: String { name }
}

// MARK: - Live Activity

struct LiveActivityResponse: Codable {
    let session: LiveSession?
    let entries: [LiveEntry]?
    let standings: [LiveStanding]?
    let players: [LiveStanding]?

    var allEntries: [LiveEntry] { entries ?? [] }
    var allStandings: [LiveStanding] { standings ?? players ?? [] }
}

struct LiveSession: Codable {
    let id: String
    let date: String
    let status: String
    let hostName: String?
    let bankName: String?

    var isOpen: Bool { status == "open" }
}

struct LiveEntry: Codable, Identifiable {
    let id: String
    let playerName: String
    let type: String
    let amount: Double
    let createdAt: String
    let comment: String?
    let attributedPlayer: String?
}

struct LiveStanding: Codable, Identifiable {
    let name: String
    let buyIn: Double
    let cashOut: Double?
    let net: Double?

    var id: String { name }
    var resolvedNet: Double { net ?? ((cashOut ?? 0) - buyIn) }
    var isPositive: Bool { resolvedNet >= 0 }
}

struct LiveSessionRole: Codable {
    let status: String?
    let isHost: Bool?
    let hostName: String?

    var resolvedIsHost: Bool { isHost ?? (status == "host") }
}

struct StartSessionResponse: Codable {
    let session: LiveSession?
}

struct LiveActivityHistoryResponse: Codable {
    let sessions: [PokerSession]?
}

// MARK: - Sessions (History)

struct SessionsResponse: Codable {
    let sessions: [PokerSession]
}

struct SessionEditResponse: Codable {
    let id: String
    let date: String
    let players: [SessionPlayer]
}

// MARK: - Members

struct MembersResponse: Codable {
    let members: [ClubMember]
}

struct ClubMember: Codable, Identifiable {
    let id: String
    let name: String
    let role: String
    let claimed: Bool?
    let userId: String?
}

// MARK: - Invites

struct InvitesResponse: Codable {
    let invites: [ClubInvite]
}

struct ClubInvite: Codable, Identifiable {
    let id: String
    let code: String
    let role: String
    let expiresAt: String?
    let maxUses: Int?
    let uses: Int?
}

struct InvitePreview: Codable {
    let club: InviteClub
    let role: String
    let claimable: [ClaimablePlayer]
}

struct InviteClub: Codable {
    let id: String
    let name: String
    let slug: String
}

struct ClaimablePlayer: Codable, Identifiable {
    let id: String
    let name: String
}

// MARK: - Tournaments

struct TournamentsResponse: Codable {
    let tournaments: [Tournament]
}

struct Tournament: Codable, Identifiable {
    let id: String
    let date: String
    let name: String?
    let totalCollected: Double?
    let players: [TournamentPlayer]
}

struct TournamentPlayer: Codable, Identifiable {
    let id: String
    let name: String
    let buyIn: Double
    let position: Int?
    let payout: Double?

    var profit: Double? {
        guard let payout else { return nil }
        return payout - buyIn
    }
}

// MARK: - Request Bodies

struct SignInBody: Encodable {
    let email: String
    let password: String
}

struct SignUpBody: Encodable {
    let name: String
    let email: String
    let password: String
    let callbackURL: String
    let termsAcceptedAt: String
}

struct SetActiveClubBody: Encodable {
    let slug: String
}

struct CreateClubBody: Encodable {
    let name: String
    let playerName: String
    let currency: String
    let timezone: String
}

struct CreateClubResponse: Codable {
    let club: ClubMembership
}

struct CreateInviteBody: Encodable {
    let role: String
    let expiresInDays: Int
    let maxUses: Int?
}

struct AcceptInviteBody: Encodable {
    let claimPlayerId: String?
    let name: String
}

struct AcceptInviteResponse: Codable {
    let club: ClubMembership
}

struct AddLiveEntryBody: Encodable {
    let amount: Double
    let type: String
    let attributedPlayer: String?
}

struct AddLiveEntryResponse: Codable {
    let entry: LiveEntry?
}

struct UpdateLiveEntryBody: Encodable {
    let amount: Double
    let type: String
    let comment: String
    let attributedPlayer: String?
}

struct DeleteLiveEntryBody: Encodable {
    let comment: String
}

struct SetHostBody: Encodable {
    let name: String
}

// MARK: - Formatting Helpers

extension Double {
    func asCurrency(_ code: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code ?? "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(code ?? "$")\(self)"
    }

    var signedString: String {
        self >= 0 ? "+\(self)" : "\(self)"
    }
}

extension String {
    var asDisplayDate: String {
        var date: Date?
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        date = iso.date(from: self)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: self)
        }
        guard let d = date else { return self }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: d)
    }
}
