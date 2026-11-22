import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        Group {
            if appVM.isLoading {
                splashScreen
            } else if appVM.isAuthenticated {
                MainTabView()
            } else {
                AuthView {
                    await appVM.checkSession()
                }
            }
        }
        .task {
            await appVM.bootstrap()
        }
    }

    private var splashScreen: some View {
        VStack(spacing: 16) {
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Poker Clubs")
                .font(.largeTitle.bold())
            ProgressView()
                .padding(.top, 8)
        }
    }
}
