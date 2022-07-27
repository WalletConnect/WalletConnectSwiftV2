final class ImportInteractor {
    private let registerService: RegisterService
    private let accountStorage: AccountStorage

    init(registerService: RegisterService, accountStorage: AccountStorage) {
        self.registerService = registerService
        self.accountStorage = accountStorage
    }

    func save(account: Account) {
        accountStorage.account = account
    }

    func register(account: Account) async {
        await registerService.register(account: account)
    }
}
