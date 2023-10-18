import Foundation
import XCTest
@testable import WalletConnectChat
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import WalletConnectSync
@testable import WalletConnectHistory
import WalletConnectRelay
import Combine
import Web3

final class ChatTests: XCTestCase {
    var invitee1: ChatClient!
    var inviter1: ChatClient!
    var invitee2: ChatClient!
    var inviter2: ChatClient!
    private var publishers = [AnyCancellable]()

    var inviteeAccount: Account {
        return Account("eip155:1:" + pk1.address.hex(eip55: true))!
    }

    var inviterAccount: Account {
        return Account("eip155:1:" + pk2.address.hex(eip55: true))!
    }

    let pk1 = try! EthereumPrivateKey()
    let pk2 = try! EthereumPrivateKey()

    var privateKey1: Data {
        return Data(pk1.rawPrivateKey)
    }
    var privateKey2: Data {
        return Data(pk2.rawPrivateKey)
    }

    override func setUp() async throws {
        invitee1 = makeClient(prefix: "🦖 Invitee", account: inviteeAccount)
        inviter1 = makeClient(prefix: "🍄 Inviter", account: inviterAccount)

        try await invitee1.register(account: inviteeAccount, domain: "") { message in
            return self.sign(message, privateKey: self.privateKey1)
        }
        try await inviter1.register(account: inviterAccount, domain: "") { message in
            return self.sign(message, privateKey: self.privateKey2)
        }
    }

    func makeClient(prefix: String, account: Account) -> ChatClient {
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let logger = ConsoleLogger(prefix: prefix, loggingLevel: .debug)
        let keyValueStorage = RuntimeKeyValueStorage()
        let keychain = KeychainStorageMock()
        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            logger: logger)

        let networkingInteractor = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: logger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage)

        let syncClient = SyncClientFactory.create(
            networkInteractor: networkingInteractor,
            bip44: DefaultBIP44Provider(),
            keychain: keychain
        )

        let historyClient = HistoryClientFactory.create(
            historyUrl: "https://history.walletconnect.com",
            relayUrl: "wss://relay.walletconnect.com",
            keyValueStorage: keyValueStorage,
            keychain: keychain,
            logger: logger
        )

        let clientId = try! networkingInteractor.getClientId()
        logger.debug("My client id is: \(clientId)")

        return ChatClientFactory.create(keyserverURL: keyserverURL, relayClient: relayClient, networkingInteractor: networkingInteractor, keychain:  keychain, logger: logger, storage: keyValueStorage, syncClient: syncClient, historyClient: historyClient)
    }

    func testInvite() async throws {
        let inviteExpectation = expectation(description: "invitation expectation")
        inviteExpectation.expectedFulfillmentCount = 2

        invitee1.newReceivedInvitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)

        inviter1.newSentInvitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)

        let inviteePublicKey = try await inviter1.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        _ = try await inviter1.invite(invite: invite)

        wait(for: [inviteExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testAcceptAndCreateNewThread() async throws {
        let newThreadInviterExpectation = expectation(description: "new thread on inviting client expectation")
        let newThreadinviteeExpectation = expectation(description: "new thread on invitee client expectation")

        invitee1.newReceivedInvitePublisher.sink { [unowned self] invite in
            Task { try! await invitee1.accept(inviteId: invite.id) }
        }.store(in: &publishers)

        invitee1.newThreadPublisher.sink { _ in
            newThreadinviteeExpectation.fulfill()
        }.store(in: &publishers)

        inviter1.newThreadPublisher.sink { _ in
            newThreadInviterExpectation.fulfill()
        }.store(in: &publishers)

        let inviteePublicKey = try await inviter1.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        try await inviter1.invite(invite: invite)

        wait(for: [newThreadinviteeExpectation, newThreadInviterExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testMessage() async throws {
        let messageExpectation = expectation(description: "message received")
        messageExpectation.expectedFulfillmentCount = 4

        invitee1.newReceivedInvitePublisher.sink { [unowned self] invite in
            Task { try! await invitee1.accept(inviteId: invite.id) }
        }.store(in: &publishers)

        invitee1.newThreadPublisher.sink { [unowned self] thread in
            Task { try! await invitee1.message(topic: thread.topic, message: "message1") }
        }.store(in: &publishers)

        inviter1.newThreadPublisher.sink { [unowned self] thread in
            Task { try! await inviter1.message(topic: thread.topic, message: "message2") }
        }.store(in: &publishers)

        inviter1.newMessagePublisher.sink { message in
            if message.authorAccount == self.inviterAccount {
                XCTAssertEqual(message.message, "message2")
            } else {
                XCTAssertEqual(message.message, "message1")
            }
            messageExpectation.fulfill()
        }.store(in: &publishers)

        invitee1.newMessagePublisher.sink { message in
            if message.authorAccount == self.inviteeAccount {
                XCTAssertEqual(message.message, "message1")
            } else {
                XCTAssertEqual(message.message, "message2")
            }
            messageExpectation.fulfill()
        }.store(in: &publishers)

        let inviteePublicKey = try await inviter1.resolve(account: inviteeAccount)
        let invite = Invite(message: "", inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        try await inviter1.invite(invite: invite)

        wait(for: [messageExpectation], timeout: InputConfig.defaultTimeout)
    }

    private func sign(_ message: String, privateKey: Data) -> SigningResult {
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        return .signed(try! signer.sign(message: message, privateKey: privateKey, type: .eip191))
    }
}
