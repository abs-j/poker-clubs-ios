import SwiftUI

struct LiveView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = LiveViewModel()
    @State private var showAddEntry = false
    @State private var showEndConfirm = false
    @State private var entryToDelete: LiveEntry?
    @State private var deleteReason = ""
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.session == nil {
                    noSessionView
                } else {
                    sessionView
                }
            }
            .navigationTitle("Live Game")
            .navBarLarge()
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button { Task { await vm.load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .trailingBar) {
                    if vm.hasOpenSession && vm.canManage {
                        Button(role: .destructive) { showEndConfirm = true } label: {
                            Text("End Session")
                        }
                    }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .sheet(isPresented: $showAddEntry, onDismiss: { Task { await vm.load() } }) {
                AddEntryView(vm: vm, currency: appVM.currency)
            }
            .confirmationDialog("End this session?", isPresented: $showEndConfirm, titleVisibility: .visible) {
                Button("End Session", role: .destructive) { Task { await vm.endSession() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All entries will be finalised.")
            }
            .alert("Delete Entry", isPresented: $showDeleteAlert) {
                TextField("Reason (required)", text: $deleteReason)
                Button("Delete", role: .destructive) {
                    guard let entry = entryToDelete, !deleteReason.isEmpty else { return }
                    Task { await vm.deleteEntry(id: entry.id, reason: deleteReason) }
                    deleteReason = ""
                }
                Button("Cancel", role: .cancel) { deleteReason = "" }
            } message: {
                Text("Please provide a reason for deleting this entry.")
            }
        }
    }

    private var noSessionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "play.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Active Session").font(.title2.bold())
            Text("Start a new session to begin recording buy-ins and cash-outs.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if vm.canManage {
                Button {
                    Task { await vm.startSession() }
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal, 40)
            }
            if let error = vm.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var sessionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                sessionHeader
                if !vm.standings.isEmpty { standingsSection }
                if !vm.entries.isEmpty { entriesSection }
                if vm.hasOpenSession && vm.canManage { addEntryButton }
                if let error = vm.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red).padding()
                }
            }
            .padding()
        }
    }

    private var sessionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let session = vm.session {
                    Text(session.date.asDisplayDate).font(.subheadline).foregroundStyle(.secondary)
                    if let host = session.hostName {
                        Text("Host: \(host)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Label(vm.hasOpenSession ? "Live" : "Closed",
                  systemImage: vm.hasOpenSession ? "circle.fill" : "stop.circle")
                .font(.caption.bold())
                .foregroundStyle(vm.hasOpenSession ? .green : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(vm.hasOpenSession ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standings").font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(vm.standings.enumerated()), id: \.element.id) { index, standing in
                    LiveStandingRow(standing: standing, currency: appVM.currency)
                    if index < vm.standings.count - 1 { Divider().padding(.leading, 16) }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entries").font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(vm.entries.enumerated()), id: \.element.id) { index, entry in
                    LiveEntryRow(entry: entry, currency: appVM.currency)
                        .swipeActions(edge: .trailing) {
                            if vm.canManage {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    if index < vm.entries.count - 1 { Divider().padding(.leading, 16) }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var addEntryButton: some View {
        Button {
            showAddEntry = true
        } label: {
            Label("Add Entry", systemImage: "plus")
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }
}

struct LiveStandingRow: View {
    let standing: LiveStanding
    let currency: String

    var body: some View {
        HStack {
            Text(standing.name).font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(standing.resolvedNet.asCurrency(currency))
                    .font(.subheadline.bold())
                    .foregroundStyle(standing.isPositive ? .green : .red)
                Text("in: \(standing.buyIn.asCurrency(currency))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct LiveEntryRow: View {
    let entry: LiveEntry
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entryIcon)
                .font(.subheadline)
                .foregroundStyle(entryColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName).font(.subheadline)
                Text(entryLabel).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.amount.asCurrency(currency))
                .font(.subheadline.bold())
                .foregroundStyle(entryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var entryIcon: String {
        switch entry.type {
        case "buy_in":   return "arrow.down.circle.fill"
        case "rebuy":    return "arrow.clockwise.circle.fill"
        case "cash_out": return "arrow.up.circle.fill"
        default:         return "circle.fill"
        }
    }

    private var entryColor: Color {
        switch entry.type {
        case "buy_in":   return .orange
        case "rebuy":    return .blue
        case "cash_out": return .green
        default:         return .secondary
        }
    }

    private var entryLabel: String {
        switch entry.type {
        case "buy_in":   return "Buy In"
        case "rebuy":    return "Rebuy"
        case "cash_out": return "Cash Out"
        default:         return entry.type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
