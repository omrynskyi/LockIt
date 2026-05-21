import SwiftUI
import Photos
import PhotosUI

struct PhotoSelectionView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedAssets: [PHAsset] = []
    @State private var showPicker = false

    var body: some View {
        ZStack(alignment: .top) {
            LockitBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 88)

                VStack(spacing: 6) {
                    Text("Lockit")
                        .font(Theme.appLabel)
                        .foregroundStyle(Theme.textSecondary)
                    ScriptTitle("A safe space for what was")

                    Text(selectedAssets.isEmpty ? "Select Pictures" : "\(selectedAssets.count) pictures selected")
                        .font(Theme.serif(15, italic: true))
                        .foregroundStyle(Theme.textSecondary)
                        .animation(.easeInOut(duration: 0.3), value: selectedAssets.count)
                }
                .padding(.horizontal, 32)

                Spacer()

                if selectedAssets.isEmpty {
                    EmptyPhotoCard(onTap: { showPicker = true })
                        .padding(.horizontal, 24)
                } else {
                    SelectedPhotoSwipeCard(assets: selectedAssets, onTapAdd: { showPicker = true })
                        .padding(.horizontal, 24)
                }

                if !selectedAssets.isEmpty {
                    Text("Selected photos will be removed from your camera roll.")
                        .font(Theme.serif(13, italic: true))
                        .foregroundStyle(Color(hex: "C0805A").opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                LockitButton(
                    "Place them in safekeeping.",
                    isEnabled: !selectedAssets.isEmpty
                ) {
                    appState.screen = .defineGuardian(selectedAssets)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: selectedAssets.isEmpty)
        .sheet(isPresented: $showPicker) {
            PHPickerRepresentable(selectedAssets: $selectedAssets)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Empty state card

private struct EmptyPhotoCard: View {
    let onTap: () -> Void

    var body: some View {
        LockitCard {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Theme.fieldLine)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Swipeable selected-photo card

private struct SelectedPhotoSwipeCard: View {
    let assets: [PHAsset]
    let onTapAdd: () -> Void

    @State private var index = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var cache: [String: UIImage] = [:]

    private var prevIndex: Int { (index - 1 + assets.count) % assets.count }
    private var nextIndex: Int { (index + 1) % assets.count }

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
                HStack(alignment: .center) {
                    pageIndicator
                    Spacer()
                    Button(action: onTapAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.white.opacity(0.85))
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .gesture(dragGesture(cardHeight: h))
        }
        .frame(height: 280)
        .onAppear { preload(around: index) }
        .onChange(of: assets.count) { _, newCount in
            if index >= newCount { index = max(0, newCount - 1) }
            preload(around: index)
        }
    }

    private func photoLayer(at i: Int, offsetY: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Theme.cardBackground
            if let img = cache[assets[i].localIdentifier] {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .saturation(0.75)
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
        if assets.count > 1 && assets.count <= 12 {
            HStack(spacing: 6) {
                ForEach(0..<assets.count, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(i == index ? 0.9 : 0.35))
                        .frame(width: i == index ? 16 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
                }
            }
        } else if assets.count > 12 {
            Text("\(index + 1) / \(assets.count)")
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
                guard !isAnimating, assets.count > 1 else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard !isAnimating, assets.count > 1 else { return }
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
            index = (index + direction + assets.count) % assets.count
            dragOffset = 0
            isAnimating = false
            preload(around: index)
        }
    }

    private func preload(around i: Int) {
        [i, nextIndex, prevIndex].forEach { loadImage(at: $0) }
    }

    private func loadImage(at i: Int) {
        let asset = assets[i]
        let key = asset.localIdentifier
        guard cache[key] == nil else { return }
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .opportunistic
        opts.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 800, height: 800),
            contentMode: .aspectFill,
            options: opts
        ) { image, _ in
            guard let image else { return }
            DispatchQueue.main.async { cache[key] = image }
        }
    }
}

// MARK: - PHPickerViewController wrapper

private struct PHPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedAssets: [PHAsset]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .videos])
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerRepresentable
        init(_ parent: PHPickerRepresentable) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }
            let ids = results.compactMap(\.assetIdentifier)
            let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            parent.selectedAssets = (0..<fetched.count).map { fetched.object(at: $0) }
        }
    }
}
