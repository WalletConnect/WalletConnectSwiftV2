import Foundation
import XCTest
@testable import WalletConnectChat
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine

final class ChatTests: XCTestCase {
    var invitee: ChatClient!
    var inviter: ChatClient!
    private var publishers = [AnyCancellable]()

    let inviteeAccount = Account("eip155:1:0x15bca56b6e2728aec2532df9d436bd1600e86688")!
    let inviterAccount = Account("eip155:2:0x15bca56b6e2728aec2532df9d436bd1600e86688")!

    let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")

    override func setUp() async throws {
        invitee = makeClient(prefix: "🦖 Invitee", account: inviteeAccount)
        inviter = makeClient(prefix: "🍄 Inviter", account: inviterAccount)

        try await invitee.register(account: inviteeAccount, onSign: sign)
        try await inviter.register(account: inviterAccount, onSign: sign)
    }

    override func setUp() {

    }

    func makeClient(prefix: String, account: Account) -> ChatClient {
        let keyserverURL = URL(string: "https://staging.keys.walletconnect.com")!
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: InputConfig.relayHost, projectId: InputConfig.projectId, keychainStorage: keychain, socketFactory: DefaultSocketFactory(), logger: logger)
        return ChatClientFactory.create(account: account, keyserverURL: keyserverURL, relayClient: relayClient, keychain:  keychain, logger: logger, keyValueStorage: RuntimeKeyValueStorage())
    }

    func testInvite() async throws {
        let inviteExpectation = expectation(description: "invitation expectation")
        let inviteePublicKey = try await inviter.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        _ = try await inviter.invite(invite: invite)
        invitee.invitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)
        wait(for: [inviteExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testAcceptAndCreateNewThread() {
        let newThreadInviterExpectation = expectation(description: "new thread on inviting client expectation")
        let newThreadinviteeExpectation = expectation(description: "new thread on invitee client expectation")

        Task(priority: .high) {
            let inviteePublicKey = try await inviter.resolve(account: inviteeAccount)
            let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
            try! await inviter.invite(invite: invite)
        }

        invitee.invitePublisher.sink { [unowned self] invite in
            Task { try! await invitee.accept(inviteId: invite.id) }
        }.store(in: &publishers)

        invitee.newThreadPublisher.sink { _ in
            newThreadinviteeExpectation.fulfill()
        }.store(in: &publishers)

        inviter.newThreadPublisher.sink { _ in
            newThreadInviterExpectation.fulfill()
        }.store(in: &publishers)

        wait(for: [newThreadinviteeExpectation, newThreadInviterExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testMessage() {
        let messageExpectation = expectation(description: "message received")
        messageExpectation.expectedFulfillmentCount = 4

        Task(priority: .high) {
            let inviteePublicKey = try await inviter.resolve(account: inviteeAccount)
            let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
            try! await inviter.invite(invite: invite)
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

        wait(for: [messageExpectation], timeout: InputConfig.defaultTimeout)
    }

    private func sign(_ message: String) -> CacaoSignature {
        let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        return try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
    }
}
