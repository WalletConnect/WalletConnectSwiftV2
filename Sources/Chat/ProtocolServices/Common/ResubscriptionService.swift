import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let accountService: AccountService
    private let logger: ConsoleLogging
    private var chatStorage: ChatStorage
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         accountService: AccountService,
         chatStorage: ChatStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }

                Task(priority: .high) {
                    try await resubscribe(account: accountService.currentAccount)
                }
            }.store(in: &publishers)
    }

    func resubscribe(account: Account) async throws {
        let topics = chatStorage.getThreads(account: account).map { $0.topic }
        try await networkingInteractor.batchSubscribe(topics: topics)
    }

    func unsubscribe(account: Account) async throws {
        let topics = chatStorage.getThreads(account: account).map { $0.topic }
        try await networkingInteractor.batchUnsubscribe(topics: topics)
    }
}
