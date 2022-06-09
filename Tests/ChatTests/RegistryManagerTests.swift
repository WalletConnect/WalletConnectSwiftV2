import Foundation
import XCTest
@testable import Chat
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import TestingUtils

final class RegistryManagerTests: XCTestCase {
    var registryManager: RegistryManager!
    var networkingInteractor: NetworkingInteractorMock!
    var topicToInvitationPubKeyStore: CodableStore<String>!
    var registry: Registry!
    var kms: KeyManagementServiceMock!
    
    override func setUp() {
        registry = KeyValueRegistry()
        networkingInteractor = NetworkingInteractorMock()
        kms = KeyManagementServiceMock()
        topicToInvitationPubKeyStore = CodableStore(defaults: RuntimeKeyValueStorage(), identifier: "")
        registryManager = RegistryManager(
            registry: registry,
            networkingInteractor: networkingInteractor,
            kms: kms,
            logger: ConsoleLoggerMock(),
            topicToInvitationPubKeyStore: topicToInvitationPubKeyStore)
    }
    
    func testRegister() async {
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        try! await registryManager.register(account: account)
        XCTAssert(!networkingInteractor.subscriptions.isEmpty, "networkingInteractors subscribes to new topic")
        let resolved = try! await registry.resolve(account: account)
        XCTAssertNotNil(resolved, "register account is resolvable")
        XCTAssertFalse(topicToInvitationPubKeyStore.getAll().isEmpty, "stores topic to invitation")
    }
}

