import Foundation
import WalletConnectPairing
import JSONRPC

class PingService {
    private let pairingStorage: WCPairingStorage
    private let networkingInteractor: NetworkInteracting

    func ping(topic: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard pairingStorage.hasSession(forTopic: topic) else { return }
        let request = RPCRequest(
    }
}
