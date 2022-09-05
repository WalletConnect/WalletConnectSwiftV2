import Foundation
import WalletConnectPairing
import JSONRPC
import WalletConnectNetworking

class PingService {
    private let pairingStorage: WCPairingStorage
    private let networkingInteractor: NetworkInteracting

    init(pairingStorage: WCPairingStorage, networkingInteractor: NetworkInteracting) {
        self.pairingStorage = pairingStorage
        self.networkingInteractor = networkingInteractor
    }

    func ping(topic: String) async throws {
        guard pairingStorage.hasPairing(forTopic: topic) else { return }
        let request = RPCRequest(method: AuthProtocolMethods.pairingPing.rawValue, params: PairingPingParams())
        try await networkingInteractor.request(request, topic: topic, tag: AuthProtocolMethods.pairingDelete.requestTag)
        //todo return a publisher?
    }
}
