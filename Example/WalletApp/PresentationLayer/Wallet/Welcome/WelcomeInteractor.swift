final class WelcomeInteractor {

    private let accountStorage: AccountStorage

    init(accountStorage: AccountStorage) {
        self.accountStorage = accountStorage
    }

    func saveAccount(_ account: ImportAccount) {
        accountStorage.importAccount = account
    }
}
