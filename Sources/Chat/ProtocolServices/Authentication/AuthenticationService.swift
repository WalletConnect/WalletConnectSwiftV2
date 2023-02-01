import Foundation

final class AuthenticationService {

    private let accountService: AccountService

    init(accountService: AccountService) {
        self.accountService = accountService
    }


}
