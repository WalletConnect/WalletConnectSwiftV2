import Foundation

struct ThirdPartyConfigurator: Configurator {

    func configure() {
    }

    private func configureLogging() {
        LoggingService.instance.configure()
    }
}
