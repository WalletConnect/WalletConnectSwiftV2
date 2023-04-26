
import Foundation

class SubscriptionScopeProvider {
    enum Errors: Error {
        case invalidUrl
    }

    func getSubscriptionScope(dappUrl: String) async throws -> Set<NotificationScope> {
        guard let scopeUrl = URL(string: "\(dappUrl)/.well-known/wc-push-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: scopeUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        return Set(config.types.map { $0.name })
    }
}
