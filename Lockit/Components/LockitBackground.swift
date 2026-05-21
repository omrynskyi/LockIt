import SwiftUI

struct LockitBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            Theme.backgroundGradient
                .ignoresSafeArea()
            AppHeaderImage()
                .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - View modifier for convenience
extension View {
    func lockitBackground() -> some View {
        self.background(LockitBackground().ignoresSafeArea())
    }
}

#Preview {
    ZStack {
        LockitBackground()
        Text("Preview")
            .font(Theme.serif(32))
            .foregroundStyle(Theme.textPrimary)
    }
}
