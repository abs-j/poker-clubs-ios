import SwiftUI

@main
struct PokerClubsApp: App {
    @State private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appVM)
        }
    }
}
