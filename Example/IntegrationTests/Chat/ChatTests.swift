import Foundation
import XCTest
@testable import Chat
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine

final class ChatTests: XCTestCase {
    var invitee: ChatClient!
    var inviter: ChatClient!
    var registry: KeyValueRegistry!
    private var publishers = [AnyCancellable]()

    private let defaultTimeout: TimeInterval = 30

    override func setUp() {
        registry = KeyValueRegistry()
        invitee = makeClient(prefix: "🦖 Registered")
        inviter = makeClient(prefix: "🍄 Inviter")

        waitClientsConnected()
    }

    private func waitClientsConnected() {
        let expectation = expectation(description: "Wait Clients Connected")
        expectation.expectedFulfillmentCount = 2

        invitee.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                expectation.fulfill()
            }
        }.store(in: &publishers)

        inviter.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                expectation.fulfill()
            }
        }.store(in: &publishers)

        wait(for: [expectation], timeout: 5)
    }

    func makeClient(prefix: String) -> ChatClient {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let projectId = "3ca2919724fbfa5456a25194e369a8b4"
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: URLConfig.relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)
        return ChatClientFactory.create(registry: registry, relayClient: relayClient, kms: KeyManagementService(keychain: keychain), logger: logger, keyValueStorage: RuntimeKeyValueStorage())
    }

    func testInvite() async {
        let inviteExpectation = expectation(description: "invitation expectation")
        let inviteeAccount = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        let inviterAccount = Account(chainIdentifier: "eip155:1", address: "0x36275231673672234423f")!
        let pubKey = try! await invitee.register(account: inviteeAccount)
        try! await inviter.invite(publicKey: pubKey, peerAccount: inviteeAccount, openingMessage: "", account: inviterAccount)
        invitee.invitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)
        wait(for: [inviteExpectation], timeout: defaultTimeout)
    }

    func testAcceptAndCreateNewThread() {
        let newThreadInviterExpectation = expectation(description: "new thread on inviting client expectation")
        let newThreadinviteeExpectation = expectation(description: "new thread on invitee client expectation")
        let inviteeAccount = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        let inviterAccount = Account(chainIdentifier: "eip155:1", address: "0x36275231673672234423f")!

        Task(priority: .high) {
            let pubKey = try! await invitee.register(account: inviteeAccount)

            try! await inviter.invite(publicKey: pubKey, peerAccount: inviteeAccount, openingMessage: "opening message", account: inviterAccount)
        }

        invitee.invitePublisher.sink { [unowned self] invite in
            Task {try! await invitee.accept(inviteId: invite.id)}
        }.store(in: &publishers)

        invitee.newThreadPublisher.sink { _ in
            newThreadinviteeExpectation.fulfill()
        }.store(in: &publishers)

        inviter.newThreadPublisher.sink { _ in
            newThreadInviterExpectation.fulfill()
        }.store(in: &publishers)

        wait(for: [newThreadinviteeExpectation, newThreadInviterExpectation], timeout: defaultTimeout)
    }

    func testMessage() {
        let messageExpectation = expectation(description: "message received")
        messageExpectation.expectedFulfillmentCount = 4 // expectedFulfillmentCount 4 because onMessage() called on send too

        let inviteeAccount = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        let inviterAccount = Account(chainIdentifier: "eip155:1", address: "0x36275231673672234423f")!

        Task(priority: .high) {
            let pubKey = try! await invitee.register(account: inviteeAccount)
            try! await inviter.invite(publicKey: pubKey, peerAccount: inviteeAccount, openingMessage: "opening message", account: inviterAccount)
        }

        invitee.invitePublisher.sink { [unowned self] invite in
            Task {try! await invitee.accept(inviteId: invite.id)}
        }.store(in: &publishers)

        invitee.newThreadPublisher.sink { [unowned self] thread in
            Task {try! await invitee.message(topic: thread.topic, message: "message")}
        }.store(in: &publishers)

        inviter.newThreadPublisher.sink { [unowned self] thread in
            Task {try! await inviter.message(topic: thread.topic, message: "message")}
        }.store(in: &publishers)

        inviter.messagePublisher.sink { _ in
            messageExpectation.fulfill()
        }.store(in: &publishers)

        invitee.messagePublisher.sink { _ in
            messageExpectation.fulfill()
        }.store(in: &publishers)

        wait(for: [messageExpectation], timeout: defaultTimeout)
    }
}
