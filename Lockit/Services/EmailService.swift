import Foundation

enum EmailError: LocalizedError {
    case invalidURL
    case serverError(Int)
    case networkError(Error)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Relay URL is not configured."
        case .serverError(let c):   return "Server returned \(c). PIN may not have been delivered."
        case .networkError(let e):  return "Network error: \(e.localizedDescription)"
        case .encodingFailed:       return "Could not encode request."
        }
    }
}

final class EmailService {
    static let shared = EmailService()
    private init() {}

    // MARK: - Configure this before shipping
    static let relayURL = "https://lockitapp.vercel.app/api/send"

    // MARK: - Send PIN

    func sendPIN(to guardian: Guardian, pin: String) async throws {
        #if DEBUG
        // Fallback for development/testing when using the default placeholder URL
        if EmailService.relayURL.contains("your-serverless-endpoint") {
            print("\n🔑 [DEVELOPMENT MOCK] PIN Generated: \(pin) for Guardian: \(guardian.name) (\(guardian.email))")
            print("Notice: Using placeholder URL. PIN printed here to avoid lockout.\n")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
            return
        }
        #endif

        guard let url = URL(string: EmailService.relayURL) else {
            throw EmailError.invalidURL
        }

        let payload = EmailPayload(
            guardianEmail: guardian.email,
            guardianName:  guardian.name,
            pin:           pin,
            message:       guardian.message
        )

        guard let body = try? JSONEncoder().encode(payload) else {
            throw EmailError.encodingFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 15

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw EmailError.serverError(http.statusCode)
            }
        } catch let error as EmailError {
            throw error
        } catch {
            throw EmailError.networkError(error)
        }
    }
}

// MARK: - Payload (PIN is never logged or stored after this encode)
private struct EmailPayload: Encodable {
    let guardianEmail: String
    let guardianName:  String
    let pin:           String
    let message:       String
}
