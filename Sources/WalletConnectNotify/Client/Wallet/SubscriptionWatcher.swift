import Foundation
import Combine
import SwiftUI

class SubscriptionWatcher: ObservableObject {

    private var timerCancellable: AnyCancellable?
    private var appLifecycleCancellable: AnyCancellable?
    private var notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequester
    private let logger: ConsoleLogging
    private let backgroundQueue = DispatchQueue(label: "com.walletconnect.subscriptionWatcher", qos: .background)

    init(notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequester,
         logger: ConsoleLogging) {
        self.notifyWatchSubscriptionsRequester = notifyWatchSubscriptionsRequester
        self.logger = logger
        setupTimer()
        watchAppLifecycle()
    }

    func setupTimer() {
        logger.debug("Setting up Subscription Watcher timer")
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 5 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [unowned self] _ in
                backgroundQueue.async {
                    self.watchSubscriptions()
                }
            }
    }

    func watchSubscriptions() {
        logger.debug("Will watch subscriptions")
        Task(priority: .background) { try await notifyWatchSubscriptionsRequester.watchSubscriptions() }
    }

    func watchAppLifecycle() {
        appLifecycleCancellable = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                logger.debug("Will setup Subscription Watcher after app entered foreground")
                setupTimer()
                backgroundQueue.async {
                    self.watchSubscriptions()
                }
            }
    }
}
