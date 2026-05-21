import SwiftUI
import Photos

enum AppScreen: Equatable {
    case selectPhotos
    case defineGuardian([PHAsset])
    case locked(Guardian)
    case unlocked

    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.selectPhotos, .selectPhotos): return true
        case (.defineGuardian, .defineGuardian): return true
        case (.locked(let a), .locked(let b)): return a == b
        case (.unlocked, .unlocked): return true
        default: return false
        }
    }
}

@Observable
class AppState {
    var screen: AppScreen

    init() {
        if let guardian = Guardian.load() {
            screen = .locked(guardian)
        } else {
            screen = .selectPhotos
        }
    }

    func lock(guardian: Guardian) {
        guardian.save()
        withAnimation(.easeInOut(duration: 0.5)) {
            screen = .locked(guardian)
        }
    }

    func unlock() {
        withAnimation(.easeInOut(duration: 0.5)) {
            screen = .unlocked
        }
    }

    func reset() {
        Guardian.clear()
        withAnimation(.easeInOut(duration: 0.5)) {
            screen = .selectPhotos
        }
    }
}
