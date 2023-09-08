
import Foundation

actor SubscriptionScopeProvider {
    enum Errors: Error {
        case invalidUrl
    }

    private var cache = [String: Set<NotificationType>]()

    func getSubscriptionScope(dappUrl: String) async throws -> Set<NotificationType> {
        if let availableScope = cache[dappUrl] {
            return availableScope
        }
        guard let notifyConfigUrl = URL(string: "\(dappUrl)/.well-known/wc-notify-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: notifyConfigUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        let availableScope = Set(config.types)
        cache[dappUrl] = availableScope
        return availableScope
    }

    func getMetadata(dappUrl: String) async throws -> AppMetadata {
        guard let notifyConfigUrl = URL(string: "\(dappUrl)/.well-known/wc-notify-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: notifyConfigUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        return AppMetadata(name: "", description: "", url: "", icons: [])
    }
}
