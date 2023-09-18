import Foundation

class NotifySubscriptionsBuilder {
    private let notifyConfigProvider: NotifyConfigProvider

    init(notifyConfigProvider: NotifyConfigProvider) {
        self.notifyConfigProvider = notifyConfigProvider
    }

    func buildSubscriptions(_ notifyServerSubscriptions: [NotifyServerSubscription]) async throws -> [NotifySubscription] {
        var result = [NotifySubscription]()

        for subscription in notifyServerSubscriptions {
            let scope = try await buildScope(selectedScope: subscription.scope, appDomain: subscription.appDomain)
            guard let metadata = try? await notifyConfigProvider.getMetadata(appDomain: subscription.appDomain),
                  let topic = try? SymmetricKey(hex: subscription.symKey).derivedTopic() else { continue }

            let notifySubscription = NotifySubscription(topic: topic,
                                                        account: subscription.account,
                                                        relay: RelayProtocolOptions(protocol: "irn", data: nil),
                                                        metadata: metadata,
                                                        scope: scope,
                                                        expiry: subscription.expiry,
                                                        symKey: subscription.symKey)
            result.append(notifySubscription)
        }

        return result
    }

    private func buildScope(selectedScope: [String], appDomain: String) async throws -> [String: ScopeValue] {
        let availableScope = try await notifyConfigProvider.getSubscriptionScope(appDomain: appDomain)
        return availableScope.reduce(into: [:]) {
            $0[$1.name] = ScopeValue(description: $1.description, enabled: selectedScope.contains($1.name))
        }
    }
}
