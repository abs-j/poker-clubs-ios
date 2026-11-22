import SwiftUI

struct AccountView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showSignOutConfirm = false
    @State private var showClubManagement = false
    @State private var showJoinClub = false
    @State private var showCreateClub = false

    var body: some View {
        NavigationStack {
            List {
                userSection
                activeClubSection
                clubActionsSection
                signOutSection
            }
            .groupedListStyle()
            .navigationTitle("Account")
            .sheet(isPresented: $showClubManagement) {
                ClubManagementView()
            }
            .sheet(isPresented: $showJoinClub) {
                JoinClubView(onJoined: {
                    Task { await appVM.loadMe() }
                })
            }
            .sheet(isPresented: $showCreateClub) {
                CreateClubView(onCreated: {
                    Task { await appVM.loadMe() }
                })
            }
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task { await appVM.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var userSection: some View {
        Section {
            if let user = appVM.user {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name).font(.headline)
                        Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var activeClubSection: some View {
        Section("Active Club") {
            if let club = appVM.activeClub {
                LabeledContent("Club", value: club.name)
                LabeledContent("Your Role", value: club.role.capitalized)
                if let currency = club.currency {
                    LabeledContent("Currency", value: currency)
                }
                if let tz = club.timezone {
                    LabeledContent("Timezone", value: tz)
                }
            } else {
                Text("No active club").foregroundStyle(.secondary)
            }
        }
    }

    private var clubActionsSection: some View {
        Section("Clubs") {
            if appVM.activeClub != nil {
                Button {
                    showClubManagement = true
                } label: {
                    Label("Manage Club", systemImage: "person.2.badge.gearshape")
                }
            }

            if appVM.clubs.count > 1 {
                NavigationLink {
                    AllClubsView()
                } label: {
                    Label("All Clubs (\(appVM.clubs.count))", systemImage: "list.bullet")
                }
            }

            Button {
                showJoinClub = true
            } label: {
                Label("Join Club with Code", systemImage: "person.badge.plus")
            }

            Button {
                showCreateClub = true
            } label: {
                Label("Create New Club", systemImage: "plus.circle")
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                    Spacer()
                }
            }
        }
    }
}

struct AllClubsView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        List(appVM.clubs) { club in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name).font(.subheadline)
                    Text(club.role.capitalized).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if club.id == appVM.activeClub?.id {
                    Text("Active")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Button("Switch") {
                        Task { await appVM.switchClub(slug: club.slug) }
                    }
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("All Clubs")
        .groupedListStyle()
    }
}
