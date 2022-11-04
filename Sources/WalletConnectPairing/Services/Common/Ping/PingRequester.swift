import Foundation

public class PingRequester {
    private let method: ProtocolMethod
    private let networkingInteractor: NetworkInteracting

    public init(networkingInteractor: NetworkInteracting, method: ProtocolMethod) {
        self.method = method
        self.networkingInteractor = networkingInteractor
    }

    public func ping(topic: String) async throws {
        let request = RPCRequest(method: method.method, params: PairingPingParams())
        try await networkingInteractor.request(request, topic: topic, protocolMethod: method)
    }
}
