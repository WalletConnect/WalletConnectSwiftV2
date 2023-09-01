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
    private var isLogging = false
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
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
    }

    func startLogging() {
        queue.sync {
            guard isLogging == false else { return }
            isLogging = true
        }

        Networking.instance.logsPublisher
            .sink { log in
                self.queue.sync {
                    switch log {
                    case .error(let log):
                        SentrySDK.capture(error: LoggingError.networking(log.aggregated))
                    case .warn(let log):
                        SentrySDK.capture(message: log.aggregated)
                    default:
                        return
                    }
                }
            }
            .store(in: &publishers)
    }
}
