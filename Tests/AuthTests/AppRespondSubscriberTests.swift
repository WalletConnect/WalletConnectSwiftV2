import Foundation
import XCTest
@testable import Auth
@testable import WalletConnectUtils
@testable import WalletConnectNetworking
@testable import WalletConnectKMS
@testable import TestingUtils
import JSONRPC

class AppRespondSubscriberTests: XCTestCase {
    var networkingInteractor: NetworkingInteractorMock!
    var sut: AppRespondSubscriber!
    var messageFormatter: SIWEMessageFormatter!
    var rpcHistory: RPCHistory!
    let defaultTimeout: TimeInterval = 0.01
    let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
    let prvKey = Data(hex: "462c1dad6832d7d96ccf87bd6a686a4110e114aaaebd5512e552c0e3a87b480f")
    var messageSigner: MessageSigner!
    var pairingStorage: WCPairingStorageMock!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        messageFormatter = SIWEMessageFormatter()
        messageSigner = MessageSigner()
        rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: RuntimeKeyValueStorage())
        pairingStorage = WCPairingStorageMock()
        sut = AppRespondSubscriber(
            networkingInteractor: networkingInteractor,
            logger: ConsoleLoggerMock(),
            rpcHistory: rpcHistory,
            signatureVerifier: messageSigner,
            messageFormatter: messageFormatter,
            pairingStorage: pairingStorage)
    }

    func testMessageCompromisedFailure() {
        let messageExpectation = expectation(description: "receives response")

        // set history record for a request
        let topic = "topic"
        let requestId: RPCID = RPCID(1234)
        let request = RPCRequest(method: "wc_authRequest", params: AuthRequestParams.stub(), id: requestId.right!)
        try! rpcHistory.set(request, forTopic: topic, emmitedBy: .local)

        var messageId: RPCID!
        var result: Result<Cacao, AuthError>!
        sut.onResponse = { id, r in
            messageId = id
            result = r
            messageExpectation.fulfill()
        }

        // subscribe on compromised cacao
        let header = CacaoHeader(t: "eip4361")
        let payload = CacaoPayload(params: AuthPayload.stub(nonce: "compromised nonce"), didpkh: DIDPKH(account: walletAccount))

        let message = try! messageFormatter.formatMessage(from: payload)
        let cacaoSignature = try! messageSigner.sign(message: message, privateKey: prvKey)

        let cacao = Cacao(h: header, p: payload, s: cacaoSignature)

        let response = RPCResponse(id: requestId, result: cacao)
        networkingInteractor.responsePublisherSubject.send((topic, request, response))

        wait(for: [messageExpectation], timeout: defaultTimeout)
        XCTAssertEqual(result, .failure(AuthError.messageCompromised))
        XCTAssertEqual(messageId, requestId)
    }
}
