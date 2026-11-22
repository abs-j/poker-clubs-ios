import SwiftUI

// Cross-platform wrappers for iOS-only SwiftUI modifiers.

extension View {
    // Replaces .navigationBarTitleDisplayMode(.inline)
    @ViewBuilder
    func navBarInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    // Replaces .navigationBarTitleDisplayMode(.large)
    @ViewBuilder
    func navBarLarge() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    // Replaces .keyboardType(.emailAddress) + .textInputAutocapitalization(.never)
    @ViewBuilder
    func emailInput() -> some View {
        #if os(iOS)
        self
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    // Replaces .keyboardType(.decimalPad)
    @ViewBuilder
    func decimalInput() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    // Replaces .textInputAutocapitalization(.never)
    @ViewBuilder
    func noAutocap() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    // Replaces .listStyle(.insetGrouped)
    @ViewBuilder
    func groupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self.listStyle(.automatic)
        #endif
    }
}

// Cross-platform clipboard write
func copyToClipboard(_ string: String) {
    #if os(iOS)
    UIPasteboard.general.string = string
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
    #endif
}

// Cross-platform toolbar placements
extension ToolbarItemPlacement {
    static var trailingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }

    static var leadingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .automatic
        #endif
    }
}

extension Color {
    // Cross-platform equivalent of .secondarySystemGroupedBackground
    static var cardBackground: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
}
