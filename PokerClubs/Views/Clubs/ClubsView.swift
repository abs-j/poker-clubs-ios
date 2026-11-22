import SwiftUI

// MARK: - Club Management

struct ClubManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ClubViewModel()
    @State private var selectedTab = 0
    @State private var showCreateInvite = false
    @State private var showInviteShare: ClubInvite?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    Text("Members").tag(0)
                    Text("Invites").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    membersTab
                } else {
                    invitesTab
                }
            }
            .navigationTitle("Manage Club")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    if selectedTab == 1 {
                        Button { showCreateInvite = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task {
                await vm.loadMembers()
                await vm.loadInvites()
            }
            .sheet(isPresented: $showCreateInvite) {
                CreateInviteView(vm: vm)
            }
            .sheet(item: $showInviteShare) { invite in
                InviteShareView(invite: invite)
            }
        }
    }

    private var membersTab: some View {
        List {
            if vm.isLoading {
                ProgressView()
            } else {
                ForEach(vm.members) { member in
                    MemberRow(member: member)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await vm.removeMember(playerId: member.id) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                }
            }
        }
        .groupedListStyle()
    }

    private var invitesTab: some View {
        List {
            ForEach(vm.invites) { invite in
                InviteRow(invite: invite) { showInviteShare = invite }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await vm.revokeInvite(id: invite.id) }
                        } label: {
                            Label("Revoke", systemImage: "trash")
                        }
                    }
            }

            if vm.invites.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "No Invites",
                    systemImage: "envelope",
                    description: Text("Create an invite link to add members.")
                )
            }
        }
        .groupedListStyle()
    }
}

struct MemberRow: View {
    let member: ClubMember

    var body: some View {
        HStack {
            Image(systemName: member.claimed == true ? "person.fill" : "person")
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(.subheadline)
                Text(member.role.capitalized).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if member.claimed == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InviteRow: View {
    let invite: ClubInvite
    let onShare: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.role.capitalized + " invite").font(.subheadline)
                HStack(spacing: 8) {
                    if let uses = invite.uses, let max = invite.maxUses {
                        Text("\(uses)/\(max) uses").font(.caption).foregroundStyle(.secondary)
                    }
                    if let expires = invite.expiresAt {
                        Text("Expires \(expires.asDisplayDate)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Button { onShare() } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Invite

struct CreateInviteView: View {
    @Bindable var vm: ClubViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var role = "member"
    @State private var expiresInDays = 7
    @State private var hasMaxUses = false
    @State private var maxUses = 1
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    Picker("Role", selection: $role) {
                        Text("Member").tag("member")
                        Text("Admin").tag("admin")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Expiry") {
                    Picker("Expires in", selection: $expiresInDays) {
                        Text("1 day").tag(1)
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("Never").tag(365)
                    }
                }
                Section("Usage Limit") {
                    Toggle("Limit uses", isOn: $hasMaxUses)
                    if hasMaxUses {
                        Stepper("Max uses: \(maxUses)", value: $maxUses, in: 1...100)
                    }
                }
            }
            .navigationTitle("Create Invite")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        isCreating = true
                        Task {
                            do {
                                _ = try await vm.createInvite(role: role, expiresInDays: expiresInDays, maxUses: hasMaxUses ? maxUses : nil)
                                dismiss()
                            } catch {}
                            isCreating = false
                        }
                    }
                    .disabled(isCreating)
                    .bold()
                }
            }
        }
    }
}

// MARK: - Invite Share

struct InviteShareView: View {
    let invite: ClubInvite
    @Environment(\.dismiss) private var dismiss

    private var inviteURL: String {
        "https://pokerclubs.abhayjhade.com/join/\(invite.code)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Invite Link").font(.title2.bold())
                    Text(inviteURL)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    ShareLink(item: inviteURL) {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        copyToClipboard(inviteURL)
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Share Invite")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Join Club

struct JoinClubView: View {
    let onJoined: () -> Void

    @State private var vm = ClubViewModel()
    @State private var code = ""
    @State private var preview: InvitePreview?
    @State private var playerName = ""
    @State private var selectedClaimId: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Invite Code") {
                    TextField("Paste invite code or URL", text: $code)
                        .autocorrectionDisabled()
                        .noAutocap()
                    Button("Preview") { Task { await loadPreview() } }
                        .disabled(code.isEmpty || isLoading)
                }

                if let preview {
                    Section("Club") {
                        LabeledContent("Club", value: preview.club.name)
                        LabeledContent("Role", value: preview.role.capitalized)
                    }

                    if !preview.claimable.isEmpty {
                        Section("Claim existing player (optional)") {
                            Picker("Player", selection: $selectedClaimId) {
                                Text("New player").tag(nil as String?)
                                ForEach(preview.claimable) { player in
                                    Text(player.name).tag(player.id as String?)
                                }
                            }
                        }
                    }

                    if selectedClaimId == nil {
                        Section("Your name in this club") {
                            TextField("Display name", text: $playerName)
                        }
                    }

                    if let error = errorMessage {
                        Section { Text(error).foregroundStyle(.red).font(.footnote) }
                    }

                    Section {
                        Button("Join Club") { Task { await joinClub(preview: preview) } }
                            .disabled(isLoading || (selectedClaimId == nil && playerName.isEmpty))
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Join Club")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func extractCode(_ input: String) -> String {
        if let url = URL(string: input), let last = url.pathComponents.last, !last.isEmpty {
            return last
        }
        return input.trimmingCharacters(in: .whitespaces)
    }

    private func loadPreview() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            preview = try await vm.previewInvite(code: extractCode(code))
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func joinClub(preview: InvitePreview) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let name = selectedClaimId.flatMap { id in preview.claimable.first { $0.id == id }?.name } ?? playerName
        do {
            _ = try await vm.acceptInvite(code: extractCode(code), name: name, claimPlayerId: selectedClaimId)
            onJoined(); dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Create Club

struct CreateClubView: View {
    let onCreated: () -> Void

    @State private var vm = ClubViewModel()
    @State private var clubName = ""
    @State private var playerName = ""
    @State private var currency = "USD"
    @State private var timezone = TimeZone.current.identifier
    @State private var isCreating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let currencies = ["USD", "AUD", "GBP", "EUR", "NZD", "CAD", "SGD"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Club Details") {
                    TextField("Club name", text: $clubName)
                    TextField("Your player name", text: $playerName)
                }
                Section("Settings") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }
                if let error = errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("Create Club")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true; errorMessage = nil
                            do {
                                _ = try await vm.createClub(name: clubName, playerName: playerName, currency: currency, timezone: timezone)
                                onCreated(); dismiss()
                            } catch {
                                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(isCreating || clubName.isEmpty || playerName.isEmpty)
                    .bold()
                }
            }
        }
    }
}
