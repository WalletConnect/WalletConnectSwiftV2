import Foundation
import Sentry

struct ThirdPartyConfigurator: Configurator {

    func configure() {
    }

    private func configureLogging() {
        LoggingService.instance.configure()
    }
}
