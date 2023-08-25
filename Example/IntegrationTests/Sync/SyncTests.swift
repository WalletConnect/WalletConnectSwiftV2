import Foundation
import Combine
import XCTest
import Web3
@testable import WalletConnectSync
@testable import WalletConnectSigner

final class SyncTests: XCTestCase {

    struct TestObject: DatabaseObject {
        let id: String
        let value: String

        var databaseId: String {
            return id
        }
    }

    var publishers = Set<AnyCancellable>()

    var client1: SyncClient!
    var client2: SyncClient!

    var indexStore1: SyncIndexStore!
    var indexStore2: SyncIndexStore!

    var syncStore1: SyncStore<TestObject>!
    var syncStore2: SyncStore<TestObject>!

    var signer: MessageSigner!

    let storeName = "SyncTests_store"

    var account: Account {
        return Account("eip155:1:" + pk.address.hex(eip55: true))!
    }

    let pk = try! EthereumPrivateKey()

    var privateKey: Data {
        return Data(pk.rawPrivateKey)
    }

    override func setUp() async throws {
        indexStore1 = makeIndexStore()
        indexStore2 = makeIndexStore()
        client1 = makeClient(indexStore: indexStore1, suffix: "❤️")
        client2 = makeClient(indexStore: indexStore2, suffix: "💜")
        syncStore1 = makeSyncStore(client: client1, indexStore: indexStore1)
        syncStore2 = makeSyncStore(client: client2, indexStore: indexStore2)
        signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
    }

    func makeClient(indexStore: SyncIndexStore, suffix: String) -> SyncClient {
        let syncSignatureStore = SyncSignatureStore(keychain: KeychainStorageMock())
        let keychain = KeychainStorageMock()
        let kms = KeyManagementService(keychain: keychain)
        let derivationService = SyncDerivationService(syncStorage: syncSignatureStore, bip44: DefaultBIP44Provider(), kms: kms)
        let logger = ConsoleLogger(prefix: suffix, loggingLevel: .debug)
        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            logger: logger)
        let networkingInteractor = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: logger,
            keychainStorage: keychain,
            keyValueStorage: RuntimeKeyValueStorage())
        let historyStore = CodableStore<Int64>(defaults: RuntimeKeyValueStorage(), identifier: "historyStore")
        let syncHistoryStore = SyncHistoryStore(store: historyStore)
        let syncService = SyncService(networkInteractor: networkingInteractor, derivationService: derivationService, signatureStore: syncSignatureStore, indexStore: indexStore, historyStore: syncHistoryStore, logger: logger)
        return SyncClient(syncService: syncService, syncSignatureStore: syncSignatureStore)
    }

    func makeIndexStore() -> SyncIndexStore {
        let store = CodableStore<SyncRecord>(defaults: RuntimeKeyValueStorage(), identifier: "indexStore")
        return SyncIndexStore(store: store)
    }

    func makeSyncStore(client: SyncClient, indexStore: SyncIndexStore) -> SyncStore<TestObject> {
        let objectStore = KeyedDatabase<TestObject>(storage: RuntimeKeyValueStorage(), identifier: "objectStore")
        return SyncStore(name: storeName, syncClient: client, indexStore: indexStore, objectStore: objectStore)
    }

    func testSync() async throws {
        let setExpectation = expectation(description: "syncSetTest")
        let delExpectation = expectation(description: "syncDelTest")
        let uptExpectation = expectation(description: "syncUptTest")

        let object = TestObject(id: "id-1", value: "value-1")
        let updated = TestObject(id: "id-1", value: "value-2")

        syncStore1.syncUpdatePublisher.sink { (_, _, update) in
            switch update {
            case .set:
                XCTFail()
            case .delete:
                delExpectation.fulfill()
            case .update:
                XCTFail()
            }
        }.store(in: &publishers)

        syncStore2.syncUpdatePublisher.sink { (_, _, update) in
            switch update {
            case .set:
                setExpectation.fulfill()
            case .delete:
                XCTFail()
            case .update:
                uptExpectation.fulfill()
            }
        }.store(in: &publishers)

        // Configure clients

        try await registerClient(client: client1)
        try await registerClient(client: client2)

        // Testing SyncStore `set`

        try await syncStore1.set(object: object, for: account)

        wait(for: [setExpectation], timeout: InputConfig.defaultTimeout)

        XCTAssertEqual(try syncStore1.getAll(for: account), [object])
        XCTAssertEqual(try syncStore2.getAll(for: account), [object])

        // Testing SyncStore `update`

        try await syncStore1.set(object: updated, for: account)

        wait(for: [uptExpectation], timeout: InputConfig.defaultTimeout)

        XCTAssertEqual(try syncStore1.getAll(for: account), [updated])
        XCTAssertEqual(try syncStore2.getAll(for: account), [updated])

        // Testing SyncStore `delete`

        try await syncStore2.delete(id: object.id, for: account)

        wait(for: [delExpectation], timeout: InputConfig.defaultTimeout)

        XCTAssertEqual(try syncStore1.getAll(for: account), [])
        XCTAssertEqual(try syncStore2.getAll(for: account), [])
    }

    private func registerClient(client: SyncClient) async throws {
        let message = client.getMessage(account: account)

        let signature = try signer.sign(message: message, privateKey: privateKey, type: .eip191)

        try await client.register(account: account, signature: signature)
        try await client.create(account: account, store: storeName)
        try await client.subscribe(account: account, store: storeName)
    }
}
