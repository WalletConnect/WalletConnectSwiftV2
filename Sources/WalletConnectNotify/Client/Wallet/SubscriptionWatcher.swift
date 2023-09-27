import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

class SubscriptionWatcher {

    private var timerCancellable: AnyCancellable?
    private var appLifecycleCancellable: AnyCancellable?
    private var notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting
    private let logger: ConsoleLogging
    private let backgroundQueue = DispatchQueue(label: "com.walletconnect.subscriptionWatcher", qos: .background)
    private let notificationCenter: NotificationPublishing

#if DEBUG
    var timerInterval: TimeInterval = 5 * 60
    var onSetupTimer: (() -> Void)?
#endif

    init(notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting,
         logger: ConsoleLogging,
         notificationCenter: NotificationPublishing = NotificationCenter.default) {
        self.notifyWatchSubscriptionsRequester = notifyWatchSubscriptionsRequester
        self.logger = logger
        self.notificationCenter = notificationCenter
        setupTimer()
        watchAppLifecycle()
    }

    func setupTimer() {
        onSetupTimer?()
        logger.debug("Setting up Subscription Watcher timer")
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: timerInterval, on: .main, in: .common)
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
#if os(iOS)
        appLifecycleCancellable = notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                logger.debug("Will setup Subscription Watcher after app entered foreground")
                setupTimer()
                backgroundQueue.async {
                    self.watchSubscriptions()
                }
            }
#endif
    }
}



