import Foundation
import XCTest
@testable import Chat
import WalletConnectUtils
import WalletConnectNetworking
import WalletConnectKMS
@testable import TestingUtils

final class RegistryManagerTests: XCTestCase {
    var registryManager: RegistryService!
    var networkingInteractor: NetworkingInteractorMock!
    var topicToRegistryRecordStore: CodableStore<RegistryRecord>!
    var registry: Registry!
    var kms: KeyManagementServiceMock!

    override func setUp() {
        registry = KeyValueRegistry()
        networkingInteractor = NetworkingInteractorMock()
        kms = KeyManagementServiceMock()
        topicToRegistryRecordStore = CodableStore(defaults: RuntimeKeyValueStorage(), identifier: "")
        registryManager = RegistryService(
            registry: registry,
            networkingInteractor: networkingInteractor,
            kms: kms,
            logger: ConsoleLoggerMock(),
            topicToRegistryRecordStore: topicToRegistryRecordStore)
    }

    func testRegister() async {
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        _ = try! await registryManager.register(account: account)
        XCTAssert(!networkingInteractor.subscriptions.isEmpty, "networkingInteractors subscribes to new topic")
        let resolved = try! await registry.resolve(account: account)
        XCTAssertNotNil(resolved, "register account is resolvable")
        XCTAssertFalse(topicToRegistryRecordStore.getAll().isEmpty, "stores topic to invitation")
    }
}
