import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking


public class PushRequester {
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

    func request(topic: String, params: AnyCodable) async throws {
        let request = RPCRequest(method: protocolMethod.method, params: params)

        try await networkingInteractor.requestNetworkAck(request, topic: topic, tag: PushProtocolMethod.propose.requestTag)
    }
}
