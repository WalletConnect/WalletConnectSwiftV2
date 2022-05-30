
import Foundation
import WalletConnectKMS
import WalletConnectUtils
import Relayer
import Combine

class Engine {
    var onInvite: ((Invite)->())?
    var onNewThread: ((Thread)->())?
    let networkingInteractor: NetworkingInteractor
    let registry: Registry
    let kms: KeyManagementService
    let threadsStore = KeyValueStore<Thread>(defaults: RuntimeKeyValueStorage(), identifier: "threads")
    private var publishers = [AnyCancellable]()

    
    init(registry: Registry,
         networkingInteractor: NetworkingInteractor,
         kms: KeyManagementService) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        
        networkingInteractor.responsePublisher.sink { [unowned self] response in
            handleResponse(response)
        }.store(in: &publishers)
        
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.request.params {
            case .invite(let invite):
                handleInvite(invite)
            case .message(let message):
                print("received message: \(message)")
            }
        }.store(in: &publishers)
    }
    
    func invite(account: Account) {
        let peerPubKeyHex = registry.resolve(account: account)!
        print("resolved pub key: \(peerPubKeyHex)")
        let pubKey = try! kms.createX25519KeyPair()
        let invite = Invite(pubKey: pubKey.hexRepresentation, message: "hello")
        let topic = try! AgreementPublicKey(hex: peerPubKeyHex).rawRepresentation.sha256().toHexString()
        let request = MessagingRequest(method: .invite, params: .invite(invite))
        networkingInteractor.request(request, topic: topic)
        let agreementKeys = try! kms.performKeyAgreement(selfPublicKey: pubKey, peerPublicKey: peerPubKeyHex)
        let threadTopic = agreementKeys.derivedTopic()
        networkingInteractor.subscribe(topic: threadTopic)
        print("invite sent on topic: \(topic)")
    }
    
    var pubKey: AgreementPublicKey!
    
    func accept(invite: Invite) {
        let agreementKeys = try! kms.performKeyAgreement(selfPublicKey: pubKey, peerPublicKey: invite.pubKey)
        let topic = agreementKeys.derivedTopic()
        networkingInteractor.subscribe(topic: topic)
    }
    
    func register(account: Account) {
        pubKey = try! kms.createX25519KeyPair()
        print("registered pubKey: \(pubKey.hexRepresentation)")
        registry.register(account: account, pubKey: pubKey.hexRepresentation)
        let topic = pubKey.rawRepresentation.sha256().toHexString()
        networkingInteractor.subscribe(topic: topic)
        print("did register and is subscribing on topic: \(topic)")
    }
    
    private func handleResponse(_ response: MessagingResponse) {
        switch response.requestParams {
        case .invite(let invite):
            let thread = Thread(topic: <#T##String#>, pubKey: <#T##String#>)
            onNewThread?()
            print("invite response: \(invite)")
        case .message(let message):
            print("received message response: \(message)")
        }
    }
    
    func handleInvite(_ invite: Invite) {
        onInvite?(invite)
    }
    
}


struct RequestSubscriptionPayload: Codable {
    let topic: String
    let request: MessagingRequest
}

struct MessagingResponse: Codable {
    let topic: String
    let requestMethod: MessagingRequest.Method
    let requestParams: MessagingRequest.Params
    let result: JsonRpcResult
}


struct Invite: Codable {
    let pubKey: String
    let message: String
}


struct Thread: Codable {
    let topic: String
    let pubKey: String
    //let peerName: String
}
public protocol Serializing {
    func serialize(topic: String, encodable: Encodable) throws -> String
    func tryDeserialize<T: Codable>(topic: String, message: String) -> T?
}

extension Serializer: Serializing {}
