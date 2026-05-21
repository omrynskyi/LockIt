import Foundation
import Photos
import UniformTypeIdentifiers

enum VaultError: LocalizedError {
    case directoryCreationFailed
    case assetWriteFailed(String)
    case deletionFailed
    case deletionDenied

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:  return "Could not create vault storage."
        case .assetWriteFailed(let n):  return "Failed to save \(n)."
        case .deletionFailed:           return "Could not remove originals from Camera Roll."
        case .deletionDenied:           return "You declined to remove originals. They remain in your Camera Roll."
        }
    }
}

@Observable
final class VaultManager {
    static let shared = VaultManager()

    private(set) var vaultDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        vaultDirectory = docs.appendingPathComponent("Vault", isDirectory: true)
        createVaultDirectoryIfNeeded()
    }

    // MARK: - Setup

    private func createVaultDirectoryIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: vaultDirectory.path) else { return }
        do {
            try fm.createDirectory(at: vaultDirectory, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try vaultDirectory.setResourceValues(values)
        } catch {
            print("[Vault] Setup error: \(error)")
        }
    }

    // MARK: - Import

    func importAssets(_ assets: [PHAsset]) async throws {
        for asset in assets {
            let resources = PHAssetResource.assetResources(for: asset)
            guard let resource = resources.first(where: {
                $0.type == .photo || $0.type == .video || $0.type == .fullSizePhoto || $0.type == .fullSizeVideo
            }) ?? resources.first else { continue }

            let ext = UTType(resource.uniformTypeIdentifier)?.preferredFilenameExtension ?? "dat"
            let destinationURL = vaultDirectory.appendingPathComponent(UUID().uuidString + "." + ext)

            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                let options = PHAssetResourceRequestOptions()
                options.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(
                    for: resource,
                    toFile: destinationURL,
                    options: options
                ) { error in
                    if let error {
                        cont.resume(throwing: VaultError.assetWriteFailed(resource.originalFilename))
                        _ = error
                    } else {
                        cont.resume()
                    }
                }
            }
        }
    }

    // MARK: - Delete from Camera Roll

    func deleteFromCameraRoll(_ assets: [PHAsset]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, error in
                if let error {
                    cont.resume(throwing: error)
                } else if success {
                    cont.resume()
                } else {
                    cont.resume(throwing: VaultError.deletionDenied)
                }
            }
        }
    }

    // MARK: - List vault contents

    func listVaultItems() -> [URL] {
        let fm = FileManager.default
        let contents = (try? fm.contentsOfDirectory(
            at: vaultDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
        return contents.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return dateA < dateB
        }
    }

    // MARK: - Clear vault

    func clearVault() {
        listVaultItems().forEach { try? FileManager.default.removeItem(at: $0) }
    }
}
