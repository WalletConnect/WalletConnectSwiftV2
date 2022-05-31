
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
        client1 = makeClient(prefix: "🦖")
        client2 = makeClient(prefix: "🍄")
    }
    
    private func waitClientsConnected() async {
        let group = DispatchGroup()
        group.enter()
        client1.onConnected = {
            group.leave()
        }
        group.enter()
        client2.onConnected = {
            group.leave()
        }
        group.wait()
        return
    }
    
    func makeClient(prefix: String) -> Chat {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let relayHost = "relay.walletconnect.com"
        let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
        let relayClient = RelayClient(relayHost: relayHost, projectId: projectId, logger: logger)
        let keychain = KeychainStorage(keychainService: KeychainServiceFake(), serviceIdentifier: "")

        return Chat(registry: registry, relayClient: relayClient, kms: KeyManagementService(keychain: keychain), logger: logger)
    }
    
    func testInvite() async {
        await waitClientsConnected()
        let inviteExpectation = expectation(description: "invitation expectation")
        let account = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        client1.register(account: account)
        client2.invite(account: account)
        client1.onInvite = { invite in
            inviteExpectation.fulfill()
        }
        wait(for: [inviteExpectation], timeout: 4)
    }
    
    
//    func testNewThread() async {
//        await waitClientsConnected()
//        let newThreadExpectation = expectation(description: "new thread expectation")
//        let account = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
//        client1.register(account: account)
//        client2.invite(account: account)
//        client1.onInvite = { [unowned self] invite in
//            client1.accept(invite: invite)
//        }
//        client1.onNewThread = { [unowned self] thread in
//            newThreadExpectation.fulfill()
//        }
//        wait(for: [newThreadExpectation], timeout: 4)
//    }
}
