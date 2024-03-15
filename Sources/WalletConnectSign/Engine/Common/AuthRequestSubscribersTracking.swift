import Foundation

// purpose of this class is to allow fallback to session propose in case wallet did not subscribe to authenticateRequestPublisher and dapp request wc_sessionAuthenticate
class AuthRequestSubscribersTracking {
    private var subscribersCount: Int = 0
    private let serialQueue = DispatchQueue(label: "com.walletconnect.AuthRequestSubscribersTrackingQueue")
    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) {
        self.logger = logger
    }

    func increment() {
        serialQueue.sync {
            subscribersCount += 1
            logger.debug("Incremented subscriber count: \(subscribersCount)")
        }
    }

    func decrement() {
        serialQueue.sync {
            subscribersCount = max(0, subscribersCount - 1)
            logger.debug("Decremented subscriber count: \(subscribersCount)")
        }
    }

    func hasSubscribers() -> Bool {
        return serialQueue.sync { subscribersCount > 0 }
    }
}
