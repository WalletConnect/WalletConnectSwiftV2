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

    func makeClient(prefix: String, account: Account) -> ChatClient {
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: InputConfig.relayHost, projectId: InputConfig.projectId, keychainStorage: keychain, socketFactory: DefaultSocketFactory(), logger: logger)
        let keyValueStorage = RuntimeKeyValueStorage()
        let networkingInteractor = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: logger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage)
        return ChatClientFactory.create(account: account, keyserverURL: keyserverURL, relayClient: relayClient, networkingInteractor: networkingInteractor, keychain:  keychain, logger: logger, keyValueStorage: keyValueStorage)
    }

    func testInvite() async throws {
        let inviteExpectation = expectation(description: "invitation expectation")
        inviteExpectation.expectedFulfillmentCount = 2

        invitee.newReceivedInvitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)

        inviter.newSentInvitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)

        let inviteePublicKey = try await inviter.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        _ = try await inviter.invite(invite: invite)

        wait(for: [inviteExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testAcceptAndCreateNewThread() async throws {
        let newThreadInviterExpectation = expectation(description: "new thread on inviting client expectation")
        let newThreadinviteeExpectation = expectation(description: "new thread on invitee client expectation")

        invitee.newReceivedInvitePublisher.sink { [unowned self] invite in
            Task { try! await invitee.accept(inviteId: invite.id) }
        }.store(in: &publishers)

        invitee.newThreadPublisher.sink { _ in
            newThreadinviteeExpectation.fulfill()
        }.store(in: &publishers)

        inviter.newThreadPublisher.sink { _ in
            newThreadInviterExpectation.fulfill()
        }.store(in: &publishers)

        let inviteePublicKey = try await inviter.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        try await inviter.invite(invite: invite)

        wait(for: [newThreadinviteeExpectation, newThreadInviterExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testMessage() async throws {
        let messageExpectation = expectation(description: "message received")
        messageExpectation.expectedFulfillmentCount = 4

        invitee.newReceivedInvitePublisher.sink { [unowned self] invite in
            Task { try! await invitee.accept(inviteId: invite.id) }
        }.store(in: &publishers)

        invitee.newThreadPublisher.sink { [unowned self] thread in
            Task { try! await invitee.message(topic: thread.topic, message: "message1") }
        }.store(in: &publishers)

        inviter.newThreadPublisher.sink { [unowned self] thread in
            Task { try! await inviter.message(topic: thread.topic, message: "message2") }
        }.store(in: &publishers)

        inviter.newMessagePublisher.sink { message in
            if message.authorAccount == self.inviterAccount {
                XCTAssertEqual(message.message, "message2")
            } else {
                XCTAssertEqual(message.message, "message1")
            }
            messageExpectation.fulfill()
        }.store(in: &publishers)

        invitee.newMessagePublisher.sink { message in
            if message.authorAccount == self.inviteeAccount {
                XCTAssertEqual(message.message, "message1")
            } else {
                XCTAssertEqual(message.message, "message2")
            }
            messageExpectation.fulfill()
        }.store(in: &publishers)

        let inviteePublicKey = try await inviter.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        try await inviter.invite(invite: invite)

        wait(for: [messageExpectation], timeout: InputConfig.defaultTimeout)
    }

    private func sign(_ message: String) -> SigningResult {
        let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        return .signed(try! signer.sign(message: message, privateKey: privateKey, type: .eip191))
    }
}
