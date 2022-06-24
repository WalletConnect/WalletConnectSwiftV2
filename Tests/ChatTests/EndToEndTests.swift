import Foundation
import XCTest
@testable import Chat
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import TestingUtils
import WalletConnectRelay
import Combine

final class ChatTests: XCTestCase {
    var invitee: Chat!
    var inviter: Chat!
    var registry: KeyValueRegistry!
    private var publishers = [AnyCancellable]()

    override func setUp() {
        registry = KeyValueRegistry()
        invitee = makeClient(prefix: "🦖 Registered")
        inviter = makeClient(prefix: "🍄 Inviter")
    }

    private func waitClientsConnected() async {
        let group = DispatchGroup()
        group.enter()
        invitee.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                group.leave()
            }
        }.store(in: &publishers)

        group.enter()
        inviter.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                group.leave()
            }
        }.store(in: &publishers)
        group.wait()
        return
    }

    func makeClient(prefix: String) -> Chat {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let relayHost = "dev.relay.walletconnect.com"
        let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
        let relayClient = RelayClient(relayHost: relayHost, projectId: projectId, logger: logger)
        let keychain = KeychainStorage(keychainService: KeychainServiceFake(), serviceIdentifier: "")

        return Chat(registry: registry, relayClient: relayClient, kms: KeyManagementService(keychain: keychain), logger: logger, keyValueStorage: RuntimeKeyValueStorage())
    }

    func testInvite() async {
//        await waitClientsConnected()
//        let inviteExpectation = expectation(description: "invitation expectation")
//        let account = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
//        let pubKey = try! await invitee.register(account: account)
//        try! await inviter.invite(publicKey: pubKey, openingMessage: "")
//        invitee.invitePublisher.sink { _ in
//            inviteExpectation.fulfill()
//        }.store(in: &publishers)
//        wait(for: [inviteExpectation], timeout: 4)
    }

    func testAcceptAndCreateNewThread() async {
//        await waitClientsConnected()
//        let newThreadInviterExpectation = expectation(description: "new thread on inviting client expectation")
//        let newThreadinviteeExpectation = expectation(description: "new thread on invitee client expectation")
//        let account = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
//        let pubKey = try! await invitee.register(account: account)
//        try! await inviter.invite(publicKey: pubKey, openingMessage: "opening message")
//
//        invitee.invitePublisher.sink { [unowned self] inviteEnvelope in
//            Task {try! await invitee.accept(inviteId: inviteEnvelope.pubKey)}
//        }.store(in: &publishers)
//
//        invitee.newThreadPublisher.sink { _ in
//            newThreadinviteeExpectation.fulfill()
//        }.store(in: &publishers)
//
//        inviter.newThreadPublisher.sink { _ in
//            newThreadInviterExpectation.fulfill()
//        }.store(in: &publishers)
//
//        wait(for: [newThreadinviteeExpectation, newThreadInviterExpectation], timeout: 4)
    }
}
