
import Foundation

actor NotifyConfigProvider {
    enum Errors: Error {
        case invalidUrl
    }

    private var cache = [String: Set<NotificationType>]()

    func getSubscriptionScope(appDomain: String) async throws -> Set<NotificationType> {
        if let availableScope = cache[appDomain] {
            return availableScope
        }
        guard let notifyConfigUrl = URL(string: "https://\(appDomain)/.well-known/wc-notify-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: notifyConfigUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        let availableScope = Set(config.types)
        cache[appDomain] = availableScope
        return availableScope
    }

    func getMetadata(appDomain: String) async throws -> AppMetadata {
        guard let notifyConfigUrl = URL(string: "https://\(appDomain)/.well-known/wc-notify-config.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: notifyConfigUrl)
        let config = try JSONDecoder().decode(NotificationConfig.self, from: data)
        return AppMetadata(name: config.name, description: config.description, url: appDomain, icons: config.icons)
    }
}
