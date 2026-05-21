import SwiftUI

struct LockitCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.cardBackground)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
            )
    }
}

#Preview {
    ZStack {
        LockitBackground()
        LockitCard {
            VStack(spacing: 16) {
                Text("Card content here")
                    .font(Theme.bodyText)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(24)
        }
        .padding(.horizontal, 24)
    }
}
