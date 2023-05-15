import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var chatStorage: ChatStorage
    private var publishers = [AnyCancellable]()

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        chatStorage: ChatStorage,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.chatStorage = chatStorage
    }
}
