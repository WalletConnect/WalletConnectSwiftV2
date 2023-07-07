import Combine

struct ApplicationConfigurator: Configurator {

    private var publishers = Set<AnyCancellable>()

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func configure() {
        if let importAccount = app.accountStorage.importAccount {
            MainModule.create(app: app, importAccount: importAccount)
                .present()
        } else {
            WelcomeModule.create(app: app).present()
        }
    }
}
