struct ApplicationConfigurator: Configurator {
    
    private let app: Application
    
    init(app: Application) {
        self.app = app
    }
    
    func configure() {
        MainModule.create(app: app).present()
    }
}
