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

    var timerInterval: TimeInterval = 5 * 60
    var onSetupTimer: (() -> Void)?

    init(notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting,
         logger: ConsoleLogging,
         notificationCenter: NotificationPublishing = NotificationCenter.default) {
        self.notifyWatchSubscriptionsRequester = notifyWatchSubscriptionsRequester
        self.logger = logger
        self.notificationCenter = notificationCenter
    }

    func setupTimer() {
        onSetupTimer?()
        logger.debug("Setting up Subscription Watcher timer")
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.backgroundQueue.async {
                    self?.watchSubscriptions()
                }
            }
    }

    func setAccount(_ account: Account) {
        notifyWatchSubscriptionsRequester.setAccount(account)
        setupTimer()
        watchAppLifecycle()
#if DEBUG
        watchSubscriptions()
#endif
    }

    func watchSubscriptions() {
        logger.debug("Will watch subscriptions")
        Task(priority: .background) { try await notifyWatchSubscriptionsRequester.watchSubscriptions() }
    }

    func watchAppLifecycle() {
#if os(iOS)
        appLifecycleCancellable = notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.logger.debug("Will setup Subscription Watcher after app entered foreground")
                self?.setupTimer()
                self?.backgroundQueue.async {
                    self?.watchSubscriptions()
                }
            }
#endif
    }
}
