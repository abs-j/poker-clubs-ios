import SwiftUI

struct OverviewView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = OverviewViewModel()
    @State private var showClubSwitcher = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                } else {
                    content
                }
            }
            .navigationTitle(appVM.activeClub?.name ?? "Overview")
            .navBarLarge()
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button { Task { await vm.load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .trailingBar) {
                    if appVM.clubs.count > 1 {
                        Button { showClubSwitcher = true } label: {
                            Image(systemName: "arrow.left.arrow.right.circle")
                        }
                    }
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $showClubSwitcher) {
                ClubSwitcherSheet()
            }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let totals = vm.totals {
                    statsSection(totals: totals)
                }
                if !vm.leaderboard.isEmpty {
                    leaderboardSection
                }
                if !vm.recentSessions.isEmpty {
                    recentSessionsSection
                }
            }
            .padding()
        }
        .refreshable { await vm.load() }
    }

    private func statsSection(totals: DashboardTotals) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Club Stats").font(.headline)
            HStack(spacing: 12) {
                StatCard(label: "Sessions", value: "\(totals.sessions ?? 0)", icon: "calendar")
                StatCard(label: "Players", value: "\(totals.players ?? 0)", icon: "person.2")
            }
        }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard").font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(vm.leaderboard.prefix(10).enumerated()), id: \.element.id) { index, player in
                    LeaderboardRow(player: player, rank: index + 1, currency: appVM.currency)
                    if index < min(vm.leaderboard.count, 10) - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions").font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(vm.recentSessions.enumerated()), id: \.element.id) { index, session in
                    SessionRow(session: session, currency: appVM.currency)
                    if index < vm.recentSessions.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title2.bold())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity)
    }
}

struct LeaderboardRow: View {
    let player: PlayerStanding
    let rank: Int
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)
            Text(player.name).font(.subheadline).lineLimit(1)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(player.profit.asCurrency(currency))
                    .font(.subheadline.bold())
                    .foregroundStyle(player.profit >= 0 ? .green : .red)
                if let games = player.gamesPlayed {
                    Text("\(games) games").font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SessionRow: View {
    let session: PokerSession
    let currency: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date.asDisplayDate).font(.subheadline)
                Text("\(session.players.count) players").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let winner = session.biggestWinner {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(winner.name).font(.caption).foregroundStyle(.secondary)
                    Text(winner.resolvedNet.asCurrency(currency))
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ClubSwitcherSheet: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(appVM.clubs) { club in
                Button {
                    Task { await appVM.switchClub(slug: club.slug); dismiss() }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(club.name).foregroundStyle(.primary)
                            Text(club.role.capitalized).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if club.id == appVM.activeClub?.id {
                            Image(systemName: "checkmark").foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("Switch Club")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
