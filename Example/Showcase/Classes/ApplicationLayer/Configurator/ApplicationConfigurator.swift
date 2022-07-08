struct ApplicationConfigurator: Configurator {

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func configure() {
        ChatListModule.create(app: app)
            .wrapToNavigationController()
            .present()
    }
}
