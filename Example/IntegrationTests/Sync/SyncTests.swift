import Foundation
import XCTest
@testable import WalletConnectSync
@testable import WalletConnectSigner

final class SyncTests: XCTestCase {
    var client: SyncClient!
    var store: SyncStorage!
    var signer: MessageSigner!

    let account = Account("0x1FF34C90a0850Fe7227fcFA642688b9712477482")!
    let privateKey = Data(hex: "99c6f0a7ac44d40d3d7f31083e9f5b045d4bf932fdf9f4a3c241cdd3cbc98045")

    override func setUp() async throws {
        client = makeClient()
        signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
    }

    func makeClient() -> SyncClient {
        let syncStorage = SyncStorage(keychain: KeychainStorageMock())
        return SyncClient(syncStorage: syncStorage)
    }

    func testSync() async throws {
        let message = client.getMessage(account: account)
        let signature = try signer.sign(message: message, privateKey: privateKey, type: .eip191)

        try client.register(account: account, signature: signature)

        XCTAssertEqual(try store.getSignature(for: account), signature.s)
    }
}
