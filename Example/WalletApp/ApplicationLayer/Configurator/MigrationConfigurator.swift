struct MigrationConfigurator: Configurator {
    let app: Application

    init(app: Application) {
        self.app = app
    }

    func configure() {}
}
