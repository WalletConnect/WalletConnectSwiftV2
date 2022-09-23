import Foundation
import WalletConnectNetworking
import JSONRPC

class PingRequester {
    private let pairingStorage: WCPairingStorage
    private let networkingInteractor: NetworkInteracting

    init(pairingStorage: WCPairingStorage, networkingInteractor: NetworkInteracting) {
        self.pairingStorage = pairingStorage
        self.networkingInteractor = networkingInteractor
    }

    func ping(topic: String) async throws {
        guard pairingStorage.hasPairing(forTopic: topic) else { return }
        let request = RPCRequest(method: PairingProtocolMethod.ping.rawValue, params: PairingPingParams())
        try await networkingInteractor.request(request, topic: topic, tag: PairingProtocolMethod.ping.requestTag)
    }
}
