import Foundation
import Sentry

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        configureLogging()
    }

    func configureLogging() {
        guard let sentryDns = InputConfig.sentryDns else { return }
        SentrySDK.start { options in
            options.dsn = "https://\(sentryDns)"
            options.debug = true // Enabled debug when first installing is always helpful
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
    }
}
