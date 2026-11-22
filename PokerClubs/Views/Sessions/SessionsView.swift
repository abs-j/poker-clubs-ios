import SwiftUI

struct SessionsView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = SessionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Sessions recorded in live mode will appear here.")
                    )
                } else {
                    sessionList
                }
            }
            .navigationTitle("Sessions")
            .task { await vm.load() }
            .refreshable { await vm.load() }
        }
    }

    private var sessionList: some View {
        List {
            ForEach(vm.sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session, currency: appVM.currency)
                } label: {
                    SessionListRow(session: session, currency: appVM.currency)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let session = vm.sessions[index]
                    Task { await vm.deleteSession(id: session.id) }
                }
            }
        }
        .groupedListStyle()
    }
}

struct SessionListRow: View {
    let session: PokerSession
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.date.asDisplayDate)
                    .font(.subheadline.bold())
                Spacer()
                if let gameNumber = session.gameNumber {
                    Text("Game #\(gameNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Label("\(session.players.count) players", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let winner = session.biggestWinner {
                    Text("\(winner.name) +\(winner.resolvedNet.asCurrency(currency))")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    let session: PokerSession
    let currency: String

    var body: some View {
        List {
            Section("Info") {
                LabeledContent("Date", value: session.date.asDisplayDate)
                if let gameNumber = session.gameNumber {
                    LabeledContent("Game #", value: "\(gameNumber)")
                }
                LabeledContent("Players", value: "\(session.players.count)")
                LabeledContent("Total Buy In", value: session.totalBuyIn.asCurrency(currency))
            }

            Section("Results") {
                ForEach(session.players.sorted { $0.resolvedNet > $1.resolvedNet }) { player in
                    HStack {
                        Text(player.name)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(player.resolvedNet.asCurrency(currency))
                                .font(.subheadline.bold())
                                .foregroundStyle(player.resolvedNet >= 0 ? .green : .red)
                            Text("in: \(player.buyIn.asCurrency(currency))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let notes = session.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .groupedListStyle()
        .navigationTitle(session.date.asDisplayDate)
        .navBarInline()
    }
}
