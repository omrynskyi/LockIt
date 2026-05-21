import SwiftUI

struct LockScreenView: View {
    let guardian: Guardian

    @Environment(AppState.self) private var appState

    @State private var pin = ""
    @State private var shakeOffset: CGFloat = 0
    @State private var showError = false
    @FocusState private var isPINFocused: Bool

    private let digitCount = 6

    var body: some View {
        ZStack(alignment: .top) {
            LockitBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 88)

                // Header
                VStack(spacing: 6) {
                    Text("Lockit")
                        .font(Theme.appLabel)
                        .foregroundStyle(Theme.textSecondary)
                    ScriptTitle("A safe space for what was")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                // Lock card
                LockitCard {
                    VStack(spacing: 20) {
                        // Guardian info
                        VStack(spacing: 4) {
                            Text("Guardian: \(guardian.name)")
                                .font(Theme.serif(16))
                                .foregroundStyle(Theme.textPrimary)
                            Text(guardian.email)
                                .font(Theme.serif(14, italic: true))
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer().frame(height: 8)

                        // PIN entry
                        PINDigitRow(
                            pin: $pin,
                            digitCount: digitCount,
                            isFocused: $isPINFocused,
                            shakeOffset: shakeOffset
                        )

                        if showError {
                            Text("Incorrect PIN")
                                .font(Theme.serif(13, italic: true))
                                .foregroundStyle(Color(hex: "C0605A"))
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)
                .onTapGesture { isPINFocused = true }

                Spacer()

                LockitButton("Open the Vault") {
                    attemptUnlock()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear { isPINFocused = true }
        .onChange(of: pin) { _, new in
            pin = String(new.filter(\.isNumber).prefix(digitCount))
            if pin.count == digitCount { attemptUnlock() }
            if showError { showError = false }
        }
    }

    private func attemptUnlock() {
        if PINManager.shared.verifyPIN(pin) {
            pin = ""
            appState.unlock()
        } else {
            triggerShake()
            pin = ""
        }
    }

    private func triggerShake() {
        showError = true
        withAnimation(.default) { shakeOffset = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.default) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring) { shakeOffset = 0 }
        }
    }
}

// MARK: - PIN digit row
private struct PINDigitRow: View {
    @Binding var pin: String
    let digitCount: Int
    var isFocused: FocusState<Bool>.Binding
    let shakeOffset: CGFloat

    var body: some View {
        ZStack {
            // Hidden actual input
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .focused(isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)

            // Visual digit slots
            HStack(spacing: 18) {
                ForEach(0..<digitCount, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(pin.count > i ? "●" : " ")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(height: 14)

                        Rectangle()
                            .frame(width: 28, height: 1)
                            .foregroundStyle(
                                pin.count > i
                                    ? Theme.textPrimary
                                    : Theme.fieldLine
                            )
                    }
                }
            }
            .offset(x: shakeOffset)
        }
        .onTapGesture { isFocused.wrappedValue = true }
    }
}
