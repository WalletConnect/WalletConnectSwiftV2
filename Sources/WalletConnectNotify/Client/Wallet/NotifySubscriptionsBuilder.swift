import Foundation

class NotifySubscriptionsBuilder {
    private let notifyConfigProvider: NotifyConfigProvider

    init(notifyConfigProvider: NotifyConfigProvider) {
        self.notifyConfigProvider = notifyConfigProvider
    }

    func buildSubscriptions(_ notifyServerSubscriptions: [NotifyServerSubscription]) async throws -> [NotifySubscription] {
        var result = [NotifySubscription]()

        for subscription in notifyServerSubscriptions {
            let config = await notifyConfigProvider.resolveNotifyConfig(appDomain: subscription.appDomain)

            do {
                let topic = try SymmetricKey(hex: subscription.symKey).derivedTopic()
                let scope = try await buildScope(selectedScope: subscription.scope, availableScope: config.notificationTypes)

                result.append(NotifySubscription(
                    topic: topic,
                    account: subscription.account,
                    relay: RelayProtocolOptions(protocol: "irn", data: nil),
                    metadata: config.metadata,
                    scope: scope,
                    expiry: subscription.expiry,
                    symKey: subscription.symKey, 
                    appAuthenticationKey: subscription.appAuthenticationKey
                ))
            } catch {
                continue
            }
        }

        return result
    }

    private func buildScope(selectedScope: [String], availableScope: [NotifyConfig.NotificationType]) async throws -> [String: ScopeValue] {
        return availableScope.reduce(into: [:]) {
            $0[$1.id] = ScopeValue(
                id: $1.id,
                name: $1.name,
                description: $1.description, 
                imageUrls: $1.imageUrls,
                enabled: selectedScope.contains($1.id)
            )
        }
    }
}
