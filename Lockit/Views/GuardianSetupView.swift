import SwiftUI
import Photos

// fileprivate so both GuardianSetupView and GuardianField can see it
fileprivate enum GuardianFormField {
    case name, email, message
}

struct GuardianSetupView: View {
    let assets: [PHAsset]

    @Environment(AppState.self) private var appState
    @FocusState private var focusedField: GuardianFormField?

    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var showWarning = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false

    private var isReady: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isProcessing
    }

    var body: some View {
        ZStack(alignment: .top) {
            LockitBackground()

            // Back button
            Button {
                withAnimation(.easeInOut(duration: 0.45)) {
                    appState.screen = .selectPhotos
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 52)
            .padding(.leading, 8)

            VStack(spacing: 0) {
                Spacer().frame(height: 88)

                VStack(spacing: 6) {
                    Text("Lockit")
                        .font(Theme.appLabel)
                        .foregroundStyle(Theme.textSecondary)
                    ScriptTitle("Choose your guardian")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                LockitCard {
                    VStack(spacing: 0) {
                        GuardianField(
                            placeholder: "Name of safekeeper",
                            text: $name,
                            keyboardType: .default,
                            focused: $focusedField,
                            tag: .name
                        )
                        Divider()
                            .background(Theme.fieldLine.opacity(0.4))
                            .padding(.horizontal, 4)

                        GuardianField(
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            focused: $focusedField,
                            tag: .email
                        )
                        Divider()
                            .background(Theme.fieldLine.opacity(0.4))
                            .padding(.horizontal, 4)

                        GuardianField(
                            placeholder: "Message (optional)",
                            text: $message,
                            keyboardType: .default,
                            focused: $focusedField,
                            tag: .message,
                            multiline: true
                        )
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)

                if focusedField == nil && name.isEmpty && email.isEmpty {
                    Text("Tap to edit")
                        .font(Theme.serif(13, italic: true))
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .padding(.top, 10)
                }

                Spacer()

                if isProcessing {
                    VStack(spacing: 8) {
                        ProgressView().tint(Theme.textSecondary)
                        Text("Placing in safekeeping…")
                            .font(Theme.serif(14, italic: true))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.bottom, 20)
                }

                LockitButton("Place them in safekeeping.", isEnabled: isReady) {
                    showWarning = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            message = Guardian.defaultMessageFor("your friend")
        }
        .onChange(of: name) { _, new in
            guard !new.isEmpty else { return }
            message = Guardian.defaultMessageFor(new)
        }
        .alert("One moment.", isPresented: $showWarning) {
            Button("Proceed", role: .destructive) {
                Task { await performHandoff() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("LOCKIT IS LOCAL.\n\nIf you delete this app, you permanently delete all stored photos. This cannot be undone.")
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
    }

    private func performHandoff() async {
        isProcessing = true
        let guardian = Guardian(name: name, email: email, message: message)
        do {
            let pin = try PINManager.shared.generateAndStorePIN()
            try await EmailService.shared.sendPIN(to: guardian, pin: pin)
            try await VaultManager.shared.importAssets(assets)
            try await VaultManager.shared.deleteFromCameraRoll(assets)
            appState.lock(guardian: guardian)
        } catch {
            PINManager.shared.clearPIN()
            errorMessage = error.localizedDescription
            showError = true
            isProcessing = false
        }
    }
}

// MARK: - Form field helper
private struct GuardianField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    var focused: FocusState<GuardianFormField?>.Binding
    let tag: GuardianFormField
    var multiline: Bool = false

    var body: some View {
        Group {
            if multiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...5)
                    .focused(focused, equals: tag)
            } else {
                TextField(placeholder, text: $text)
                    .focused(focused, equals: tag)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            }
        }
        .font(Theme.serif(16))
        .foregroundStyle(Theme.textPrimary)
        .keyboardType(keyboardType)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
