import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

protocol PairingRequestSubscriber {
    func subscribeForRequest()
}

class PushRequestSubscriber: PairingRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    var onRequest: ((AuthRequest) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        subscribeForRequest()
    }

    func subscribeForRequest() {

        networkingInteractor.requestSubscription(on: AuthProtocolMethod.authRequest)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AuthRequestParams>) in

            }.store(in: &publishers)
    }
}

enum PushProtocolMethod: String, ProtocolMethod {
case authRequest = "wc_pushRequest"

var method: String {
    return self.rawValue
}

var requestTag: Int {
    switch self {
    case .authRequest:
        return 3000
    }
}

var responseTag: Int {
    switch self {
    case .authRequest:
        return 3001
    }
}
}
