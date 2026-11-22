import Foundation
import Observation

@Observable
final class ClubViewModel {
    var members: [ClubMember] = []
    var invites: [ClubInvite] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    func loadMembers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let r: MembersResponse = try await api.get("/api/clubs/current/members")
            members = r.members
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func loadInvites() async {
        do {
            let r: InvitesResponse = try await api.get("/api/clubs/current/invites")
            invites = r.invites
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func createInvite(role: String, expiresInDays: Int, maxUses: Int?) async throws -> ClubInvite {
        struct Response: Decodable { let invite: ClubInvite }
        let r: Response = try await api.post("/api/clubs/current/invites", body: CreateInviteBody(
            role: role,
            expiresInDays: expiresInDays,
            maxUses: maxUses
        ))
        invites.append(r.invite)
        return r.invite
    }

    func revokeInvite(id: String) async {
        do {
            try await api.delete("/api/clubs/current/invites/\(id)")
            invites.removeAll { $0.id == id }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func removeMember(playerId: String) async {
        do {
            try await api.delete("/api/clubs/current/members/\(playerId)")
            members.removeAll { $0.id == playerId }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func changeMemberRole(playerId: String, role: String) async {
        struct Body: Encodable { let role: String }
        struct Resp: Decodable { let playerId: String; let role: String }
        do {
            let _: Resp = try await api.patch("/api/clubs/current/members/\(playerId)", body: Body(role: role))
            if let idx = members.firstIndex(where: { $0.id == playerId }) {
                members[idx] = ClubMember(id: members[idx].id, name: members[idx].name, role: role, claimed: members[idx].claimed, userId: members[idx].userId)
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func createClub(name: String, playerName: String, currency: String, timezone: String) async throws -> ClubMembership {
        let r: CreateClubResponse = try await api.post("/api/clubs", body: CreateClubBody(
            name: name,
            playerName: playerName,
            currency: currency,
            timezone: timezone
        ))
        return r.club
    }

    func previewInvite(code: String) async throws -> InvitePreview {
        try await api.get("/api/invites/\(code)")
    }

    func acceptInvite(code: String, name: String, claimPlayerId: String?) async throws -> AcceptInviteResponse {
        try await api.post("/api/invites/\(code)/accept", body: AcceptInviteBody(
            claimPlayerId: claimPlayerId,
            name: name
        ))
    }
}
