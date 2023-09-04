import Foundation
import Combine
import Sentry
import WalletConnectNetworking

final class LoggingService {
    enum LoggingError: Error {
        case networking(String)
    }

    public static var instance = LoggingService()
    private var publishers = [AnyCancellable]()
    private var isLogging: Bool {
        get {
            return queue.sync { _isLogging }
        }
        set {
            queue.sync { _isLogging = newValue }
        }
    }
    private var _isLogging = false

    private let queue = DispatchQueue(label: "com.walletApp.loggingService")

    func setUpUser(account: String, clientId: String) {
        let user = User()
        user.userId = clientId
        user.data = ["account": account]
        SentrySDK.setUser(user)
    }

    func configure() {
        guard let sentryDsn = InputConfig.sentryDsn, !sentryDsn.isEmpty  else { return }
        SentrySDK.start { options in
            options.dsn = "https://\(sentryDsn)"
            options.tracesSampleRate = 1.0
        }
    }

    func startLogging() {
        guard !isLogging else { return }
        isLogging = true

        Networking.instance.logsPublisher
            .sink { [weak self] log in
                self?.queue.sync {
                    switch log {
                    case .error(let log):
                        SentrySDK.capture(error: LoggingError.networking(log.aggregated))
                    case .warn(let log):
                        // Example of setting level to warning
                        var event = Event(level: .warning)
                        event.message = SentryMessage(formatted: log.aggregated)
                        SentrySDK.capture(event: event)
                    default:
                        return
                    }
                }
            }
            .store(in: &publishers)
    }
}
