import Foundation
import XCTest
@testable import WalletConnectChat
import WalletConnectUtils
import WalletConnectNetworking
import WalletConnectKMS
@testable import TestingUtils
@testable import WalletConnectIdentity

final class RegistryServiceTests: XCTestCase {
    var resubscriptionService: ResubscriptionService!
    var identityClient: IdentityClient!
    var identityStorage: IdentityStorage!
    var networkService: IdentityNetwotkServiceMock!
    var networkingInteractor: NetworkingInteractorMock!
    var kms: KeyManagementServiceMock!

    let account = Account("eip155:1:0x1AAe9864337E821f2F86b5D27468C59AA333C877")!
    let privateKey = "4dc0055d1831f7df8d855fc8cd9118f4a85ddc05395104c4cb0831a6752621a8"

    let cacaoStub: Cacao = {
        return Cacao(h: .init(t: ""), p: .init(iss: "", domain: "", aud: "", version: "", nonce: "", iat: "", nbf: "", exp: nil, statement: nil, requestId: nil, resources: nil), s: .init(t: .eip191, s: ""))
    }()

    let inviteKeyStub = "62720d14643acf0f7dd87513b079502f56be414a2f2ea4719342cf088c794173"

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        kms = KeyManagementServiceMock()
        identityStorage = IdentityStorage(keychain: KeychainStorageMock())
        networkService = IdentityNetwotkServiceMock(cacao: cacaoStub, inviteKey: inviteKeyStub)

        let identitySevice = IdentityService(
            keyserverURL: URL(string: "https://www.url.com")!,
            kms: kms,
            storage: identityStorage,
            networkService: networkService,
            iatProvader: DefaultIATProvider(),
            messageFormatter: SIWECacaoFormatter()
        )
        identityClient = IdentityClient(identityService: identitySevice, identityStorage: identityStorage, logger: ConsoleLoggerMock())

        let storage = RuntimeKeyValueStorage()
        let accountService = AccountService(currentAccount: account)
        let chatStorage = ChatStorage(
            accountService: accountService,
            messageStore: .init(storage: storage, identifier: ""),
            receivedInviteStore: .init(storage: storage, identifier: ""),
            sentInviteStore: .init(storage: storage, identifier: ""),
            threadStore: .init(storage: storage, identifier: "")
        )
        resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, kms: kms, accountService: accountService, chatStorage: chatStorage, logger: ConsoleLoggerMock())
    }

    func testRegister() async throws {
        let pubKey = try await identityClient.register(account: account, onSign: onSign)

        XCTAssertTrue(networkService.callRegisterIdentity)

        let identityKey = try identityStorage.getIdentityKey(for: account)
        XCTAssertEqual(identityKey.publicKey.hexRepresentation, pubKey)
    }

    func testGoPublic() async throws {
        XCTAssertTrue(networkingInteractor.subscriptions.isEmpty)

        _ = try await identityClient.register(account: account, onSign: onSign)
        let inviteKey = try await identityClient.goPublic(account: account)
        try await resubscriptionService.subscribeForInvites(inviteKey: inviteKey)

        XCTAssertNoThrow(try identityStorage.getInviteKey(for: account))
        XCTAssertTrue(networkService.callRegisterInvite)

        XCTAssertEqual(networkingInteractor.subscriptions.count, 1)
        XCTAssertNotNil(kms.getPublicKey(for: networkingInteractor.subscriptions[0]))
    }

    func testUnregister() async throws {
        XCTAssertThrowsError(try identityStorage.getIdentityKey(for: account))

        _ = try await identityClient.register(account: account, onSign: onSign)
        XCTAssertNoThrow(try identityStorage.getIdentityKey(for: account))

        try await identityClient.unregister(account: account, onSign: onSign)
        XCTAssertThrowsError(try identityStorage.getIdentityKey(for: account))
        XCTAssertTrue(networkService.callRemoveIdentity)
    }

    func testGoPrivate() async throws {
        let invitePubKey = try AgreementPublicKey(hex: inviteKeyStub)
        try identityStorage.saveInviteKey(invitePubKey, for: account)

        let identityKey = SigningPrivateKey()
        try identityStorage.saveIdentityKey(identityKey, for: account)

        let topic = invitePubKey.rawRepresentation.sha256().toHexString()
        try await networkingInteractor.subscribe(topic: topic)

        let inviteKey = try await identityClient.goPrivate(account: account)
        resubscriptionService.unsubscribeFromInvites(inviteKey: inviteKey)

        XCTAssertThrowsError(try identityStorage.getInviteKey(for: account))
        XCTAssertTrue(networkingInteractor.unsubscriptions.contains(topic))
    }

    func testResolve() async throws {
        let inviteKey = try await identityClient.resolveInvite(account: account)

        XCTAssertEqual(inviteKey, inviteKeyStub)
    }

    private func onSign(_ message: String) -> SigningResult {
        return .signed(CacaoSignature(t: .eip191, s: ""))
    }
}
