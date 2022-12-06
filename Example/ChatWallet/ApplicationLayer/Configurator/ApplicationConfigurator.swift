import Combine

struct ApplicationConfigurator: Configurator {

    private var publishers = Set<AnyCancellable>()

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func configure() {
        WalletModule.create(app: app).present()
    }
}
