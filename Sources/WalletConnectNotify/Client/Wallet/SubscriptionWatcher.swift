import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

class SubscriptionWatcher {

    private var timer: Timer?
    private var appLifecycleCancellable: AnyCancellable?
    private var notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting
    private let logger: ConsoleLogging
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

    deinit { stop() }

    func start() async throws {
        setupAppLifecyclePublisher()
        setupTimer()

        try await notifyWatchSubscriptionsRequester.watchSubscriptions()
    }

    func stop() {
        timer?.invalidate()
        appLifecycleCancellable?.cancel()
    }
}

private extension SubscriptionWatcher {

    func setupAppLifecyclePublisher() {
#if os(iOS)
        appLifecycleCancellable = notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.logger.debug("SubscriptionWatcher entered foreground event")
                self.watchSubscriptions()
            }
#endif
    }

    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.logger.debug("SubscriptionWatcher scheduled event")
            self.watchSubscriptions()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func watchSubscriptions() {
        Task(priority: .high) {
            try await self.notifyWatchSubscriptionsRequester.watchSubscriptions()
        }
    }
}
