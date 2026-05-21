import SwiftUI

struct LockitButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.serif(20))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(Theme.buttonGradient)
                        .opacity(isEnabled ? 1.0 : 0.5)
                )
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

#Preview {
    ZStack {
        LockitBackground()
        VStack(spacing: 16) {
            LockitButton("Place them in safekeeping.") {}
            LockitButton("Disabled button", isEnabled: false) {}
        }
        .padding(.horizontal, 24)
    }
}
