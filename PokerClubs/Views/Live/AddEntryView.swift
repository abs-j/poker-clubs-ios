import SwiftUI

struct AddEntryView: View {
    @Bindable var vm: LiveViewModel
    let currency: String

    @Environment(\.dismiss) private var dismiss
    @State private var playerName = ""
    @State private var type = "buy_in"
    @State private var amountText = ""
    @State private var isSubmitting = false

    private let entryTypes = [
        ("buy_in", "Buy In", "arrow.down.circle.fill", Color.orange),
        ("rebuy", "Rebuy", "arrow.clockwise.circle.fill", Color.blue),
        ("cash_out", "Cash Out", "arrow.up.circle.fill", Color.green),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Player name", text: $playerName)
                        .autocorrectionDisabled()
                }

                Section("Type") {
                    ForEach(entryTypes, id: \.0) { typeKey, label, icon, color in
                        Button {
                            type = typeKey
                        } label: {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundStyle(color)
                                    .frame(width: 28)
                                Text(label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if type == typeKey {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .decimalInput()
                    }
                }
            }
            .navigationTitle("Add Entry")
            .navBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let amount = Double(amountText), amount > 0 else { return }
                        isSubmitting = true
                        Task {
                            await vm.addEntry(playerName: playerName, type: type, amount: amount)
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(isSubmitting || playerName.isEmpty || (Double(amountText) ?? 0) <= 0)
                    .bold()
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? "$"
    }
}
