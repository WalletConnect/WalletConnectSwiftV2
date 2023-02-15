import XCTest
import WalletConnectNetworking
import WalletConnectKMS
import WalletConnectUtils
@testable import WalletConnectChat

final class RegistryTests: XCTestCase {

    let account = Account("eip155:1:0x15bca56b6e2728aec2532df9d436bd1600e86688")!
    let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")

    var sut: IdentityRegisterService!
    var storage: IdentityStorage!
    var signer: CacaoMessageSigner!

    override func setUp() {
        let keyserverURL = URL(string: "https://staging.keys.walletconnect.com")!
        let httpService = HTTPNetworkClient(host: keyserverURL.host!)
        let accountService = AccountService(currentAccount: account)
        let identityNetworkService = IdentityNetworkService(accountService: accountService, httpService: httpService)
        storage = IdentityStorage(keychain: KeychainStorageMock())
        sut = IdentityRegisterService(
            keyserverURL: keyserverURL,
            identityStorage: storage,
            identityNetworkService: identityNetworkService,
            iatProvader: DefaultIATProvider(),
            messageFormatter: SIWECacaoFormatter()
        )
        signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
    }

    func testRegisterIdentityAndInviteKey() async throws {
        var message: String!
        let publicKey = try await sut.registerIdentity(account: account, isPrivate: false) { msg in
            message = msg
            return try! signer.sign(message: msg, privateKey: privateKey, type: .eip191)
        }

        let cacao = try await sut.resolveIdentity(publicKey: publicKey)
        XCTAssertEqual(try SIWECacaoFormatter().formatMessage(from: cacao.p), message)

        let recovered = storage.getIdentityKey(for: account)!.publicKey.hexRepresentation
        XCTAssertEqual(publicKey, recovered)

        let inviteKey = try await sut.registerInvite(account: account, isPrivate: false, onSign: { msg in
            return try! signer.sign(message: msg, privateKey: privateKey, type: .eip191)
        })

        let recoveredKey = storage.getInviteKey(for: account)!
        XCTAssertEqual(inviteKey, recoveredKey.publicKey.hexRepresentation)

        let resolvedKey = try await sut.resolveInvite(account: account)
        XCTAssertEqual(inviteKey, resolvedKey)
    }
}
