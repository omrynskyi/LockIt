import SwiftUI
import Photos

struct VaultView: View {
    @Environment(AppState.self) private var appState

    @State private var items: [URL] = []
    @State private var showLockConfirm = false
    @State private var isRelocking = false

    var body: some View {
        ZStack(alignment: .top) {
            LockitBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 88)

                VStack(spacing: 6) {
                    Text("Lockit")
                        .font(Theme.appLabel)
                        .foregroundStyle(Theme.textSecondary)
                    ScriptTitle("Your memories")

                    Text("\(items.count) item\(items.count == 1 ? "" : "s") kept safe")
                        .font(Theme.serif(14, italic: true))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "lock.open")
                            .font(.system(size: 36, weight: .ultraLight))
                            .foregroundStyle(Theme.fieldLine)
                        Text("Nothing here yet.")
                            .font(Theme.serif(18, italic: true))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                } else {
                    Spacer()
                    PhotoSwipeView(items: items)
                        .padding(.horizontal, 24)
                    Spacer()
                }
            }

            VStack {
                Spacer()
                LockitButton(isRelocking ? "Locking…" : "Lock the Vault", isEnabled: !isRelocking) {
                    showLockConfirm = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear { items = VaultManager.shared.listVaultItems() }
        .alert("Lock the vault?", isPresented: $showLockConfirm) {
            Button("Lock", role: .destructive) { Task { await relockVault() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A new PIN will be generated and sent to your Guardian. You will need it to open the vault again.")
        }
    }

    private func relockVault() async {
        guard let guardian = Guardian.load() else {
            appState.reset()
            return
        }
        isRelocking = true
        do {
            let pin = try PINManager.shared.generateAndStorePIN()
            try await EmailService.shared.sendPIN(to: guardian, pin: pin)
            appState.lock(guardian: guardian)
        } catch {
            isRelocking = false
        }
    }
}

// MARK: - Swipeable photo viewer

private struct PhotoSwipeView: View {
    let items: [URL]

    @State private var index = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var cache: [String: UIImage] = [:]

    private var prevIndex: Int { (index - 1 + items.count) % items.count }
    private var nextIndex: Int { (index + 1) % items.count }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                photoLayer(at: prevIndex, offsetY: -h + dragOffset, w: w, h: h)
                photoLayer(at: index,     offsetY: dragOffset,       w: w, h: h)
                photoLayer(at: nextIndex, offsetY:  h + dragOffset,  w: w, h: h)
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
            .overlay(alignment: .bottom) {
                pageIndicator.padding(.bottom, 16)
            }
            .gesture(dragGesture(cardHeight: h))
        }
        .frame(height: 380)
        .onAppear { preload(around: index) }
    }

    private func photoLayer(at i: Int, offsetY: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Theme.cardBackground
            if let img = cache[items[i].path] {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
            } else {
                ProgressView()
                    .tint(Theme.textSecondary)
                    .onAppear { loadImage(at: i) }
            }
        }
        .frame(width: w, height: h)
        .offset(y: offsetY)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if items.count > 1 && items.count <= 12 {
            HStack(spacing: 6) {
                ForEach(0..<items.count, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(i == index ? 0.9 : 0.35))
                        .frame(width: i == index ? 16 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
                }
            }
        } else if items.count > 12 {
            Text("\(index + 1) / \(items.count)")
                .font(Theme.serif(13, italic: true))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(.black.opacity(0.25)))
        }
    }

    private func dragGesture(cardHeight h: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimating else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard !isAnimating else { return }
                let threshold = h * 0.2
                if value.translation.height < -threshold {
                    advance(by: 1, cardHeight: h)
                } else if value.translation.height > threshold {
                    advance(by: -1, cardHeight: h)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragOffset = 0 }
                }
            }
    }

    private func advance(by direction: Int, cardHeight h: CGFloat) {
        isAnimating = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            dragOffset = direction > 0 ? -h : h
        } completion: {
            index = (index + direction + items.count) % items.count
            dragOffset = 0
            isAnimating = false
            preload(around: index)
        }
    }

    private func preload(around i: Int) {
        [i, nextIndex, prevIndex].forEach { loadImage(at: $0) }
    }

    private func loadImage(at i: Int) {
        let url = items[i]
        guard cache[url.path] == nil else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = UIImage(contentsOfFile: url.path) else { return }
            DispatchQueue.main.async { cache[url.path] = img }
        }
    }
}
