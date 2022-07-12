import Combine

struct ApplicationConfigurator: Configurator {

    private var publishers = Set<AnyCancellable>()

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func configure() {
        registerAccount()

        WelcomeModule.create(app: app).present()
    }
}

private extension ApplicationConfigurator {

    func registerAccount() {
        Task(priority: .high) {
            for await status in app.chatService.connectionPublisher {
                guard status == .connected else {
                    fatalError("Not Connected")
                }

                print("Socket connected")
                try! await app.chatService.register(account: ChatService.selfAccount)
            }
        }
    }
}
