import SwiftUI

struct PlayersView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = OverviewViewModel()
    @State private var searchText = ""
    @State private var sortBy: SortOption = .profit

    enum SortOption: String, CaseIterable {
        case profit = "Profit"
        case games = "Games"
        case name = "Name"
    }

    private var players: [PlayerStanding] {
        var list = vm.leaderboard
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortBy {
        case .profit: return list.sorted { $0.profit > $1.profit }
        case .games:  return list.sorted { ($0.gamesPlayed ?? 0) > ($1.gamesPlayed ?? 0) }
        case .name:   return list.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if players.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Players" : "No Results",
                        systemImage: "person.2",
                        description: Text(searchText.isEmpty ? "Players will appear here after sessions are recorded." : "Try a different search.")
                    )
                } else {
                    playerList
                }
            }
            .navigationTitle("Players")
            .searchable(text: $searchText, prompt: "Search players")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortBy = option
                            } label: {
                                Label(option.rawValue, systemImage: sortBy == option ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
        }
    }

    private var playerList: some View {
        List {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                NavigationLink {
                    PlayerDetailView(player: player, currency: appVM.currency)
                } label: {
                    PlayerRow(player: player, rank: index + 1, currency: appVM.currency)
                }
            }
        }
    }
}

struct PlayerRow: View {
    let player: PlayerStanding
    let rank: Int
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline)
                if let games = player.gamesPlayed {
                    Text("\(games) games")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(player.profit.asCurrency(currency))
                    .font(.subheadline.bold())
                    .foregroundStyle(player.profit >= 0 ? .green : .red)
                if let winPct = player.winPercentage {
                    Text("\(Int(winPct))% win")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlayerDetailView: View {
    let player: PlayerStanding
    let currency: String

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    Text(player.name)
                        .font(.title2.bold())
                    Text(player.profit.asCurrency(currency))
                        .font(.title.bold())
                        .foregroundStyle(player.profit >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Stats") {
                if let games = player.gamesPlayed {
                    LabeledContent("Games Played", value: "\(games)")
                }
                if let buyIn = player.buyInTotal {
                    LabeledContent("Total Buy In", value: buyIn.asCurrency(currency))
                }
                if let cashOut = player.cashOutTotal {
                    LabeledContent("Total Cash Out", value: cashOut.asCurrency(currency))
                }
                if let winPct = player.winPercentage {
                    LabeledContent("Win Rate", value: "\(Int(winPct))%")
                }
                if let maxWin = player.maxWin {
                    LabeledContent("Best Session", value: maxWin.asCurrency(currency))
                }
                if let maxLoss = player.maxLoss {
                    LabeledContent("Worst Session", value: maxLoss.asCurrency(currency))
                }
            }
        }
        .navigationTitle(player.name)
    }
}
