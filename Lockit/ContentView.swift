import SwiftUI
import Photos

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        currentScreen
            .animation(.easeInOut(duration: 0.45), value: appState.screen)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch appState.screen {
        case .selectPhotos:
            PhotoSelectionView()
        case .defineGuardian(let assets):
            GuardianSetupView(assets: assets)
        case .locked(let guardian):
            LockScreenView(guardian: guardian)
        case .unlocked:
            VaultView()
        }
    }
}

#Preview("Select Photos") {
    ContentView()
        .environment(AppState())
}

#Preview("Locked") {
    let state = AppState()
    state.screen = .locked(Guardian(name: "Jane", email: "jane@example.com", message: Guardian.defaultMessage))
    return ContentView()
        .environment(state)
}
