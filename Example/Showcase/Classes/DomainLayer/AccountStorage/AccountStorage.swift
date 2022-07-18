import Foundation

final class AccountStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var account: Account? {
        get {
            guard let value = UserDefaults.standard.string(forKey: "account") else {
                return nil
            }
            return Account(value)
        }
        set {
            UserDefaults.standard.set(newValue?.absoluteString, forKey: "account")
        }
    }
}
