import SwiftUI
import CoreText

@main
struct LockitApp: App {

    @State private var appState = AppState()

    init() {
        registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }

    private func registerFonts() {
        let fonts = [
            "CormorantGaramond-LightItalic",
            "CormorantGaramond-Italic",
            "CormorantGaramond-Regular",
            "CormorantGaramond-Bold",
            "ImperialScript-Regular"
        ]
        fonts.forEach { name in
            let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            guard let url else { return }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
