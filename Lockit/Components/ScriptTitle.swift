import SwiftUI

struct ScriptTitle: View {
    let text: String
    var size: CGFloat = 36

    init(_ text: String, size: CGFloat = 36) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(Theme.script(size))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

#Preview {
    ZStack {
        LockitBackground()
        VStack(spacing: 8) {
            Text("Lockit")
                .font(Theme.appLabel)
                .foregroundStyle(Theme.textSecondary)
            ScriptTitle("A safe space for what was")
            ScriptTitle("Choose your guardian")
        }
        .padding(.horizontal, 32)
    }
}
