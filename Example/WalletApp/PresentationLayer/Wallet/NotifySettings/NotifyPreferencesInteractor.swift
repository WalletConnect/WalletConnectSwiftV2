import WalletConnectNotify

final class NotifyPreferencesInteractor {

    func updatePreferences(subscription: NotifySubscription, scope: Set<String>) async throws {
        try await Notify.instance.update(topic: subscription.topic, scope: scope)
    }
}
