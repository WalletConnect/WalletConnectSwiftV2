import Foundation

final class AccountService {

    private(set) var currentAccount: Account

    init(currentAccount: Account) {
        self.currentAccount = currentAccount
    }

    func setAccount(_ account: Account) {
        currentAccount = account
    }
}
