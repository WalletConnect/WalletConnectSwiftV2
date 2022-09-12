import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

public protocol Paringable {
    var protocolMethod: ProtocolMethod { get set }
    var pairingRequestSubscriber: PairingRequestSubscriber! {get set}
    var pairingRequester: PairingRequester! {get set}
}

public class PairingRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    var onRequest: ((RequestSubscriptionPayload<AnyCodable>) -> Void)?
    let protocolMethod: ProtocolMethod

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         protocolMethod: ProtocolMethod) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.protocolMethod = protocolMethod
        subscribeForRequest()
    }

    func subscribeForRequest() {

        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AnyCodable>) in
                onRequest?(payload)
            }.store(in: &publishers)
    }
}

public class PairingRequester {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    let protocolMethod: ProtocolMethod

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         protocolMethod: ProtocolMethod) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.protocolMethod = protocolMethod
    }

    func request(topic: String) async throws {
        let request = RPCRequest(method: protocolMethod.method, params: AnyCodable(""))

        try await networkingInteractor.requestNetworkAck(request, topic: topic, tag: PushProtocolMethod.propose.requestTag)
    }
}
