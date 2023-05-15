
import Foundation

class SubscriptionScopeProvider {
    enum Errors: Error {
        case invalidUrl
    }

    private var cache = [String: Set<NotificationType>]()

    func getSubscriptionScope(dappUrl: String) async throws -> Set<NotificationType> {
        if let availableScope = cache[dappUrl] {
            return availableScope
        }
        guard let scopeUrl = URL(string: "\(dappUrl)/.well-known/wc-push-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: scopeUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        let availableScope = Set(config.types)
        cache[dappUrl] = availableScope
        return availableScope
    }
}
