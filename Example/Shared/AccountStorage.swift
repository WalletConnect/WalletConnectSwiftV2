import Foundation

final class AccountStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var importAccount: ImportAccount? {
        get {
            guard let value = UserDefaults.standard.string(forKey: "account") else {
                return nil
            }
            guard let account = ImportAccount(input: value) else {
                // Migration
                self.importAccount = nil
                return nil
            }
            return account
        }
        set {
            UserDefaults.standard.set(newValue?.storageId, forKey: "account")
        }
    }
}
