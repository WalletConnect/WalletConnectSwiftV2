import Foundation
import Sentry

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        configureLogging()
    }

    func configureLogging() {
        guard let sentryDsn = InputConfig.sentryDsn else { return }
        SentrySDK.start { options in
            options.dsn = "https://\(sentryDsn)"
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
    }
}
