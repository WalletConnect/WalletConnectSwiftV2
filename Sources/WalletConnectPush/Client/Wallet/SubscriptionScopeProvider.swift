
import Foundation

class SubscriptionScopeProvider {
    enum Errors: Error {
        case invalidUrl
    }

    private var cache = [String: Set<NotificationScope>]()

    func getSubscriptionScope(dappUrl: String) async throws -> Set<NotificationScope> {
        if let availableScope = cache[dappUrl] {
            return availableScope
        }
        guard let scopeUrl = URL(string: "\(dappUrl)/.well-known/wc-push-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: scopeUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        let availableScope = Set(config.types.map { $0.name })
        cache[dappUrl] = availableScope
        return availableScope
    }
}
