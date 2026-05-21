import Foundation

struct Guardian: Codable, Equatable {
    var name: String
    var email: String
    var message: String

    static let defaultMessage = "is using Lockit to find some space. Please keep this safe."

    static func defaultMessageFor(_ userName: String) -> String {
        "Hey, \(userName) \(defaultMessage)"
    }
}

// MARK: - UserDefaults persistence
extension Guardian {
    private static let key = "lockit.guardian"

    static func load() -> Guardian? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let guardian = try? JSONDecoder().decode(Guardian.self, from: data) else {
            return nil
        }
        return guardian
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Guardian.key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
