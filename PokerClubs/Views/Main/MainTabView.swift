import SwiftUI

struct MainTabView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        TabView {
            Tab("Overview", systemImage: "house.fill") {
                OverviewView()
            }
            Tab("Live", systemImage: "play.circle.fill") {
                LiveView()
            }
            Tab("Sessions", systemImage: "list.bullet.rectangle") {
                SessionsView()
            }
            Tab("Players", systemImage: "person.2.fill") {
                PlayersView()
            }
            Tab("Account", systemImage: "person.circle.fill") {
                AccountView()
            }
        }
        .tint(.green)
    }
}
