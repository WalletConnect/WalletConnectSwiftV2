
import Foundation

class SubscriptionsAutoUpdater {
    private let notifyUpdateRequester: NotifyUpdateRequesting
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStoring

    init(notifyUpdateRequester: NotifyUpdateRequesting,
         logger: ConsoleLogging,
         notifyStorage: NotifyStoring) {
        self.notifyUpdateRequester = notifyUpdateRequester
        self.logger = logger
        self.notifyStorage = notifyStorage
        updateSubscriptionsIfNeeded()
    }

    private func updateSubscriptionsIfNeeded() {
        for subscription in notifyStorage.getSubscriptions() {
            if shouldUpdate(subscription: subscription) {
                let scope = Set(subscription.scope.filter{ $0.value.enabled == true }.keys)
                let topic = subscription.topic
                Task {
                    do {
                        try await notifyUpdateRequester.update(topic: topic, scope: scope)
                    } catch {
                        logger.error("Failed to update subscription for topic: \(topic)")
                    }
                }
            }
        }
    }

    private func shouldUpdate(subscription: NotifySubscription) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let expiryDate = subscription.expiry
        let dateComponents = calendar.dateComponents([.day], from: currentDate, to: expiryDate)
        if let numberOfDays = dateComponents.day,
           numberOfDays < 14 {
            return true
        } else {
            return false
        }
    }
}
