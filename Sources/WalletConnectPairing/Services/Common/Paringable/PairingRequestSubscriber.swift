import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking


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
