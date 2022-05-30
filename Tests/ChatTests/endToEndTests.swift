
import Foundation
import XCTest
@testable import Chat
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import TestingUtils
import WalletConnectRelay

final class ChatTests: XCTestCase {
    var client1: Chat!
    var client2: Chat!
    var registry: KeyValueRegistry!
    
    override func setUp() {
        registry = KeyValueRegistry()
        client1 = makeClient()
        client2 = makeClient()
    }
    
    func makeClient() -> Chat {
        let relayHost = "relay.walletconnect.com"
        let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
        let relayClient = RelayClient(relayHost: relayHost, projectId: projectId)
        let keychain = KeychainStorage(keychainService: KeychainServiceFake(), serviceIdentifier: "")

        return Chat(registry: registry, relayClient: relayClient, kms: KeyManagementService(keychain: keychain))
    }
    
    func testInvite() {
        let inviteExpectation = expectation(description: "Proposer settles session")

        let account = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        client1.register(account: account)
        client2.invite(account: account)
        client1.onInvite = { [unowned self] invite in
            client1.accept(invite: invite)
            inviteExpectation.fulfill()
        }
        client1
        client1.message(threadTopic: , message: "test message")
        waitForExpectations(timeout: 20, handler: nil)

    }
}
