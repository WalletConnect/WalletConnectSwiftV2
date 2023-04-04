import Foundation
import XCTest
@testable import WalletConnectChat
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine

final class ChatTests: XCTestCase {

    lazy var invitee: ChatClient = makeClient(prefix: "🦖 Invitee", account: inviteeAccount)
    lazy var inviter: ChatClient = makeClient(prefix: "🍄 Inviter", account: inviterAccount)

    private var publishers = [AnyCancellable]()

    let inviteeAccount = Account("eip155:1:0x5927e14698A00D799d3430ad919D94aB1dD87458")!
    let inviterAccount = Account("eip155:1:0xf3Dd9c482061b7a977aF08D8a6c28f9CB7b72043")!

    let privateKey1 = Data(hex: "c0a4b45292a714b56cc00faf197a963f8b6e04334507a70ab0b9defc3bc8492a")
    let privateKey2 = Data(hex: "f4230d5166b30a20bd092b3afa471023caefdba9ecdf41a3c953712ead2d558a")

    override func setUp() async throws {
        try await invitee.register(account: inviteeAccount) { [unowned self] message in
            sign(message, privateKey: privateKey1)
        }
        try await inviter.register(account: inviterAccount) { [unowned self] message in
            sign(message, privateKey: privateKey2)
        }
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
        return ChatClientFactory.create(keyserverURL: keyserverURL, relayClient: relayClient, networkingInteractor: networkingInteractor, keychain:  keychain, logger: logger, keyValueStorage: keyValueStorage)
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

    func sign(_ message: String, privateKey: Data) -> SigningResult {
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        return .signed(try! signer.sign(message: message, privateKey: privateKey, type: .eip191))
    }
}
