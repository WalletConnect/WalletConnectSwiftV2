import Foundation

final class NotifyAccountProvider {
    enum Errors: Error {
        case currentAccountNotFound
    }

    private(set) var currentAccount: Account?

    func setAccount(_ account: Account) {
        self.currentAccount = account
    }

    func logout() {
        self.currentAccount = nil
    }

    func getCurrentAccount() throws -> Account {
        guard let currentAccount else { throw Errors.currentAccountNotFound }
        return currentAccount
    }
}
