import Foundation
import XCTest
@testable import WalletConnectChat
import WalletConnectUtils
import WalletConnectNetworking
import WalletConnectKMS
@testable import TestingUtils

final class RegistryManagerTests: XCTestCase {
    var registryManager: RegistryService!
    var networkingInteractor: NetworkingInteractorMock!
    var topicToRegistryRecordStore: CodableStore<RegistryRecord>!
    var registry: Registry!
    var accountService: AccountService!
    var kms: KeyManagementServiceMock!
    var resubscriptionService: ResubscriptionService!
    var chatStorage: ChatStorage!
    var threadStore: KeyedDatabase<WalletConnectChat.Thread>!

    let initialAccount = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let newAccount = Account("eip155:2:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let mockAccount = Account("eip155:3:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!

    override func setUp() {
        registry = KeyValueRegistry()
        networkingInteractor = NetworkingInteractorMock()
        kms = KeyManagementServiceMock()
        topicToRegistryRecordStore = CodableStore(defaults: RuntimeKeyValueStorage(), identifier: "")
        accountService = AccountService(currentAccount: initialAccount)
        threadStore = KeyedDatabase(storage: RuntimeKeyValueStorage(), identifier: "")
        chatStorage = ChatStorage(
            messageStore: .init(storage: RuntimeKeyValueStorage(), identifier: ""),
            inviteStore: .init(storage: RuntimeKeyValueStorage(), identifier: ""),
            threadStore: threadStore
        )
        resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, accountService: accountService, chatStorage: chatStorage, logger: ConsoleLoggerMock())
        registryManager = RegistryService(
            registry: registry,
            accountService: accountService,
            resubscriptionService: resubscriptionService,
            networkingInteractor: networkingInteractor,
            kms: kms,
            logger: ConsoleLoggerMock(),
            topicToRegistryRecordStore: topicToRegistryRecordStore)
    }

    func testRegister() async throws {
        threadStore.set(Thread(topic: "topic1", selfAccount: mockAccount, peerAccount: mockAccount), for: newAccount.absoluteString)
        threadStore.set(Thread(topic: "topic2", selfAccount: mockAccount, peerAccount: mockAccount), for: newAccount.absoluteString)

        // Test accountService initial state
        XCTAssertEqual(accountService.currentAccount, initialAccount)

        let pubKey = try await registryManager.register(account: newAccount)

        // Test subscription for invite topic
        XCTAssert(!networkingInteractor.subscriptions.isEmpty, "networkingInteractors subscribes to new topic")

        // Test resubscription for threads
        XCTAssertTrue(networkingInteractor.subscriptions.contains("topic1"))
        XCTAssertTrue(networkingInteractor.subscriptions.contains("topic2"))

        let resolved = try await registry.resolve(account: newAccount)

        // Test resolved account pubKey
        XCTAssertEqual(pubKey, resolved)

        // Test topicToRegistryRecordStore filled
        XCTAssertFalse(topicToRegistryRecordStore.getAll().isEmpty, "stores topic to invitation")

        // Test current account changed
        XCTAssertEqual(accountService.currentAccount, newAccount)
    }
}
