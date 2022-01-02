import XCTest
import WalletConnectUtils
@testable import WalletConnect

// TODO: Move common helper methods to a shared folder
fileprivate extension Pairing {
    
    static func stub() -> Pairing {
        Pairing(topic: String.generateTopic()!, peer: nil)
    }
}

fileprivate extension SessionType.Permissions {
    
    static func stub() -> SessionType.Permissions {
        SessionType.Permissions(
            blockchain: SessionType.Blockchain(chains: []),
            jsonrpc: SessionType.JSONRPC(methods: []),
            notifications: SessionType.Notifications(types: [])
        )
    }
}

fileprivate extension WCRequest {
    
    var sessionProposal: SessionProposal? {
        guard case .pairingPayload(let payload) = self.params else { return nil }
        return payload.request.params
    }
    
    var approveParams: SessionType.ApproveParams? {
        guard case .sessionApprove(let approveParams) = self.params else { return nil }
        return approveParams
    }
}

extension AgreementKeys {
    
    static func stub() -> AgreementKeys {
        AgreementKeys(sharedSecret: Data(), publicKey: Curve25519.KeyAgreement.PrivateKey().publicKey)
    }
}

//fileprivate func deriveTopic(publicKey: String, privateKey: Crypto.X25519.PrivateKey) -> String {
//    try! Crypto.X25519.generateAgreementKeys(peerPublicKey: Data(hex: publicKey), privateKey: privateKey).derivedTopic()
//}

import CryptoKit

final class SessionEngineTests: XCTestCase {
    
    var engine: SessionEngine!

    var relayMock: MockedWCRelay!
    var subscriberMock: MockedSubscriber!
    var storageMock: SessionSequenceStorageMock!
    var cryptoMock: CryptoStorageProtocolMock!
    
    var topicGenerator: TopicGenerator!
    
    var isController: Bool!
    var metadata: AppMetadata!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = SessionSequenceStorageMock()
        cryptoMock = CryptoStorageProtocolMock()
        topicGenerator = TopicGenerator()
        
        metadata = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        isController = false
        let logger = ConsoleLoggerMock()
        engine = SessionEngine(
            relay: relayMock,
            crypto: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            isController: isController,
            metadata: metadata,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }

    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func testPropose() {
        let pairing = Pairing.stub()
        
        let topicB = pairing.topic
        let topicC = topicGenerator.topic
        
        let agreementKeys = AgreementKeys.stub()
        cryptoMock.set(agreementKeys: agreementKeys, topic: topicB)
        let permissions = SessionType.Permissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        
        guard let publishTopic = relayMock.requests.first?.topic, let proposal = relayMock.requests.first?.request.sessionProposal else {
            XCTFail("Proposer must publish a proposal request."); return
        }
        
        XCTAssert(subscriberMock.didSubscribe(to: topicC), "Proposer must subscribe to topic C to listen for approval message.")
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must store the private key matching the public key sent through the proposal.")
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicB))
        XCTAssert(storageMock.hasPendingProposedPairing(on: topicC), "The engine must store a pending session on proposed state.")
        
        XCTAssertEqual(publishTopic, topicB)
        XCTAssertEqual(proposal.topic, topicC)
    }
    
    func testProposeResponseFailure() {
        let pairing = Pairing.stub()
        
        let topicB = pairing.topic
        let topicC = topicGenerator.topic
        
        let agreementKeys = AgreementKeys.stub()
        cryptoMock.set(agreementKeys: agreementKeys, topic: topicB)
        let permissions = SessionType.Permissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        
        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
            XCTFail("Proposer must publish a proposal request."); return
        }
        let error = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        let response = WCResponse(
            topic: publishTopic,
            requestMethod: request.method,
            requestParams: request.params,
            result: .failure(error))
        relayMock.onResponse?(response)
        
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: request.sessionProposal?.proposer.publicKey ?? ""))
        XCTAssertFalse(cryptoMock.hasAgreementKeys(for: topicB))
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC))
    }
    
    func testApprove() {
        let proposerPubKey = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.toHexString()
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionProposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionType.Permissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: [])
        
        guard let publishTopic = relayMock.requests.first?.topic, let approval = relayMock.requests.first?.request.approveParams else {
            XCTFail("Responder must publish an approval request."); return
        }
        
        XCTAssert(subscriberMock.didSubscribe(to: topicC))
        XCTAssert(subscriberMock.didSubscribe(to: topicD))
        XCTAssert(cryptoMock.hasPrivateKey(for: approval.responder.publicKey))
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicD))
        XCTAssert(storageMock.hasSequence(forTopic: topicC)) // TODO: check state
        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check state
        XCTAssertEqual(publishTopic, topicC)
    }
    
    func testApprovalAcknowledgementSuccess() {
        let proposerPubKey = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.toHexString()
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let agreementKeys = AgreementKeys.stub()
        cryptoMock.set(agreementKeys: agreementKeys, topic: topicC)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionProposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionType.Permissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: [])
        
        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
            XCTFail("Responder must publish an approval request."); return
        }
        let success = JSONRPCResponse<AnyCodable>(id: request.id, result: AnyCodable(true))
        let response = WCResponse(
            topic: publishTopic,
            requestMethod: request.method,
            requestParams: request.params,
            result: .success(success))
        relayMock.onResponse?(response)
    
        XCTAssertFalse(cryptoMock.hasAgreementKeys(for: topicC))
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC)) // TODO: Check state
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
    }
    
    func testApprovalAcknowledgementFailure() {
        let proposerPubKey = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.toHexString()
        let selfPubKey = cryptoMock.privateKeyStub.publicKey.rawRepresentation.toHexString()
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let agreementKeys = AgreementKeys.stub()
        cryptoMock.set(agreementKeys: agreementKeys, topic: topicC)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionProposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionType.Permissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: [])
        
        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
            XCTFail("Responder must publish an approval request."); return
        }
        let error = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        let response = WCResponse(
            topic: publishTopic,
            requestMethod: request.method,
            requestParams: request.params,
            result: .failure(error))
        relayMock.onResponse?(response)
        
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: selfPubKey))
        XCTAssertFalse(cryptoMock.hasAgreementKeys(for: topicC))
        XCTAssertFalse(cryptoMock.hasAgreementKeys(for: topicD))
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC)) // TODO: Check state
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicD))
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
        XCTAssert(subscriberMock.didUnsubscribe(to: topicD))
        // TODO: assert session settlement callback
    }
    
    func testReceiveApprovalResponse() {

        var approvedSession: Session?

        let privateKeyStub = cryptoMock.privateKeyStub
        let proposerPubKey = privateKeyStub.publicKey.rawRepresentation.toHexString()
        let responderPubKey = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.toHexString()
        let topicC = topicGenerator.topic
        let topicD = deriveTopic(publicKey: responderPubKey, privateKey: privateKeyStub)

        let permissions = SessionType.Permissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        let approveParams = SessionType.ApproveParams(
            relay: relayOptions,
            responder: Participant(publicKey: responderPubKey, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)),
            expiry: Time.day,
            state: SessionState(accounts: []))
        let request = WCRequest(method: .sessionApprove, params: .sessionApprove(approveParams))
        let payload = WCRequestSubscriptionPayload(topic: topicC, wcRequest: request)
        let pairing = Pairing.stub()

        let agreementKeys = AgreementKeys.stub()
        cryptoMock.set(agreementKeys: agreementKeys, topic: pairing.topic)

        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        engine.onSessionApproved = { session in
            approvedSession = session
        }
        subscriberMock.onReceivePayload?(payload)

        XCTAssert(subscriberMock.didUnsubscribe(to: topicC)) // FIXME: Actually, only on acknowledgement
        XCTAssert(subscriberMock.didSubscribe(to: topicD))
        XCTAssert(cryptoMock.hasPrivateKey(for: proposerPubKey))
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicD))
        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check for state
        XCTAssertNotNil(approvedSession)
        XCTAssertEqual(approvedSession?.topic, topicD)
    }
}
