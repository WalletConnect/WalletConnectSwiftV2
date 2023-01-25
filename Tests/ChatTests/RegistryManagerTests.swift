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

    let initialAccount = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let newAccount = Account("eip155:2:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!

    override func setUp() {
        registry = KeyValueRegistry()
        networkingInteractor = NetworkingInteractorMock()
        kms = KeyManagementServiceMock()
        topicToRegistryRecordStore = CodableStore(defaults: RuntimeKeyValueStorage(), identifier: "")
        accountService = AccountService(currentAccount: initialAccount)
        registryManager = RegistryService(
            registry: registry,
            accountService: accountService,
            networkingInteractor: networkingInteractor,
            kms: kms,
            logger: ConsoleLoggerMock(),
            topicToRegistryRecordStore: topicToRegistryRecordStore)
    }

    func testRegister() async {
        XCTAssertEqual(accountService.currentAccount, initialAccount)

        _ = try! await registryManager.register(account: newAccount)
        XCTAssert(!networkingInteractor.subscriptions.isEmpty, "networkingInteractors subscribes to new topic")

        let resolved = try! await registry.resolve(account: newAccount)
        XCTAssertNotNil(resolved, "register account is resolvable")
        XCTAssertFalse(topicToRegistryRecordStore.getAll().isEmpty, "stores topic to invitation")
        XCTAssertEqual(accountService.currentAccount, newAccount)
    }
}
