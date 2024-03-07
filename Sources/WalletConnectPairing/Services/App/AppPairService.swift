import Foundation

actor AppPairService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStorage: WCPairingStorage

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, pairingStorage: WCPairingStorage) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
    }

    func create(supportedMethods: [String]?) async throws -> WalletConnectURI {
        let topic = String.generateTopic()
        try await networkingInteractor.subscribe(topic: topic)
        let symKey = try! kms.createSymmetricKey(topic)

        let relay = RelayProtocolOptions(protocol: "irn", data: nil)
        let uri = WalletConnectURI(topic: topic, symKey: symKey.hexRepresentation, relay: relay, methods: supportedMethods)
        let pairing = WCPairing(uri: uri)
        pairingStorage.setPairing(pairing)
        return uri
    }
}
